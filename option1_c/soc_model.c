/**
 * soc_model.c
 *
 * LSTM-based SOC inference engine — pure C, optimized for Cortex-M7.
 *
 * Architecture
 * ------------
 *   Layer 0: LSTM  input_size=5,  hidden_size=64
 *   Layer 1: LSTM  input_size=64, hidden_size=64
 *   Head:    Linear(64,64) -> ReLU -> Linear(64,1)
 *
 * PyTorch LSTM gate order: [input, forget, cell_gate, output]
 * Each gate has HIDDEN_SIZE (64) units within the 4*HIDDEN_SIZE (256) vectors.
 *
 * Weight layout (row-major, from PyTorch export):
 *   W_ih[layer]: shape [4*H, input_size_l]   (input_size_l = 5 for layer 0, 64 for layer 1)
 *   W_hh[layer]: shape [4*H, H]
 *   bias[layer]: shape [4*H]                  (bias_ih + bias_hh, pre-combined)
 */

#include "soc_model.h"
#include "soc_model_weights.h"

#include <math.h>
#include <string.h>

/* ------------------------------------------------------------------ */
/*  Optional CMSIS-DSP acceleration                                    */
/* ------------------------------------------------------------------ */
#if defined(USE_CMSIS_DSP) && USE_CMSIS_DSP
#include "arm_math.h"
#define HAS_CMSIS_DSP 1
#else
#define HAS_CMSIS_DSP 0
#endif

/* ------------------------------------------------------------------ */
/*  Fast math approximations                                           */
/* ------------------------------------------------------------------ */

static inline float fast_sigmoid(float x)
{
    /* Clamp to avoid overflow in expf */
    if (x < -8.0f) return 0.0f;
    if (x >  8.0f) return 1.0f;
    return 1.0f / (1.0f + expf(-x));
}

static inline float fast_tanh(float x)
{
    /* tanh(x) = 2*sigmoid(2x) - 1 */
    if (x < -4.0f) return -1.0f;
    if (x >  4.0f) return  1.0f;
    float e2x = expf(2.0f * x);
    return (e2x - 1.0f) / (e2x + 1.0f);
}

static inline float relu(float x)
{
    return x > 0.0f ? x : 0.0f;
}

/* ------------------------------------------------------------------ */
/*  Matrix-vector multiply:  y[M] += A[M][N] * x[N]                   */
/*  (accumulates into y; caller must initialize y beforehand)          */
/* ------------------------------------------------------------------ */

static void matvec_add(
    float * restrict       y,
    const float * restrict A,
    const float * restrict x,
    int M,
    int N)
{
#if HAS_CMSIS_DSP
    /* Use CMSIS-DSP: treat as matrix(M,N) * matrix(N,1) -> matrix(M,1).
       arm_mat_mult_f32 writes the result, so we need a temp buffer and add. */
    float tmp[256];  /* max M = GATE_SIZE = 256 */
    arm_matrix_instance_f32 matA, matX, matY;
    arm_mat_init_f32(&matA, (uint16_t)M, (uint16_t)N, (float *)A);
    arm_mat_init_f32(&matX, (uint16_t)N, 1, (float *)x);
    arm_mat_init_f32(&matY, (uint16_t)M, 1, tmp);
    arm_mat_mult_f32(&matA, &matX, &matY);
    for (int i = 0; i < M; i++)
        y[i] += tmp[i];
#else
    for (int i = 0; i < M; i++) {
        float sum = 0.0f;
        const float *row = A + (size_t)i * N;
        for (int j = 0; j < N; j++) {
            sum += row[j] * x[j];
        }
        y[i] += sum;
    }
#endif
}

/* ------------------------------------------------------------------ */
/*  Static buffers — no heap allocation                                */
/* ------------------------------------------------------------------ */

/* Hidden and cell states for both LSTM layers */
static float h_state[NUM_LAYERS][HIDDEN_SIZE];
static float c_state[NUM_LAYERS][HIDDEN_SIZE];

/* ------------------------------------------------------------------ */
/*  Public API                                                         */
/* ------------------------------------------------------------------ */

void soc_model_init(void)
{
    memset(h_state, 0, sizeof(h_state));
    memset(c_state, 0, sizeof(c_state));
}

/**
 * Run a single LSTM cell step for one layer.
 *
 * @param x_t       Input vector (length = in_size)
 * @param h         Hidden state (length = HIDDEN_SIZE), updated in-place
 * @param c         Cell   state (length = HIDDEN_SIZE), updated in-place
 * @param W_ih      Input-hidden weights  [GATE_SIZE x in_size]
 * @param W_hh      Hidden-hidden weights [GATE_SIZE x HIDDEN_SIZE]
 * @param bias      Combined bias         [GATE_SIZE]
 * @param in_size   Dimension of x_t
 */
static void lstm_cell(
    const float * restrict x_t,
    float * restrict       h,
    float * restrict       c,
    const float * restrict W_ih,
    const float * restrict W_hh,
    const float * restrict bias,
    int                    in_size)
{
    float gates[GATE_SIZE];

    /* Start with bias */
    memcpy(gates, bias, sizeof(float) * GATE_SIZE);

    /* gates += W_ih @ x_t */
    matvec_add(gates, W_ih, x_t, GATE_SIZE, in_size);

    /* gates += W_hh @ h_{t-1} */
    matvec_add(gates, W_hh, h, GATE_SIZE, HIDDEN_SIZE);

    /* Split gates: i | f | g | o   (each HIDDEN_SIZE = 64) */
    const float *gi = gates;                        /* input  gate */
    const float *gf = gates + HIDDEN_SIZE;          /* forget gate */
    const float *gg = gates + 2 * HIDDEN_SIZE;      /* cell   gate */
    const float *go = gates + 3 * HIDDEN_SIZE;      /* output gate */

    for (int k = 0; k < HIDDEN_SIZE; k++) {
        float i_gate = fast_sigmoid(gi[k]);
        float f_gate = fast_sigmoid(gf[k]);
        float g_gate = fast_tanh(gg[k]);
        float o_gate = fast_sigmoid(go[k]);

        float c_new  = f_gate * c[k] + i_gate * g_gate;
        c[k] = c_new;
        h[k] = o_gate * fast_tanh(c_new);
    }
}

float soc_model_predict(const float input[10][5])
{
    /* Reset hidden / cell states for a fresh sequence */
    soc_model_init();

    /*
     * Intermediate buffer: after layer 0 processes all timesteps,
     * we store the hidden-state outputs so layer 1 can consume them.
     */
    float layer0_out[SEQ_LEN][HIDDEN_SIZE];

    /* --- Layer 0 --- */
    for (int t = 0; t < SEQ_LEN; t++) {
        lstm_cell(
            input[t],
            h_state[0],
            c_state[0],
            lstm_weight_ih_l0,   /* [256 x 5]  */
            lstm_weight_hh_l0,   /* [256 x 64] */
            lstm_bias_l0,        /* [256]       */
            INPUT_SIZE);

        memcpy(layer0_out[t], h_state[0], sizeof(float) * HIDDEN_SIZE);
    }

    /* --- Layer 1 --- */
    for (int t = 0; t < SEQ_LEN; t++) {
        lstm_cell(
            layer0_out[t],
            h_state[1],
            c_state[1],
            lstm_weight_ih_l1,   /* [256 x 64] */
            lstm_weight_hh_l1,   /* [256 x 64] */
            lstm_bias_l1,        /* [256]       */
            HIDDEN_SIZE);
    }

    /* Final hidden state from layer 1 (last timestep) */
    const float *h_final = h_state[1];

    /* --- Head: Linear(64 -> 64) --- */
    float fc0_out[HIDDEN_SIZE];
    memcpy(fc0_out, head_bias_0, sizeof(float) * HIDDEN_SIZE);
    matvec_add(fc0_out, head_weight_0, h_final, HIDDEN_SIZE, HIDDEN_SIZE);

    /* ReLU */
    for (int i = 0; i < HIDDEN_SIZE; i++) {
        fc0_out[i] = relu(fc0_out[i]);
    }

    /* --- Head: Linear(64 -> 1) --- */
    float result = head_bias_2[0];
    for (int i = 0; i < HIDDEN_SIZE; i++) {
        result += head_weight_2[i] * fc0_out[i];
    }

    return result;
}

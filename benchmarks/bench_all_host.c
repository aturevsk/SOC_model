/**
 * bench_all_host.c
 *
 * Comprehensive host benchmark for all C code generation options.
 * Measures inference time, throughput, and memory footprint.
 *
 * Compile:
 *   Option 1: gcc -O2 -o bench_opt1 bench_all_host.c ../option1_c/soc_model.c -lm -DOPTION=1
 *   Option 2: gcc -O2 -o bench_opt2 bench_all_host.c \
 *             ../option2_matlab_pytorch_coder/outputDir/predict_soc.c \
 *             ../option2_matlab_pytorch_coder/outputDir/predict_soc_data.c \
 *             ../option2_matlab_pytorch_coder/outputDir/predict_soc_initialize.c \
 *             ../option2_matlab_pytorch_coder/outputDir/predict_soc_terminate.c \
 *             -I../option2_matlab_pytorch_coder/outputDir -lm -DOPTION=2
 *   Option 4: gcc -O2 -o bench_opt4 bench_all_host.c \
 *             ../option4_matlab_onnx/codegen_output/predict_soc_onnx.c \
 *             ../option4_matlab_onnx/codegen_output/predict_soc_onnx_data.c \
 *             ../option4_matlab_onnx/codegen_output/predict_soc_onnx_initialize.c \
 *             ../option4_matlab_onnx/codegen_output/predict_soc_onnx_terminate.c \
 *             ../option4_matlab_onnx/codegen_output/predict.c \
 *             ../option4_matlab_onnx/codegen_output/callPredict.c \
 *             ../option4_matlab_onnx/codegen_output/cat.c \
 *             ../option4_matlab_onnx/codegen_output/elementwiseOperationInPlace.c \
 *             -I../option4_matlab_onnx/codegen_output -lm -DOPTION=4
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <string.h>

#if OPTION == 1
#include "../option1_c/soc_model.h"
#elif OPTION == 2
#include "predict_soc.h"
#include "predict_soc_initialize.h"
#include "predict_soc_terminate.h"
#elif OPTION == 4
#include "predict_soc_onnx.h"
#include "predict_soc_onnx_initialize.h"
#include "predict_soc_onnx_terminate.h"
#elif OPTION == 5
#include "predict_soc_native.h"
#include "predict_soc_native_initialize.h"
#include "predict_soc_native_terminate.h"
#endif

/* Benchmark parameters */
#define WARMUP_ITERS  1000
#define BENCH_ITERS   100000

/* Test input: 10 timesteps x 5 features */
static float test_input[10][5];

static void fill_random_input(void) {
    srand(42);
    for (int i = 0; i < 10; i++)
        for (int j = 0; j < 5; j++)
            test_input[i][j] = ((float)rand() / RAND_MAX) * 2.0f - 1.0f;
}

static double get_time_sec(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec * 1e-9;
}

static float run_inference(void) {
#if OPTION == 1
    return soc_model_predict(test_input);
#elif OPTION == 2
    /* Option 2 takes flat float[50] in row-major */
    return predict_soc((const float *)test_input);
#elif OPTION == 4
    /* Option 4 takes float[10][5] reshaped to flat */
    float flat[50];
    memcpy(flat, test_input, sizeof(flat));
    return predict_soc_onnx(flat);
#elif OPTION == 5
    float flat[50];
    memcpy(flat, test_input, sizeof(flat));
    return predict_soc_native(flat);
#else
    return 0.0f;
#endif
}

int main(void)
{
    float result;
    double t0, t1, elapsed;
    double times[BENCH_ITERS];
    double min_t = 1e9, max_t = 0, sum_t = 0;

#if OPTION == 1
    printf("=== Benchmark: Option 1 (Manual C) ===\n");
    soc_model_init();
#elif OPTION == 2
    printf("=== Benchmark: Option 2 (MATLAB Coder PyTorch) ===\n");
    predict_soc_initialize();
#elif OPTION == 4
    printf("=== Benchmark: Option 4 (ONNX Import Codegen) ===\n");
    predict_soc_onnx_initialize();
#elif OPTION == 5
    printf("=== Benchmark: Option 5 (Manual dlnetwork + Embedded Coder) ===\n");
    predict_soc_native_initialize();
#endif

    fill_random_input();

    /* Warmup */
    for (int i = 0; i < WARMUP_ITERS; i++) {
        result = run_inference();
    }
    printf("Warmup done. Sample output: %.8f\n\n", result);

    /* Benchmark */
    for (int i = 0; i < BENCH_ITERS; i++) {
        t0 = get_time_sec();
        result = run_inference();
        t1 = get_time_sec();
        elapsed = (t1 - t0) * 1e6; /* microseconds */
        times[i] = elapsed;
        sum_t += elapsed;
        if (elapsed < min_t) min_t = elapsed;
        if (elapsed > max_t) max_t = elapsed;
    }

    /* Compute percentiles */
    /* Simple sort for percentiles */
    for (int i = 0; i < BENCH_ITERS - 1; i++) {
        for (int j = i + 1; j < BENCH_ITERS; j++) {
            if (times[j] < times[i]) {
                double tmp = times[i];
                times[i] = times[j];
                times[j] = tmp;
            }
        }
    }
    double p50 = times[BENCH_ITERS / 2];
    double p95 = times[(int)(BENCH_ITERS * 0.95)];
    double p99 = times[(int)(BENCH_ITERS * 0.99)];

    double avg = sum_t / BENCH_ITERS;

    printf("--- Timing Results (%d iterations) ---\n", BENCH_ITERS);
    printf("  Mean:       %8.2f us\n", avg);
    printf("  Median:     %8.2f us\n", p50);
    printf("  Min:        %8.2f us\n", min_t);
    printf("  Max:        %8.2f us\n", max_t);
    printf("  P95:        %8.2f us\n", p95);
    printf("  P99:        %8.2f us\n", p99);
    printf("  Throughput: %8.0f inferences/sec\n", 1e6 / avg);

#if OPTION == 2
    predict_soc_terminate();
#elif OPTION == 4
    predict_soc_onnx_terminate();
#elif OPTION == 5
    predict_soc_native_terminate();
#endif

    return 0;
}

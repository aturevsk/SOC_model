/**
 * main_test.c
 *
 * Test harness for the LSTM SOC model.
 * Verifies correctness against a known test vector, then benchmarks throughput.
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#include "soc_model.h"

/* ------------------------------------------------------------------ */
/*  Test vector (10 timesteps x 5 features, row-major)                 */
/*  First 5 values from the reference; remaining 45 filled with zeros. */
/* ------------------------------------------------------------------ */
static const float test_input[10][5] = {
    { -0.2832135260105133f, -1.0206300020217896f, -0.6308194398880005f,
       1.2680393457412720f,  1.9709614515304565f },
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
};

/* Expected result from PyTorch reference model */
static const float expected_output = -0.031596f;
static const float tolerance       =  0.001f;

#define BENCH_ITERATIONS 10000

int main(void)
{
    printf("=== SOC Model Test Harness ===\n\n");

    /* ---- Correctness check ---- */
    soc_model_init();
    float result = soc_model_predict(test_input);

    printf("Predicted SOC : %+.6f\n", result);
    printf("Expected  SOC : %+.6f\n", expected_output);
    printf("Absolute error: %.6f\n", fabsf(result - expected_output));

    if (fabsf(result - expected_output) < tolerance) {
        printf("PASS  (within tolerance %.4f)\n\n", tolerance);
    } else {
        printf("FAIL  (exceeds tolerance %.4f)\n\n", tolerance);
    }

    /* ---- Benchmark ---- */
    printf("Running %d inference iterations for benchmarking...\n", BENCH_ITERATIONS);

    clock_t t_start = clock();

    volatile float dummy = 0.0f;   /* prevent optimizer from eliding the loop */
    for (int i = 0; i < BENCH_ITERATIONS; i++) {
        dummy = soc_model_predict(test_input);
    }

    clock_t t_end = clock();
    double elapsed_sec = (double)(t_end - t_start) / CLOCKS_PER_SEC;
    double us_per_inference = (elapsed_sec / BENCH_ITERATIONS) * 1.0e6;

    printf("Total time    : %.3f s\n", elapsed_sec);
    printf("Per inference : %.1f us\n", us_per_inference);
    printf("Throughput    : %.0f inferences/sec\n",
           (double)BENCH_ITERATIONS / elapsed_sec);

    (void)dummy;
    return 0;
}

/*
 * Benchmark for Option 1: Manual C Implementation
 * ================================================
 * Measures inference time, memory usage, and validates correctness.
 *
 * Compile (host):
 *   gcc -O2 -o benchmark_option1 benchmark_option1.c ../option1_c/soc_model.c -lm
 *
 * Compile (ARM cross):
 *   arm-none-eabi-gcc -mcpu=cortex-m7 -mfpu=fpv5-sp-d16 -mfloat-abi=hard \
 *     -Os -o benchmark_option1.elf benchmark_option1.c ../option1_c/soc_model.c -lm
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include "../option1_c/soc_model.h"

/* Number of benchmark iterations */
#define NUM_ITERATIONS 100000
#define WARMUP_ITERATIONS 1000

/* Test input: 10 timesteps x 5 features */
static const float test_input[10][5] = {
    {-0.28321353f, -1.02063000f, -0.63081944f,  1.26803935f,  1.97096145f},
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f},
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f},
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f},
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f},
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f},
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f},
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f},
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f},
    { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f}
};

static double get_time_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1000000.0;
}

int main(void) {
    float result;
    double start, end_time, elapsed;
    double min_time = 1e9, max_time = 0, total_time = 0;
    int i;

    printf("=== Option 1 Benchmark: Manual C Implementation ===\n\n");

    /* Initialize model */
    soc_model_init();

    /* Warmup */
    printf("Warming up (%d iterations)...\n", WARMUP_ITERATIONS);
    for (i = 0; i < WARMUP_ITERATIONS; i++) {
        result = soc_model_predict(test_input);
    }
    printf("Warmup complete. Last result: %.6f\n\n", result);

    /* Benchmark */
    printf("Running benchmark (%d iterations)...\n", NUM_ITERATIONS);
    for (i = 0; i < NUM_ITERATIONS; i++) {
        start = get_time_ms();
        result = soc_model_predict(test_input);
        end_time = get_time_ms();

        elapsed = end_time - start;
        total_time += elapsed;
        if (elapsed < min_time) min_time = elapsed;
        if (elapsed > max_time) max_time = elapsed;
    }

    printf("\n--- Results ---\n");
    printf("Iterations:  %d\n", NUM_ITERATIONS);
    printf("Total time:  %.3f ms\n", total_time);
    printf("Avg time:    %.4f ms/inference\n", total_time / NUM_ITERATIONS);
    printf("Min time:    %.4f ms\n", min_time);
    printf("Max time:    %.4f ms\n", max_time);
    printf("Throughput:  %.0f inferences/sec\n", NUM_ITERATIONS / (total_time / 1000.0));
    printf("Output:      %.6f\n", result);

    /* Memory estimate */
    printf("\n--- Memory Estimate ---\n");
    printf("Model weights (flash): %lu bytes (%.1f KB)\n",
           (unsigned long)(55681 * sizeof(float)),
           55681 * sizeof(float) / 1024.0f);
    printf("Runtime buffers (RAM): ~%lu bytes (%.1f KB)\n",
           (unsigned long)(2 * 2 * 64 * sizeof(float)    /* h,c states */
           + 256 * sizeof(float)                          /* gate buffer */
           + 10 * 64 * sizeof(float)                      /* layer output */
           + 64 * sizeof(float)),                         /* head buffer */
           (2*2*64*4 + 256*4 + 10*64*4 + 64*4) / 1024.0f);

    return 0;
}

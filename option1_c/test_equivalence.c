/**
 * test_equivalence.c
 *
 * 100-sample numerical equivalence test between C implementation and PyTorch.
 * Validates that the manual C code matches PyTorch output for all test vectors.
 */

#include <stdio.h>
#include <math.h>
#include "soc_model.h"
#include "test_vectors_100.h"

#define ABS_TOL 1e-5f
#define REL_TOL 1e-4f

int main(void)
{
    int pass = 0, fail = 0;
    float max_abs_err = 0.0f;
    float max_rel_err = 0.0f;
    float sum_abs_err = 0.0f;
    int worst_idx = -1;

    printf("=== Numerical Equivalence Test: 100 Vectors ===\n\n");

    for (int i = 0; i < N_TEST_VECTORS; i++) {
        soc_model_init();
        float predicted = soc_model_predict(test_inputs[i]);
        float expected = test_expected[i];

        float abs_err = fabsf(predicted - expected);
        float rel_err = (fabsf(expected) > 1e-8f) ?
                        abs_err / fabsf(expected) : abs_err;

        sum_abs_err += abs_err;

        if (abs_err > max_abs_err) {
            max_abs_err = abs_err;
            worst_idx = i;
        }
        if (rel_err > max_rel_err)
            max_rel_err = rel_err;

        if (abs_err < ABS_TOL || rel_err < REL_TOL) {
            pass++;
        } else {
            fail++;
            printf("  FAIL [%3d]: C=%.8f  PyTorch=%.8f  err=%.2e  rel=%.2e\n",
                   i, predicted, expected, abs_err, rel_err);
        }
    }

    printf("\n--- Results ---\n");
    printf("Total tests:     %d\n", N_TEST_VECTORS);
    printf("Passed:          %d\n", pass);
    printf("Failed:          %d\n", fail);
    printf("Max abs error:   %.2e (vector %d)\n", max_abs_err, worst_idx);
    printf("Max rel error:   %.2e\n", max_rel_err);
    printf("Mean abs error:  %.2e\n", sum_abs_err / N_TEST_VECTORS);

    if (fail == 0) {
        printf("\nALL 100 TESTS PASSED\n");
    } else {
        printf("\n%d TESTS FAILED\n", fail);
    }

    return fail > 0 ? 1 : 0;
}

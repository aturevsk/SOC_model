/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_native_terminate.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 17:49:13
 */

/* Include Files */
#include "predict_soc_native_terminate.h"
#include "predict_soc_native_data.h"
#include "omp.h"

/* Function Definitions */
/*
 * Arguments    : void
 * Return Type  : void
 */
void predict_soc_native_terminate(void)
{
  omp_destroy_nest_lock(&predict_soc_native_nestLockGlobal);
  isInitialized_predict_soc_native = false;
}

/*
 * File trailer for predict_soc_native_terminate.c
 *
 * [EOF]
 */

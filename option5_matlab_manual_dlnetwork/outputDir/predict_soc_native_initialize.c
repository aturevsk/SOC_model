/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_native_initialize.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 17:49:13
 */

/* Include Files */
#include "predict_soc_native_initialize.h"
#include "predict_soc_native.h"
#include "predict_soc_native_data.h"
#include "omp.h"

/* Function Definitions */
/*
 * Arguments    : void
 * Return Type  : void
 */
void predict_soc_native_initialize(void)
{
  omp_init_nest_lock(&predict_soc_native_nestLockGlobal);
  predict_soc_native_emx_init();
  predict_soc_native_init();
  isInitialized_predict_soc_native = true;
}

/*
 * File trailer for predict_soc_native_initialize.c
 *
 * [EOF]
 */

/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_opt5_direct_terminate.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 22:43:19
 */

/* Include Files */
#include "predict_soc_opt5_direct_terminate.h"
#include "predict_soc_opt5_direct_data.h"
#include "omp.h"

/* Function Definitions */
/*
 * Arguments    : void
 * Return Type  : void
 */
void predict_soc_opt5_direct_terminate(void)
{
  omp_destroy_nest_lock(&predict_soc_opt5_direct_nestLockGlobal);
  isInitialized_predict_soc_opt5_direct = false;
}

/*
 * File trailer for predict_soc_opt5_direct_terminate.c
 *
 * [EOF]
 */

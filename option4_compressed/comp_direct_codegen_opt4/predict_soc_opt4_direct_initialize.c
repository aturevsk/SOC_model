/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_opt4_direct_initialize.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 20:19:45
 */

/* Include Files */
#include "predict_soc_opt4_direct_initialize.h"
#include "predict_soc_opt4_direct_data.h"
#include "omp.h"

/* Function Definitions */
/*
 * Arguments    : void
 * Return Type  : void
 */
void predict_soc_opt4_direct_initialize(void)
{
  omp_init_nest_lock(&predict_soc_opt4_direct_nestLockGlobal);
  isInitialized_predict_soc_opt4_direct = true;
}

/*
 * File trailer for predict_soc_opt4_direct_initialize.c
 *
 * [EOF]
 */

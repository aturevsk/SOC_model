/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_initialize.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 17:29:35
 */

/* Include Files */
#include "predict_soc_initialize.h"
#include "predict_soc_data.h"
#include "omp.h"

/* Function Definitions */
/*
 * Arguments    : void
 * Return Type  : void
 */
void predict_soc_initialize(void)
{
  omp_init_nest_lock(&predict_soc_nestLockGlobal);
  isInitialized_predict_soc = true;
}

/*
 * File trailer for predict_soc_initialize.c
 *
 * [EOF]
 */

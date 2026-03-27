/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_onnx_initialize.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 17:53:24
 */

/* Include Files */
#include "predict_soc_onnx_initialize.h"
#include "predict_soc_onnx_data.h"
#include "omp.h"

/* Function Definitions */
/*
 * Arguments    : void
 * Return Type  : void
 */
void predict_soc_onnx_initialize(void)
{
  omp_init_nest_lock(&predict_soc_onnx_nestLockGlobal);
  isInitialized_predict_soc_onnx = true;
}

/*
 * File trailer for predict_soc_onnx_initialize.c
 *
 * [EOF]
 */

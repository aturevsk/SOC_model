/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_onnx.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 17:53:24
 */

/* Include Files */
#include "predict_soc_onnx.h"
#include "predict.h"
#include "predict_soc_onnx_data.h"
#include "predict_soc_onnx_initialize.h"

/* Function Definitions */
/*
 * predict_soc_onnx - SOC prediction from ONNX-imported network
 *    soc = predict_soc_onnx(in)
 *    in:  single(10x5) - 10 timesteps, 5 features
 *    soc: single(1x1) - predicted state of charge
 *
 *  R2026a: Auto-generated custom layers from ONNX support codegen.
 *
 * Arguments    : const float in[50]
 * Return Type  : float
 */
float predict_soc_onnx(const float in[50])
{
  if (!isInitialized_predict_soc_onnx) {
    predict_soc_onnx_initialize();
  }
  return dlnetwork_predict(in);
}

/*
 * File trailer for predict_soc_onnx.c
 *
 * [EOF]
 */

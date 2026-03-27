/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_native.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 17:49:13
 */

/* Include Files */
#include "predict_soc_native.h"
#include "loadDeepLearningNetwork.h"
#include "predict.h"
#include "predict_soc_native_data.h"
#include "predict_soc_native_emxutil.h"
#include "predict_soc_native_initialize.h"
#include "predict_soc_native_types.h"

/* Variable Definitions */
static c_coder_internal_ctarget_dlnetw net;

/* Function Definitions */
/*
 * predict_soc_native - SOC prediction using native codegen-compatible dlnetwork
 *    soc = predict_soc_native(in)
 *    in:  single(10x5) - 10 timesteps, 5 features (no batch dim)
 *    soc: single scalar - predicted state of charge
 *
 *  Uses only native MATLAB layers (no custom layers) for full codegen support.
 *
 * Arguments    : const float in[50]
 * Return Type  : float
 */
float predict_soc_native(const float in[50])
{
  if (!isInitialized_predict_soc_native) {
    predict_soc_native_initialize();
  }
  /*  Reshape input: add batch dimension */
  /*  Create dlarray with appropriate format */
  /*  Run prediction — LSTM2 has OutputMode='last', so output is already scalar
   */
  return dlnetwork_predict(net.InternalState.InternalValue, in);
  /*  Extract output */
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void predict_soc_native_emx_init(void)
{
  c_emxInitStruct_coder_internal_(&net);
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void predict_soc_native_init(void)
{
  loadDeepLearningNetwork(net.InternalState.InternalValue);
}

/*
 * File trailer for predict_soc_native.c
 *
 * [EOF]
 */

/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_opt5_direct.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 22:43:19
 */

/* Include Files */
#include "predict_soc_opt5_direct.h"
#include "loadDeepLearningNetwork.h"
#include "predict.h"
#include "predict_soc_opt5_direct_data.h"
#include "predict_soc_opt5_direct_emxutil.h"
#include "predict_soc_opt5_direct_initialize.h"
#include "predict_soc_opt5_direct_types.h"

/* Variable Definitions */
static c_coder_internal_ctarget_dlnetw net;

/* Function Definitions */
/*
 * Arguments    : void
 * Return Type  : void
 */
void c_predict_soc_opt5_direct_emx_i(void)
{
  c_emxInitStruct_coder_internal_(&net);
}

/*
 * #codegen
 *
 * Arguments    : const float in[50]
 * Return Type  : float
 */
float predict_soc_opt5_direct(const float in[50])
{
  if (!isInitialized_predict_soc_opt5_direct) {
    predict_soc_opt5_direct_initialize();
  }
  return dlnetwork_predict(net.InternalState.InternalValue, in);
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void predict_soc_opt5_direct_init(void)
{
  loadDeepLearningNetwork(net.InternalState.InternalValue);
}

/*
 * File trailer for predict_soc_opt5_direct.c
 *
 * [EOF]
 */

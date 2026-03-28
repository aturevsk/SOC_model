/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_opt4_direct.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 20:19:45
 */

/* Include Files */
#include "predict_soc_opt4_direct.h"
#include "predict.h"
#include "predict_soc_opt4_direct_data.h"
#include "predict_soc_opt4_direct_initialize.h"

/* Function Definitions */
/*
 * #codegen
 *
 * Arguments    : const float in[50]
 * Return Type  : float
 */
float predict_soc_opt4_direct(const float in[50])
{
  if (!isInitialized_predict_soc_opt4_direct) {
    predict_soc_opt4_direct_initialize();
  }
  return dlnetwork_predict(in);
}

/*
 * File trailer for predict_soc_opt4_direct.c
 *
 * [EOF]
 */

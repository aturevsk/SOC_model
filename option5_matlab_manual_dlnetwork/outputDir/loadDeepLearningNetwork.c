/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: loadDeepLearningNetwork.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 17:49:13
 */

/* Include Files */
#include "loadDeepLearningNetwork.h"
#include "predict_soc_native_types.h"
#include <string.h>

/* Function Definitions */
/*
 * Arguments    : coder_internal_DataHolder net_InternalState_InternalValue[4]
 * Return Type  : void
 */
void loadDeepLearningNetwork(
    coder_internal_DataHolder net_InternalState_InternalValue[4])
{
  net_InternalState_InternalValue[0].data.size[0] = 64;
  net_InternalState_InternalValue[0].data.size[1] = 1;
  net_InternalState_InternalValue[1].data.size[0] = 64;
  net_InternalState_InternalValue[1].data.size[1] = 1;
  net_InternalState_InternalValue[2].data.size[0] = 64;
  net_InternalState_InternalValue[2].data.size[1] = 1;
  net_InternalState_InternalValue[3].data.size[0] = 64;
  net_InternalState_InternalValue[3].data.size[1] = 1;
  memset(&net_InternalState_InternalValue[0].data.data[0], 0,
         64U * sizeof(float));
  memset(&net_InternalState_InternalValue[1].data.data[0], 0,
         64U * sizeof(float));
  memset(&net_InternalState_InternalValue[2].data.data[0], 0,
         64U * sizeof(float));
  memset(&net_InternalState_InternalValue[3].data.data[0], 0,
         64U * sizeof(float));
}

/*
 * File trailer for loadDeepLearningNetwork.c
 *
 * [EOF]
 */

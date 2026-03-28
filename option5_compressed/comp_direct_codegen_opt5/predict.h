/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict.h
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 22:43:19
 */

#ifndef PREDICT_H
#define PREDICT_H

/* Include Files */
#include "predict_soc_opt5_direct_types.h"
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
float dlnetwork_predict(
    const coder_internal_DataHolder c_dlnet_InternalState_InternalV[4],
    const float varargin_1_Data[50]);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for predict.h
 *
 * [EOF]
 */

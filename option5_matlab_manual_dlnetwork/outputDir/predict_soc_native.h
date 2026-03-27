/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_native.h
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 17:49:13
 */

#ifndef PREDICT_SOC_NATIVE_H
#define PREDICT_SOC_NATIVE_H

/* Include Files */
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern float predict_soc_native(const float in[50]);

void predict_soc_native_emx_init(void);

void predict_soc_native_init(void);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for predict_soc_native.h
 *
 * [EOF]
 */

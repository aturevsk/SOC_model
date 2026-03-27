/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 17:53:24
 */

/* Include Files */
#include "predict.h"
#include "callPredict.h"

/* Function Definitions */
/*
 * Arguments    : const float varargin_1_Data[50]
 * Return Type  : float
 */
float dlnetwork_predict(const float varargin_1_Data[50])
{
  float dataInputsSingle_0_f1[50];
  int b_k;
  int k;
  for (k = 0; k < 5; k++) {
    for (b_k = 0; b_k < 10; b_k++) {
      dataInputsSingle_0_f1[k + 5 * b_k] = varargin_1_Data[b_k + 10 * k];
    }
  }
  return predict(dataInputsSingle_0_f1);
}

/*
 * File trailer for predict.c
 *
 * [EOF]
 */

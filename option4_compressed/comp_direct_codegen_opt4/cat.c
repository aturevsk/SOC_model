/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: cat.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 20:19:45
 */

/* Include Files */
#include "cat.h"
#include <string.h>

/* Function Definitions */
/*
 * Arguments    : const float varargin_1[64]
 *                const float varargin_2[64]
 *                float y[128]
 * Return Type  : void
 */
void cat(const float varargin_1[64], const float varargin_2[64], float y[128])
{
  memcpy(&y[0], &varargin_1[0], 64U * sizeof(float));
  memcpy(&y[64], &varargin_2[0], 64U * sizeof(float));
}

/*
 * File trailer for cat.c
 *
 * [EOF]
 */

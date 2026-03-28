/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: elementwiseOperationInPlace.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 22:43:19
 */

/* Include Files */
#include "elementwiseOperationInPlace.h"
#include "omp.h"
#include <math.h>

/* Function Definitions */
/*
 * Arguments    : float X[64]
 * Return Type  : void
 */
void b_lambdaForColumnMajorGeneric(float X[64])
{
  int iElem;
#pragma omp parallel for num_threads(omp_get_max_threads())

  for (iElem = 0; iElem < 64; iElem++) {
    X[iElem] = tanhf(X[iElem]);
  }
}

/*
 * Arguments    : float X[64]
 * Return Type  : void
 */
void c_lambdaForColumnMajorGeneric(float X[64])
{
  int iElem;
#pragma omp parallel for num_threads(omp_get_max_threads())

  for (iElem = 0; iElem < 64; iElem++) {
    X[iElem] = fmaxf(0.0F, X[iElem]);
  }
}

/*
 * Arguments    : float X[192]
 * Return Type  : void
 */
void lambdaForColumnMajorGeneric(float X[192])
{
  int iElem;
#pragma omp parallel for num_threads(omp_get_max_threads())

  for (iElem = 0; iElem < 192; iElem++) {
    X[iElem] = 1.0F / (expf(-X[iElem]) + 1.0F);
  }
}

/*
 * File trailer for elementwiseOperationInPlace.c
 *
 * [EOF]
 */

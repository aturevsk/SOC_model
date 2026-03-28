/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_opt5_direct_emxutil.c
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 22:43:19
 */

/* Include Files */
#include "predict_soc_opt5_direct_emxutil.h"
#include "predict_soc_opt5_direct_types.h"

/* Function Definitions */
/*
 * Arguments    : coder_internal_DataHolder pMatrix[4]
 * Return Type  : void
 */
void c_emxInitMatrix_coder_internal_(coder_internal_DataHolder pMatrix[4])
{
  int i;
  for (i = 0; i < 4; i++) {
    d_emxInitStruct_coder_internal_(&pMatrix[i]);
  }
}

/*
 * Arguments    : c_coder_internal_ctarget_dlnetw *pStruct
 * Return Type  : void
 */
void c_emxInitStruct_coder_internal_(c_coder_internal_ctarget_dlnetw *pStruct)
{
  c_emxInitStruct_dltargets_inter(&pStruct->InternalState);
}

/*
 * Arguments    : dltargets_internal_NetworkTable *pStruct
 * Return Type  : void
 */
void c_emxInitStruct_dltargets_inter(dltargets_internal_NetworkTable *pStruct)
{
  c_emxInitMatrix_coder_internal_(pStruct->InternalValue);
}

/*
 * Arguments    : coder_internal_DataHolder *pStruct
 * Return Type  : void
 */
void d_emxInitStruct_coder_internal_(coder_internal_DataHolder *pStruct)
{
  pStruct->data.size[0] = 0;
  pStruct->data.size[1] = 0;
}

/*
 * File trailer for predict_soc_opt5_direct_emxutil.c
 *
 * [EOF]
 */

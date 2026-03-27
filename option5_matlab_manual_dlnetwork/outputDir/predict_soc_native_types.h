/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 * File: predict_soc_native_types.h
 *
 * MATLAB Coder version            : 26.1
 * C/C++ source code generated on  : 27-Mar-2026 17:49:13
 */

#ifndef PREDICT_SOC_NATIVE_TYPES_H
#define PREDICT_SOC_NATIVE_TYPES_H

/* Include Files */
#include "rtwtypes.h"

/* Type Definitions */
#ifndef struct_emxArray_real32_T_64x1
#define struct_emxArray_real32_T_64x1
struct emxArray_real32_T_64x1 {
  float data[64];
  int size[2];
};
#endif /* struct_emxArray_real32_T_64x1 */
#ifndef typedef_emxArray_real32_T_64x1
#define typedef_emxArray_real32_T_64x1
typedef struct emxArray_real32_T_64x1 emxArray_real32_T_64x1;
#endif /* typedef_emxArray_real32_T_64x1 */

#ifndef c_typedef_coder_internal_DataHo
#define c_typedef_coder_internal_DataHo
typedef struct {
  emxArray_real32_T_64x1 data;
} coder_internal_DataHolder;
#endif /* c_typedef_coder_internal_DataHo */

#ifndef c_typedef_dltargets_internal_Ne
#define c_typedef_dltargets_internal_Ne
typedef struct {
  coder_internal_DataHolder InternalValue[4];
} dltargets_internal_NetworkTable;
#endif /* c_typedef_dltargets_internal_Ne */

#ifndef c_typedef_c_coder_internal_ctar
#define c_typedef_c_coder_internal_ctar
typedef struct {
  dltargets_internal_NetworkTable InternalState;
} c_coder_internal_ctarget_dlnetw;
#endif /* c_typedef_c_coder_internal_ctar */

#endif
/*
 * File trailer for predict_soc_native_types.h
 *
 * [EOF]
 */

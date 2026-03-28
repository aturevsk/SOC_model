/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 *
 * File: soc_opt5_network.c
 *
 * Code generated for Simulink model 'soc_opt5_network'.
 *
 * Model version                  : 1.1
 * Simulink Coder version         : 26.1 (R2026a) 20-Nov-2025
 * C/C++ source code generated on : Fri Mar 27 22:45:07 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: ARM Compatible->ARM Cortex-M
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "soc_opt5_network.h"
#include "rtwtypes.h"
#include "soc_opt5_network_private.h"
#include <string.h>

/* Block signals (default storage) */
B_soc_opt5_network_T soc_opt5_network_B;

/* Block states (default storage) */
DW_soc_opt5_network_T soc_opt5_network_DW;

/* External inputs (root inport signals with default storage) */
ExtU_soc_opt5_network_T soc_opt5_network_U;

/* External outputs (root outports fed by signals with default storage) */
ExtY_soc_opt5_network_T soc_opt5_network_Y;

/* Real-time model */
static RT_MODEL_soc_opt5_network_T soc_opt5_network_M_;
RT_MODEL_soc_opt5_network_T *const soc_opt5_network_M = &soc_opt5_network_M_;

/*
 * Output and update for atomic system:
 *    '<S39>/Sigmoid Layer'
 *    '<S46>/Sigmoid Layer'
 *    '<S53>/Sigmoid Layer'
 *    '<S98>/Sigmoid Layer'
 *    '<S105>/Sigmoid Layer'
 *    '<S112>/Sigmoid Layer'
 */
void soc_opt5_network_SigmoidLayer(const int16_T rtu_In1[64], uint16_T rty_Out1
  [64])
{
  int32_T k;
  static const uint16_T b[26] = { 60U, 162U, 263U, 431U, 709U, 1157U, 1891U,
    3062U, 4905U, 7723U, 11856U, 17527U, 24668U, 32768U, 40865U, 48007U, 53678U,
    57812U, 60630U, 62474U, 63645U, 64377U, 64828U, 65105U, 65271U, 65445U };

  /* MATLAB Function: '<S44>/sigmoid_lookup' */
  for (k = 0; k < 64; k++) {
    int32_T indexZeroBased;
    int16_T rtu_In1_0;
    uint16_T tableLeft;
    rtu_In1_0 = rtu_In1[k];
    if (rtu_In1_0 < -13312) {
      rtu_In1_0 = -13312;
    }

    if (rtu_In1_0 > 12287) {
      rtu_In1_0 = 12287;
    }

    indexZeroBased = (rtu_In1_0 + 13312) >> 10;
    tableLeft = b[indexZeroBased];
    rty_Out1[k] = (uint16_T)(((((uint32_T)(rtu_In1_0 + 13312) & 1023U) *
      (uint16_T)(b[indexZeroBased + 1] - tableLeft)) >> 10) + tableLeft);
  }

  /* End of MATLAB Function: '<S44>/sigmoid_lookup' */
}

/*
 * Output and update for atomic system:
 *    '<S62>/Tanh Layer'
 *    '<S121>/Tanh Layer'
 */
void soc_opt5_network_TanhLayer(const int16_T rtu_In1[64], int16_T rty_Out1[64])
{
  int32_T k;
  static const int16_T b[33] = { -32746, -32732, -32708, -32670, -32606, -32501,
    -32329, -32048, -31589, -30874, -29729, -27860, -25057, -20939, -15259,
    -8099, 0, 8100, 15269, 20939, 25057, 27860, 29729, 30874, 31589, 32048,
    32329, 32501, 32606, 32670, 32708, 32732, 32746 };

  /* MATLAB Function: '<S67>/tanh_lookup' */
  for (k = 0; k < 64; k++) {
    int32_T indexZeroBased;
    int16_T rtu_In1_0;
    int16_T tableLeft;
    rtu_In1_0 = rtu_In1[k];
    if (rtu_In1_0 < -16384) {
      rtu_In1_0 = -16384;
    }

    if (rtu_In1_0 > 16383) {
      rtu_In1_0 = 16383;
    }

    indexZeroBased = (rtu_In1_0 + 16384) >> 10;
    tableLeft = b[indexZeroBased];
    rty_Out1[k] = (int16_T)((((int32_T)((uint32_T)(rtu_In1_0 + 16384) & 1023U) *
      (int16_T)(b[indexZeroBased + 1] - tableLeft)) >> 10) + tableLeft);
  }

  /* End of MATLAB Function: '<S67>/tanh_lookup' */
}

/* Model step function */
void soc_opt5_network_step(void)
{
  int32_T rtb_Wx_i[256];
  int32_T i;
  int32_T i_0;
  int32_T i_1;
  int32_T q0;
  int32_T q1;
  int32_T s19_iter;
  int16_T rtb_Add[256];
  int16_T rtb_WxRhb[256];
  int16_T rtb_DataTypeConversion[64];
  int16_T rtb_MatrixMultiply_a[64];
  int16_T rtb_y_e[64];
  int16_T rtb_h_t1_0;
  uint16_T rtb_y[64];
  int8_T rtb_h_t1[64];
  int8_T tmp;

  /* Outputs for Atomic SubSystem: '<S1>/lstm1' */
  /* Math: '<S20>/x'' incorporates:
   *  Inport: '<Root>/input'
   */
  for (i = 0; i < 5; i++) {
    rtb_h_t1[i] = soc_opt5_network_U.input[i];
  }

  /* End of Math: '<S20>/x'' */

  /* Product: '<S20>/x'*Q_in' incorporates:
   *  Constant: '<S20>/InputProjector'
   */
  for (i_0 = 0; i_0 < 5; i_0++) {
    rtb_h_t1_0 = 0;
    for (i_1 = 0; i_1 < 5; i_1++) {
      i = ((soc_opt5_network_ConstP.InputProjector_Value[5 * i_0 + i_1] *
            rtb_h_t1[i_1] + 2) >> 2) + rtb_h_t1_0;
      if (i > 32767) {
        i = 32767;
      } else if (i < -32768) {
        i = -32768;
      }

      rtb_h_t1_0 = (int16_T)i;
    }

    rtb_y_e[i_0] = rtb_h_t1_0;
  }

  /* End of Product: '<S20>/x'*Q_in' */

  /* Product: '<S20>/W*x' incorporates:
   *  Constant: '<S20>/InputWeights'
   *  Math: '<S20>/Q_in'*x'
   */
  for (i_0 = 0; i_0 < 256; i_0++) {
    q0 = 0;
    for (i_1 = 0; i_1 < 5; i_1++) {
      q1 = soc_opt5_network_ConstP.InputWeights_Value_g[(i_1 << 8) + i_0] *
        rtb_y_e[i_1];
      if ((q0 < 0) && (q1 < MIN_int32_T - q0)) {
        q0 = MIN_int32_T;
      } else if ((q0 > 0) && (q1 > MAX_int32_T - q0)) {
        q0 = MAX_int32_T;
      } else {
        q0 += q1;
      }
    }

    rtb_Wx_i[i_0] = q0;
  }

  /* End of Product: '<S20>/W*x' */

  /* Outputs for Iterator SubSystem: '<S4>/ForIteratorSubsystem' incorporates:
   *  ForIterator: '<S19>/ForIterator'
   */
  i_0 = soc_opt5_network_B.ProbeDimension_e[1];
  if (soc_opt5_network_B.ProbeDimension_e[1] > 2147483646) {
    i_0 = 2147483646;
  } else if (soc_opt5_network_B.ProbeDimension_e[1] < 0) {
    i_0 = 0;
  }

  for (s19_iter = 1; s19_iter <= i_0; s19_iter++) {
    /* Delay: '<S22>/HiddenStateDelay' */
    if (soc_opt5_network_DW.icLoad_h) {
      memset(&soc_opt5_network_DW.HiddenStateDelay_DSTATE[0], 0, sizeof(int8_T) <<
             6U);
    }

    /* Product: '<S31>/h_t-1'*Q_out' incorporates:
     *  Constant: '<S31>/OutputProjector'
     *  Delay: '<S22>/HiddenStateDelay'
     */
    for (i_1 = 0; i_1 < 49; i_1++) {
      rtb_h_t1_0 = 0;
      for (i = 0; i < 64; i++) {
        q0 = ((soc_opt5_network_ConstP.pooled3[(i_1 << 6) + i] *
               soc_opt5_network_DW.HiddenStateDelay_DSTATE[i] + 32) >> 6) +
          rtb_h_t1_0;
        if (q0 > 32767) {
          q0 = 32767;
        } else if (q0 < -32768) {
          q0 = -32768;
        }

        rtb_h_t1_0 = (int16_T)q0;
      }

      rtb_y_e[i_1] = rtb_h_t1_0;
    }

    /* End of Product: '<S31>/h_t-1'*Q_out' */

    /* Sum: '<S30>/Wx+Rh+b' incorporates:
     *  Constant: '<S30>/Bias'
     *  Constant: '<S31>/RecurrentWeights'
     *  Math: '<S31>/Q_out'*h_t-1'
     *  Product: '<S20>/W*x'
     *  Product: '<S31>/R*h_t-1'
     *  Selector: '<S19>/Selector1'
     *  Sum: '<S89>/Wx+Rh+b'
     */
    for (i_1 = 0; i_1 < 256; i_1++) {
      q0 = 0;
      for (i = 0; i < 49; i++) {
        q1 = (soc_opt5_network_ConstP.RecurrentWeights_Value[(i << 8) + i_1] *
              rtb_y_e[i]) << 1;
        if ((q0 < 0) && (q1 < MIN_int32_T - q0)) {
          q0 = MIN_int32_T;
        } else if ((q0 > 0) && (q1 > MAX_int32_T - q0)) {
          q0 = MAX_int32_T;
        } else {
          q0 += q1;
        }
      }

      i = rtb_Wx_i[i_1];
      if ((i < 0) && (q0 < MIN_int32_T - i)) {
        q0 = MIN_int32_T;
      } else if ((i > 0) && (q0 > MAX_int32_T - i)) {
        q0 = MAX_int32_T;
      } else {
        q0 += i;
      }

      q1 = soc_opt5_network_ConstP.Bias_Value_a[i_1];
      if ((q0 < 0) && (q1 < MIN_int32_T - q0)) {
        q0 = MIN_int32_T;
      } else if ((q0 > 0) && (q1 > MAX_int32_T - q0)) {
        q0 = MAX_int32_T;
      } else {
        q0 += q1;
      }

      i = (((uint32_T)q0 & 64U) != 0U) + (q0 >> 7);
      if (i > 32767) {
        i = 32767;
      } else if (i < -32768) {
        i = -32768;
      }

      rtb_WxRhb[i_1] = (int16_T)i;
    }

    /* End of Sum: '<S30>/Wx+Rh+b' */

    /* DataTypeConversion: '<S36>/Data Type Conversion' incorporates:
     *  Selector: '<S22>/Selector_f'
     *  Sum: '<S89>/Wx+Rh+b'
     */
    for (i = 0; i < 64; i++) {
      rtb_y_e[i] = (int16_T)((rtb_WxRhb[i + 64] + 1) >> 1);
    }

    /* End of DataTypeConversion: '<S36>/Data Type Conversion' */

    /* Outputs for Atomic SubSystem: '<S39>/Sigmoid Layer' */
    soc_opt5_network_SigmoidLayer(rtb_y_e, rtb_y);

    /* End of Outputs for SubSystem: '<S39>/Sigmoid Layer' */
    for (i = 0; i < 64; i++) {
      /* Delay: '<S22>/CellStateDelay' incorporates:
       *  Sum: '<S22>/CellAdd'
       */
      if (soc_opt5_network_DW.icLoad_g) {
        soc_opt5_network_DW.CellStateDelay_DSTATE[i] = 0;
      }

      /* Product: '<S22>/f*c_t-1' incorporates:
       *  Delay: '<S22>/CellStateDelay'
       *  Product: '<S2>/Matrix Multiply'
       */
      i_1 = soc_opt5_network_DW.CellStateDelay_DSTATE[i] * rtb_y[i];
      rtb_MatrixMultiply_a[i] = (int16_T)((((uint32_T)i_1 & 32768U) != 0U) +
        (i_1 >> 16));

      /* DataTypeConversion: '<S37>/Data Type Conversion' incorporates:
       *  Selector: '<S22>/Selector_i'
       *  Sum: '<S89>/Wx+Rh+b'
       */
      rtb_y_e[i] = (int16_T)((rtb_WxRhb[i] + 1) >> 1);
    }

    /* Outputs for Atomic SubSystem: '<S46>/Sigmoid Layer' */
    soc_opt5_network_SigmoidLayer(rtb_y_e, rtb_y);

    /* End of Outputs for SubSystem: '<S46>/Sigmoid Layer' */

    /* Outputs for Atomic SubSystem: '<S69>/Tanh Layer' */
    /* Selector: '<S22>/Selector_g' incorporates:
     *  Sum: '<S89>/Wx+Rh+b'
     */
    soc_opt5_network_TanhLayer(&rtb_WxRhb[128], rtb_y_e);

    /* End of Outputs for SubSystem: '<S69>/Tanh Layer' */
    for (i = 0; i < 64; i++) {
      /* Sum: '<S22>/CellAdd' incorporates:
       *  Product: '<S2>/Matrix Multiply'
       */
      q0 = rtb_MatrixMultiply_a[i];

      /* Product: '<S22>/i*g' */
      i_1 = rtb_y[i] * rtb_y_e[i];

      /* Sum: '<S22>/CellAdd' incorporates:
       *  Product: '<S22>/i*g'
       */
      q1 = (((uint32_T)i_1 & 32768U) != 0U) + (i_1 >> 16);
      if ((q0 < 0) && (q1 < MIN_int32_T - q0)) {
        q0 = MIN_int32_T;
      } else if ((q0 > 0) && (q1 > MAX_int32_T - q0)) {
        q0 = MAX_int32_T;
      } else {
        q0 += q1;
      }

      if (q0 > 32767) {
        q0 = 32767;
      } else if (q0 < -32768) {
        q0 = -32768;
      }

      soc_opt5_network_DW.CellStateDelay_DSTATE[i] = (int16_T)q0;

      /* DataTypeConversion: '<S60>/Data Type Conversion' incorporates:
       *  Sum: '<S22>/CellAdd'
       */
      rtb_DataTypeConversion[i] = (int16_T)(((int16_T)q0 + 4) >> 3);
    }

    /* Outputs for Atomic SubSystem: '<S62>/Tanh Layer' */
    soc_opt5_network_TanhLayer(rtb_DataTypeConversion, rtb_y_e);

    /* End of Outputs for SubSystem: '<S62>/Tanh Layer' */

    /* DataTypeConversion: '<S38>/Data Type Conversion' incorporates:
     *  Selector: '<S22>/Selector_o'
     *  Sum: '<S89>/Wx+Rh+b'
     */
    for (i = 0; i < 64; i++) {
      rtb_DataTypeConversion[i] = (int16_T)((rtb_WxRhb[i + 192] + 1) >> 1);
    }

    /* End of DataTypeConversion: '<S38>/Data Type Conversion' */

    /* Outputs for Atomic SubSystem: '<S53>/Sigmoid Layer' */
    soc_opt5_network_SigmoidLayer(rtb_DataTypeConversion, rtb_y);

    /* End of Outputs for SubSystem: '<S53>/Sigmoid Layer' */
    for (i = 0; i < 64; i++) {
      /* Product: '<S22>/HiddenStateProduct' incorporates:
       *  Selector: '<S81>/Selector_o'
       */
      i_1 = rtb_y_e[i] * rtb_y[i];
      i_1 = (((uint32_T)i_1 & 4194304U) != 0U) + (i_1 >> 23);
      if (i_1 > 127) {
        i_1 = 127;
      } else if (i_1 < -128) {
        i_1 = -128;
      }

      soc_opt5_network_DW.HiddenStateDelay_DSTATE[i] = (int8_T)i_1;

      /* Assignment: '<S76>/Assignment' incorporates:
       *  Product: '<S22>/HiddenStateProduct'
       */
      soc_opt5_network_B.Assignment[i] = (int8_T)i_1;
    }

    /* Update for Delay: '<S22>/HiddenStateDelay' */
    soc_opt5_network_DW.icLoad_h = false;

    /* Update for Delay: '<S22>/CellStateDelay' */
    soc_opt5_network_DW.icLoad_g = false;
  }

  /* End of Outputs for SubSystem: '<S4>/ForIteratorSubsystem' */
  /* End of Outputs for SubSystem: '<S1>/lstm1' */

  /* Outputs for Atomic SubSystem: '<S1>/lstm2' */
  /* Product: '<S79>/x'*Q_in' incorporates:
   *  Assignment: '<S76>/Assignment'
   *  Constant: '<S79>/InputProjector'
   *  Math: '<S79>/x''
   */
  for (i_0 = 0; i_0 < 49; i_0++) {
    rtb_h_t1_0 = 0;
    for (i_1 = 0; i_1 < 64; i_1++) {
      i = ((soc_opt5_network_ConstP.pooled3[(i_0 << 6) + i_1] *
            soc_opt5_network_B.Assignment[i_1] + 32) >> 6) + rtb_h_t1_0;
      if (i > 32767) {
        i = 32767;
      } else if (i < -32768) {
        i = -32768;
      }

      rtb_h_t1_0 = (int16_T)i;
    }

    rtb_y_e[i_0] = rtb_h_t1_0;
  }

  /* End of Product: '<S79>/x'*Q_in' */

  /* Product: '<S79>/W*x' incorporates:
   *  Constant: '<S79>/InputWeights'
   *  Math: '<S79>/Q_in'*x'
   */
  for (i_0 = 0; i_0 < 256; i_0++) {
    q0 = 0;
    for (i_1 = 0; i_1 < 49; i_1++) {
      q1 = (soc_opt5_network_ConstP.InputWeights_Value[(i_1 << 8) + i_0] *
            rtb_y_e[i_1]) << 1;
      if ((q0 < 0) && (q1 < MIN_int32_T - q0)) {
        q0 = MIN_int32_T;
      } else if ((q0 > 0) && (q1 > MAX_int32_T - q0)) {
        q0 = MAX_int32_T;
      } else {
        q0 += q1;
      }
    }

    rtb_Wx_i[i_0] = q0;
  }

  /* End of Product: '<S79>/W*x' */

  /* Outputs for Iterator SubSystem: '<S5>/ForIteratorSubsystem' incorporates:
   *  ForIterator: '<S78>/ForIterator'
   */
  i_0 = soc_opt5_network_B.ProbeDimension[1];
  if (soc_opt5_network_B.ProbeDimension[1] > 2147483646) {
    i_0 = 2147483646;
  } else if (soc_opt5_network_B.ProbeDimension[1] < 0) {
    i_0 = 0;
  }

  for (s19_iter = 1; s19_iter <= i_0; s19_iter++) {
    /* Delay: '<S81>/HiddenStateDelay' incorporates:
     *  Constant: '<S5>/initialHiddenState'
     */
    if (soc_opt5_network_DW.icLoad) {
      memset(&soc_opt5_network_DW.HiddenStateDelay_DSTATE_p[0], 0, sizeof(int8_T)
             << 6U);
    }

    /* Product: '<S90>/h_t-1'*Q_out' incorporates:
     *  Constant: '<S90>/OutputProjector'
     *  Delay: '<S81>/HiddenStateDelay'
     */
    for (i_1 = 0; i_1 < 38; i_1++) {
      rtb_h_t1_0 = 0;
      for (i = 0; i < 64; i++) {
        q0 = ((soc_opt5_network_ConstP.OutputProjector_Value[(i_1 << 6) + i] *
               soc_opt5_network_DW.HiddenStateDelay_DSTATE_p[i] + 32) >> 6) +
          rtb_h_t1_0;
        if (q0 > 32767) {
          q0 = 32767;
        } else if (q0 < -32768) {
          q0 = -32768;
        }

        rtb_h_t1_0 = (int16_T)q0;
      }

      rtb_WxRhb[i_1] = rtb_h_t1_0;
    }

    /* End of Product: '<S90>/h_t-1'*Q_out' */

    /* Sum: '<S89>/Wx+Rh+b' incorporates:
     *  Constant: '<S89>/Bias'
     *  Constant: '<S90>/RecurrentWeights'
     *  Math: '<S90>/Q_out'*h_t-1'
     *  Product: '<S79>/W*x'
     *  Product: '<S90>/R*h_t-1'
     *  Selector: '<S78>/Selector1'
     */
    for (i_1 = 0; i_1 < 256; i_1++) {
      q0 = 0;
      for (i = 0; i < 38; i++) {
        q1 = soc_opt5_network_ConstP.RecurrentWeights_Value_e[(i << 8) + i_1] *
          rtb_WxRhb[i];
        if ((q0 < 0) && (q1 < MIN_int32_T - q0)) {
          q0 = MIN_int32_T;
        } else if ((q0 > 0) && (q1 > MAX_int32_T - q0)) {
          q0 = MAX_int32_T;
        } else {
          q0 += q1;
        }
      }

      i = rtb_Wx_i[i_1];
      if ((i < 0) && (q0 < MIN_int32_T - i)) {
        q0 = MIN_int32_T;
      } else if ((i > 0) && (q0 > MAX_int32_T - i)) {
        q0 = MAX_int32_T;
      } else {
        q0 += i;
      }

      q1 = soc_opt5_network_ConstP.Bias_Value_n[i_1];
      if ((q0 < 0) && (q1 < MIN_int32_T - q0)) {
        q0 = MIN_int32_T;
      } else if ((q0 > 0) && (q1 > MAX_int32_T - q0)) {
        q0 = MAX_int32_T;
      } else {
        q0 += q1;
      }

      i = (((uint32_T)q0 & 64U) != 0U) + (q0 >> 7);
      if (i > 32767) {
        i = 32767;
      } else if (i < -32768) {
        i = -32768;
      }

      rtb_Add[i_1] = (int16_T)i;
    }

    memcpy(&rtb_WxRhb[0], &rtb_Add[0], sizeof(int16_T) << 8U);

    /* End of Sum: '<S89>/Wx+Rh+b' */

    /* DataTypeConversion: '<S95>/Data Type Conversion' incorporates:
     *  Selector: '<S81>/Selector_f'
     *  Sum: '<S89>/Wx+Rh+b'
     */
    for (i = 0; i < 64; i++) {
      rtb_y_e[i] = (int16_T)((rtb_WxRhb[i + 64] + 1) >> 1);
    }

    /* End of DataTypeConversion: '<S95>/Data Type Conversion' */

    /* Outputs for Atomic SubSystem: '<S98>/Sigmoid Layer' */
    soc_opt5_network_SigmoidLayer(rtb_y_e, rtb_y);

    /* End of Outputs for SubSystem: '<S98>/Sigmoid Layer' */
    for (i = 0; i < 64; i++) {
      /* Delay: '<S81>/CellStateDelay' incorporates:
       *  Constant: '<S5>/initialCellState'
       *  Sum: '<S81>/CellAdd'
       */
      if (soc_opt5_network_DW.icLoad_j) {
        soc_opt5_network_DW.CellStateDelay_DSTATE_d[i] = 0;
      }

      /* Product: '<S81>/f*c_t-1' incorporates:
       *  Delay: '<S81>/CellStateDelay'
       */
      i_1 = soc_opt5_network_DW.CellStateDelay_DSTATE_d[i] * rtb_y[i];
      rtb_Add[i] = (int16_T)((((uint32_T)i_1 & 32768U) != 0U) + (i_1 >> 16));

      /* DataTypeConversion: '<S96>/Data Type Conversion' incorporates:
       *  Selector: '<S81>/Selector_i'
       *  Sum: '<S89>/Wx+Rh+b'
       */
      rtb_y_e[i] = (int16_T)((rtb_WxRhb[i] + 1) >> 1);
    }

    /* Outputs for Atomic SubSystem: '<S105>/Sigmoid Layer' */
    soc_opt5_network_SigmoidLayer(rtb_y_e, rtb_y);

    /* End of Outputs for SubSystem: '<S105>/Sigmoid Layer' */

    /* Outputs for Atomic SubSystem: '<S128>/Tanh Layer' */
    /* Selector: '<S81>/Selector_g' incorporates:
     *  Sum: '<S89>/Wx+Rh+b'
     */
    soc_opt5_network_TanhLayer(&rtb_WxRhb[128], rtb_y_e);

    /* End of Outputs for SubSystem: '<S128>/Tanh Layer' */
    for (i = 0; i < 64; i++) {
      /* Sum: '<S81>/CellAdd' */
      q0 = rtb_Add[i];

      /* Product: '<S81>/i*g' incorporates:
       *  Selector: '<S81>/Selector_o'
       */
      i_1 = rtb_y[i] * rtb_y_e[i];

      /* Sum: '<S81>/CellAdd' incorporates:
       *  Product: '<S81>/i*g'
       */
      q1 = (((uint32_T)i_1 & 16384U) != 0U) + (i_1 >> 15);
      if ((q0 < 0) && (q1 < MIN_int32_T - q0)) {
        q0 = MIN_int32_T;
      } else if ((q0 > 0) && (q1 > MAX_int32_T - q0)) {
        q0 = MAX_int32_T;
      } else {
        q0 += q1;
      }

      if (q0 > 32767) {
        q0 = 32767;
      } else if (q0 < -32768) {
        q0 = -32768;
      }

      soc_opt5_network_DW.CellStateDelay_DSTATE_d[i] = (int16_T)q0;

      /* DataTypeConversion: '<S119>/Data Type Conversion' incorporates:
       *  Sum: '<S81>/CellAdd'
       */
      rtb_DataTypeConversion[i] = (int16_T)(((int16_T)q0 + 8) >> 4);
    }

    /* Outputs for Atomic SubSystem: '<S121>/Tanh Layer' */
    soc_opt5_network_TanhLayer(rtb_DataTypeConversion, rtb_y_e);

    /* End of Outputs for SubSystem: '<S121>/Tanh Layer' */

    /* DataTypeConversion: '<S97>/Data Type Conversion' incorporates:
     *  Selector: '<S81>/Selector_o'
     *  Sum: '<S89>/Wx+Rh+b'
     */
    for (i = 0; i < 64; i++) {
      rtb_DataTypeConversion[i] = (int16_T)((rtb_WxRhb[i + 192] + 1) >> 1);
    }

    /* End of DataTypeConversion: '<S97>/Data Type Conversion' */

    /* Outputs for Atomic SubSystem: '<S112>/Sigmoid Layer' */
    soc_opt5_network_SigmoidLayer(rtb_DataTypeConversion, rtb_y);

    /* End of Outputs for SubSystem: '<S112>/Sigmoid Layer' */

    /* Update for Delay: '<S81>/HiddenStateDelay' */
    soc_opt5_network_DW.icLoad = false;
    for (i = 0; i < 64; i++) {
      /* Product: '<S81>/HiddenStateProduct' */
      i_1 = rtb_y_e[i] * rtb_y[i];
      i_1 = (((uint32_T)i_1 & 2097152U) != 0U) + (i_1 >> 22);
      if (i_1 > 127) {
        i_1 = 127;
      } else if (i_1 < -128) {
        i_1 = -128;
      }

      /* Product: '<S81>/HiddenStateProduct' */
      soc_opt5_network_B.Y[i] = (int8_T)i_1;

      /* Update for Delay: '<S81>/HiddenStateDelay' incorporates:
       *  Product: '<S81>/HiddenStateProduct'
       */
      soc_opt5_network_DW.HiddenStateDelay_DSTATE_p[i] = (int8_T)i_1;
    }

    /* Update for Delay: '<S81>/CellStateDelay' */
    soc_opt5_network_DW.icLoad_j = false;
  }

  /* End of Outputs for SubSystem: '<S5>/ForIteratorSubsystem' */
  /* End of Outputs for SubSystem: '<S1>/lstm2' */

  /* Outputs for Atomic SubSystem: '<S1>/fc2' */
  /* Product: '<S3>/Matrix Multiply' */
  i_0 = 0;

  /* Outputs for Atomic SubSystem: '<S1>/fc1' */
  for (i_1 = 0; i_1 < 64; i_1++) {
    /* DataTypeConversion: '<S11>/Data Type Conversion' incorporates:
     *  Constant: '<S2>/Bias'
     *  Constant: '<S2>/Weights'
     *  Product: '<S2>/Matrix Multiply'
     *  Product: '<S81>/HiddenStateProduct'
     *  Sum: '<S10>/Add'
     */
    i = 0;
    for (q0 = 0; q0 < 64; q0++) {
      i += soc_opt5_network_ConstP.Weights_Value[(q0 << 6) + i_1] *
        soc_opt5_network_B.Y[q0];
    }

    i += soc_opt5_network_ConstP.Bias_Value_m[i_1];
    i = (((uint32_T)i & 2048U) != 0U) + (i >> 12);
    if (i > 127) {
      i = 127;
    } else if (i < -128) {
      i = -128;
    }

    /* Outputs for Atomic SubSystem: '<S1>/relu1' */
    /* Product: '<S3>/Matrix Multiply' incorporates:
     *  Constant: '<S3>/Weights'
     *  DataTypeConversion: '<S11>/Data Type Conversion'
     *  MinMax: '<S6>/Max'
     */
    if (i >= 0) {
      tmp = (int8_T)i;
    } else {
      tmp = 0;
    }

    i_0 += soc_opt5_network_ConstP.Weights_Value_i[i_1] * tmp;

    /* End of Outputs for SubSystem: '<S1>/relu1' */
  }

  /* End of Outputs for SubSystem: '<S1>/fc1' */

  /* Outport: '<Root>/fc2_out' incorporates:
   *  Constant: '<S3>/Bias'
   *  DataTypeConversion: '<S1>/fc2_out_cast'
   *  Sum: '<S16>/Add'
   */
  soc_opt5_network_Y.fc2_out = (real32_T)(i_0 + 207) * 7.6293945E-6F;

  /* End of Outputs for SubSystem: '<S1>/fc2' */
}

/* Model initialize function */
void soc_opt5_network_initialize(void)
{
  /* SystemInitialize for Atomic SubSystem: '<S1>/lstm1' */
  /* SystemInitialize for Iterator SubSystem: '<S4>/ForIteratorSubsystem' */
  /* Start for Probe: '<S19>/Probe Dimension' */
  soc_opt5_network_B.ProbeDimension_e[0] = 256;
  soc_opt5_network_B.ProbeDimension_e[1] = 1;

  /* InitializeConditions for Delay: '<S22>/HiddenStateDelay' */
  soc_opt5_network_DW.icLoad_h = true;

  /* InitializeConditions for Delay: '<S22>/CellStateDelay' */
  soc_opt5_network_DW.icLoad_g = true;

  /* End of SystemInitialize for SubSystem: '<S4>/ForIteratorSubsystem' */
  /* End of SystemInitialize for SubSystem: '<S1>/lstm1' */

  /* SystemInitialize for Atomic SubSystem: '<S1>/lstm2' */
  /* SystemInitialize for Iterator SubSystem: '<S5>/ForIteratorSubsystem' */
  /* Start for Probe: '<S78>/Probe Dimension' */
  soc_opt5_network_B.ProbeDimension[0] = 256;
  soc_opt5_network_B.ProbeDimension[1] = 1;

  /* InitializeConditions for Delay: '<S81>/HiddenStateDelay' */
  soc_opt5_network_DW.icLoad = true;

  /* InitializeConditions for Delay: '<S81>/CellStateDelay' */
  soc_opt5_network_DW.icLoad_j = true;

  /* End of SystemInitialize for SubSystem: '<S5>/ForIteratorSubsystem' */
  /* End of SystemInitialize for SubSystem: '<S1>/lstm2' */
}

/* Model terminate function */
void soc_opt5_network_terminate(void)
{
  /* (no terminate code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */

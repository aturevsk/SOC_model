/*
 * Prerelease License - for engineering feedback and testing purposes
 * only. Not for sale.
 *
 * File: soc_opt5_network.h
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

#ifndef soc_opt5_network_h_
#define soc_opt5_network_h_
#ifndef soc_opt5_network_COMMON_INCLUDES_
#define soc_opt5_network_COMMON_INCLUDES_
#include "rtwtypes.h"
#include "math.h"
#endif                                 /* soc_opt5_network_COMMON_INCLUDES_ */

#include "soc_opt5_network_types.h"

/* Macros for accessing real-time model data structure */
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

/* Block signals (default storage) */
typedef struct {
  int32_T ProbeDimension[2];           /* '<S78>/Probe Dimension' */
  int32_T ProbeDimension_e[2];         /* '<S19>/Probe Dimension' */
  int8_T Y[64];                        /* '<S81>/HiddenStateProduct' */
  int8_T Assignment[64];               /* '<S76>/Assignment' */
} B_soc_opt5_network_T;

/* Block states (default storage) for system '<Root>' */
typedef struct {
  int16_T CellStateDelay_DSTATE[64];   /* '<S22>/CellStateDelay' */
  int16_T CellStateDelay_DSTATE_d[64]; /* '<S81>/CellStateDelay' */
  int8_T HiddenStateDelay_DSTATE[64];  /* '<S22>/HiddenStateDelay' */
  int8_T HiddenStateDelay_DSTATE_p[64];/* '<S81>/HiddenStateDelay' */
  boolean_T icLoad;                    /* '<S81>/HiddenStateDelay' */
  boolean_T icLoad_j;                  /* '<S81>/CellStateDelay' */
  boolean_T icLoad_h;                  /* '<S22>/HiddenStateDelay' */
  boolean_T icLoad_g;                  /* '<S22>/CellStateDelay' */
} DW_soc_opt5_network_T;

/* Constant parameters (default storage) */
typedef struct {
  /* Computed Parameter: Bias_Value_m
   * Referenced by: '<S2>/Bias'
   */
  int32_T Bias_Value_m[64];

  /* Computed Parameter: Bias_Value_a
   * Referenced by: '<S30>/Bias'
   */
  int32_T Bias_Value_a[256];

  /* Computed Parameter: Bias_Value_n
   * Referenced by: '<S89>/Bias'
   */
  int32_T Bias_Value_n[256];

  /* Computed Parameter: Weights_Value
   * Referenced by: '<S2>/Weights'
   */
  int8_T Weights_Value[4096];

  /* Computed Parameter: Weights_Value_i
   * Referenced by: '<S3>/Weights'
   */
  int8_T Weights_Value_i[64];

  /* Computed Parameter: InputProjector_Value
   * Referenced by: '<S20>/InputProjector'
   */
  int8_T InputProjector_Value[25];

  /* Pooled Parameter (Expression: )
   * Referenced by:
   *   '<S79>/InputProjector'
   *   '<S31>/OutputProjector'
   */
  int8_T pooled3[3136];

  /* Computed Parameter: RecurrentWeights_Value
   * Referenced by: '<S31>/RecurrentWeights'
   */
  int8_T RecurrentWeights_Value[12544];

  /* Computed Parameter: OutputProjector_Value
   * Referenced by: '<S90>/OutputProjector'
   */
  int8_T OutputProjector_Value[2432];

  /* Computed Parameter: RecurrentWeights_Value_e
   * Referenced by: '<S90>/RecurrentWeights'
   */
  int8_T RecurrentWeights_Value_e[9728];

  /* Computed Parameter: InputWeights_Value
   * Referenced by: '<S79>/InputWeights'
   */
  int8_T InputWeights_Value[12544];

  /* Computed Parameter: InputWeights_Value_g
   * Referenced by: '<S20>/InputWeights'
   */
  int8_T InputWeights_Value_g[1280];
} ConstP_soc_opt5_network_T;

/* External inputs (root inport signals with default storage) */
typedef struct {
  int8_T input[5];                     /* '<Root>/input' */
} ExtU_soc_opt5_network_T;

/* External outputs (root outports fed by signals with default storage) */
typedef struct {
  real32_T fc2_out;                    /* '<Root>/fc2_out' */
} ExtY_soc_opt5_network_T;

/* Real-time Model Data Structure */
struct tag_RTM_soc_opt5_network_T {
  const char_T * volatile errorStatus;
};

/* Block signals (default storage) */
extern B_soc_opt5_network_T soc_opt5_network_B;

/* Block states (default storage) */
extern DW_soc_opt5_network_T soc_opt5_network_DW;

/* External inputs (root inport signals with default storage) */
extern ExtU_soc_opt5_network_T soc_opt5_network_U;

/* External outputs (root outports fed by signals with default storage) */
extern ExtY_soc_opt5_network_T soc_opt5_network_Y;

/* Constant parameters (default storage) */
extern const ConstP_soc_opt5_network_T soc_opt5_network_ConstP;

/* Model entry point functions */
extern void soc_opt5_network_initialize(void);
extern void soc_opt5_network_step(void);
extern void soc_opt5_network_terminate(void);

/* Real-time Model object */
extern RT_MODEL_soc_opt5_network_T *const soc_opt5_network_M;

/*-
 * These blocks were eliminated from the model due to optimizations:
 *
 * Block '<S76>/Data Type Duplicate' : Unused code path elimination
 * Block '<S79>/Constant' : Unused code path elimination
 * Block '<S79>/Data Type Conversion' : Unused code path elimination
 * Block '<S79>/PreallocatedOutput' : Unused code path elimination
 * Block '<S12>/Reshape' : Reshape block reduction
 * Block '<S17>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S18>/Reshape' : Reshape block reduction
 * Block '<S43>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S50>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S57>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S61>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S66>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S73>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S77>/OutputDTConversion' : Eliminate redundant data type conversion
 * Block '<S1>/lstm1_in_cast' : Eliminate redundant data type conversion
 * Block '<S102>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S109>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S116>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S120>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S125>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S132>/Data Type Conversion' : Eliminate redundant data type conversion
 * Block '<S136>/OutputDTConversion' : Eliminate redundant data type conversion
 */

/*-
 * The generated code includes comments that allow you to trace directly
 * back to the appropriate location in the model.  The basic format
 * is <system>/block_name, where system is the system number (uniquely
 * assigned by Simulink) and block_name is the name of the block.
 *
 * Use the MATLAB hilite_system command to trace the generated code back
 * to the model.  For example,
 *
 * hilite_system('<S3>')    - opens system 3
 * hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
 *
 * Here is the system hierarchy for this model
 *
 * '<Root>' : 'soc_opt5_network'
 * '<S1>'   : 'soc_opt5_network/soc_opt5_network'
 * '<S2>'   : 'soc_opt5_network/soc_opt5_network/fc1'
 * '<S3>'   : 'soc_opt5_network/soc_opt5_network/fc2'
 * '<S4>'   : 'soc_opt5_network/soc_opt5_network/lstm1'
 * '<S5>'   : 'soc_opt5_network/soc_opt5_network/lstm2'
 * '<S6>'   : 'soc_opt5_network/soc_opt5_network/relu1'
 * '<S7>'   : 'soc_opt5_network/soc_opt5_network/fc1/BiasAddition'
 * '<S8>'   : 'soc_opt5_network/soc_opt5_network/fc1/OutputDataType'
 * '<S9>'   : 'soc_opt5_network/soc_opt5_network/fc1/Reshape'
 * '<S10>'  : 'soc_opt5_network/soc_opt5_network/fc1/BiasAddition/Add'
 * '<S11>'  : 'soc_opt5_network/soc_opt5_network/fc1/OutputDataType/Convert'
 * '<S12>'  : 'soc_opt5_network/soc_opt5_network/fc1/Reshape/Reshape'
 * '<S13>'  : 'soc_opt5_network/soc_opt5_network/fc2/BiasAddition'
 * '<S14>'  : 'soc_opt5_network/soc_opt5_network/fc2/OutputDataType'
 * '<S15>'  : 'soc_opt5_network/soc_opt5_network/fc2/Reshape'
 * '<S16>'  : 'soc_opt5_network/soc_opt5_network/fc2/BiasAddition/Add'
 * '<S17>'  : 'soc_opt5_network/soc_opt5_network/fc2/OutputDataType/Convert'
 * '<S18>'  : 'soc_opt5_network/soc_opt5_network/fc2/Reshape/Reshape'
 * '<S19>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem'
 * '<S20>'  : 'soc_opt5_network/soc_opt5_network/lstm1/InputWeightsMatrixMultiply'
 * '<S21>'  : 'soc_opt5_network/soc_opt5_network/lstm1/OutputDataType'
 * '<S22>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore'
 * '<S23>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/OutputMode'
 * '<S24>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GAF_f_InputDataType'
 * '<S25>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GAF_i_InputDataType'
 * '<S26>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GAF_o_InputDataType'
 * '<S27>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f'
 * '<S28>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i'
 * '<S29>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o'
 * '<S30>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/LinearGateAdd'
 * '<S31>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/RecurrentWeightsMatrixMultiply'
 * '<S32>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/SAF_c_InputDataType'
 * '<S33>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/SAF_g_InputDataType'
 * '<S34>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c'
 * '<S35>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g'
 * '<S36>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GAF_f_InputDataType/Convert'
 * '<S37>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GAF_i_InputDataType/Convert'
 * '<S38>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GAF_o_InputDataType/Convert'
 * '<S39>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid'
 * '<S40>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid/Sigmoid Layer'
 * '<S41>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid/Sigmoid Layer/OutputDataType'
 * '<S42>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid/Sigmoid Layer/Sigmoid_VSS'
 * '<S43>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid/Sigmoid Layer/OutputDataType/Convert'
 * '<S44>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid/Sigmoid Layer/Sigmoid_VSS/Lookup'
 * '<S45>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid/Sigmoid Layer/Sigmoid_VSS/Lookup/sigmoid_lookup'
 * '<S46>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid'
 * '<S47>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid/Sigmoid Layer'
 * '<S48>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid/Sigmoid Layer/OutputDataType'
 * '<S49>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid/Sigmoid Layer/Sigmoid_VSS'
 * '<S50>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid/Sigmoid Layer/OutputDataType/Convert'
 * '<S51>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid/Sigmoid Layer/Sigmoid_VSS/Lookup'
 * '<S52>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid/Sigmoid Layer/Sigmoid_VSS/Lookup/sigmoid_lookup'
 * '<S53>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid'
 * '<S54>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid/Sigmoid Layer'
 * '<S55>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid/Sigmoid Layer/OutputDataType'
 * '<S56>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid/Sigmoid Layer/Sigmoid_VSS'
 * '<S57>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid/Sigmoid Layer/OutputDataType/Convert'
 * '<S58>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid/Sigmoid Layer/Sigmoid_VSS/Lookup'
 * '<S59>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid/Sigmoid Layer/Sigmoid_VSS/Lookup/sigmoid_lookup'
 * '<S60>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/SAF_c_InputDataType/Convert'
 * '<S61>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/SAF_g_InputDataType/Convert'
 * '<S62>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh'
 * '<S63>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh/Tanh Layer'
 * '<S64>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh/Tanh Layer/OutputDataType'
 * '<S65>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh/Tanh Layer/Tanh_VSS'
 * '<S66>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh/Tanh Layer/OutputDataType/Convert'
 * '<S67>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh/Tanh Layer/Tanh_VSS/Lookup'
 * '<S68>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh/Tanh Layer/Tanh_VSS/Lookup/tanh_lookup'
 * '<S69>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh'
 * '<S70>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh/Tanh Layer'
 * '<S71>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh/Tanh Layer/OutputDataType'
 * '<S72>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh/Tanh Layer/Tanh_VSS'
 * '<S73>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh/Tanh Layer/OutputDataType/Convert'
 * '<S74>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh/Tanh Layer/Tanh_VSS/Lookup'
 * '<S75>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh/Tanh Layer/Tanh_VSS/Lookup/tanh_lookup'
 * '<S76>'  : 'soc_opt5_network/soc_opt5_network/lstm1/ForIteratorSubsystem/OutputMode/OutputMode_sequence'
 * '<S77>'  : 'soc_opt5_network/soc_opt5_network/lstm1/OutputDataType/Convert'
 * '<S78>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem'
 * '<S79>'  : 'soc_opt5_network/soc_opt5_network/lstm2/InputWeightsMatrixMultiply'
 * '<S80>'  : 'soc_opt5_network/soc_opt5_network/lstm2/OutputDataType'
 * '<S81>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore'
 * '<S82>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/OutputMode'
 * '<S83>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GAF_f_InputDataType'
 * '<S84>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GAF_i_InputDataType'
 * '<S85>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GAF_o_InputDataType'
 * '<S86>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f'
 * '<S87>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i'
 * '<S88>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o'
 * '<S89>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/LinearGateAdd'
 * '<S90>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/RecurrentWeightsMatrixMultiply'
 * '<S91>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/SAF_c_InputDataType'
 * '<S92>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/SAF_g_InputDataType'
 * '<S93>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c'
 * '<S94>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g'
 * '<S95>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GAF_f_InputDataType/Convert'
 * '<S96>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GAF_i_InputDataType/Convert'
 * '<S97>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GAF_o_InputDataType/Convert'
 * '<S98>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid'
 * '<S99>'  : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid/Sigmoid Layer'
 * '<S100>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid/Sigmoid Layer/OutputDataType'
 * '<S101>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid/Sigmoid Layer/Sigmoid_VSS'
 * '<S102>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid/Sigmoid Layer/OutputDataType/Convert'
 * '<S103>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid/Sigmoid Layer/Sigmoid_VSS/Lookup'
 * '<S104>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_f/sigmoid/Sigmoid Layer/Sigmoid_VSS/Lookup/sigmoid_lookup'
 * '<S105>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid'
 * '<S106>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid/Sigmoid Layer'
 * '<S107>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid/Sigmoid Layer/OutputDataType'
 * '<S108>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid/Sigmoid Layer/Sigmoid_VSS'
 * '<S109>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid/Sigmoid Layer/OutputDataType/Convert'
 * '<S110>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid/Sigmoid Layer/Sigmoid_VSS/Lookup'
 * '<S111>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_i/sigmoid/Sigmoid Layer/Sigmoid_VSS/Lookup/sigmoid_lookup'
 * '<S112>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid'
 * '<S113>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid/Sigmoid Layer'
 * '<S114>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid/Sigmoid Layer/OutputDataType'
 * '<S115>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid/Sigmoid Layer/Sigmoid_VSS'
 * '<S116>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid/Sigmoid Layer/OutputDataType/Convert'
 * '<S117>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid/Sigmoid Layer/Sigmoid_VSS/Lookup'
 * '<S118>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/GateActivationFunction_o/sigmoid/Sigmoid Layer/Sigmoid_VSS/Lookup/sigmoid_lookup'
 * '<S119>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/SAF_c_InputDataType/Convert'
 * '<S120>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/SAF_g_InputDataType/Convert'
 * '<S121>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh'
 * '<S122>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh/Tanh Layer'
 * '<S123>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh/Tanh Layer/OutputDataType'
 * '<S124>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh/Tanh Layer/Tanh_VSS'
 * '<S125>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh/Tanh Layer/OutputDataType/Convert'
 * '<S126>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh/Tanh Layer/Tanh_VSS/Lookup'
 * '<S127>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_c/tanh/Tanh Layer/Tanh_VSS/Lookup/tanh_lookup'
 * '<S128>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh'
 * '<S129>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh/Tanh Layer'
 * '<S130>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh/Tanh Layer/OutputDataType'
 * '<S131>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh/Tanh Layer/Tanh_VSS'
 * '<S132>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh/Tanh Layer/OutputDataType/Convert'
 * '<S133>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh/Tanh Layer/Tanh_VSS/Lookup'
 * '<S134>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/LSTMProjectedCore/StateActivationFunction_g/tanh/Tanh Layer/Tanh_VSS/Lookup/tanh_lookup'
 * '<S135>' : 'soc_opt5_network/soc_opt5_network/lstm2/ForIteratorSubsystem/OutputMode/OutputMode_last'
 * '<S136>' : 'soc_opt5_network/soc_opt5_network/lstm2/OutputDataType/Convert'
 */
#endif                                 /* soc_opt5_network_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */

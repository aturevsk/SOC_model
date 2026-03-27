/**
 * soc_model.h
 *
 * LSTM-based State of Charge (SOC) estimation model.
 * Architecture: 2-layer LSTM (input=5, hidden=64) -> Linear head -> SOC value
 *
 * Target: STM32F746G-Discovery (Cortex-M7)
 */

#ifndef SOC_MODEL_H
#define SOC_MODEL_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Initialize model state (zeros hidden/cell states).
 * Must be called before first prediction or to reset between sequences.
 */
void soc_model_init(void);

/**
 * Run inference on a 10-timestep, 5-feature input sequence.
 *
 * @param input  [SEQ_LEN][INPUT_SIZE] = [10][5] row-major float array
 * @return       Predicted SOC value (single float)
 */
float soc_model_predict(const float input[10][5]);

#ifdef __cplusplus
}
#endif

#endif /* SOC_MODEL_H */

# SOC Model — Embedded C Code Generation from PyTorch LSTM

Comparative analysis of **5 approaches** for generating embedded C code from a PyTorch LSTM-based State of Charge (SOC) estimation model, targeting the **STM32F746G-Discovery** board (ARM Cortex-M7, 216 MHz).

## [Interactive Explorer](https://arkadiyturevskiy.github.io/SOC_model/)

Browse all source code, benchmark results, accuracy data, and issues in the interactive web app.

## Model Architecture

| Property | Value |
|----------|-------|
| Architecture | 2-layer LSTM (hidden=64) + Dense Head |
| Input | `[1, 10, 5]` — 10 timesteps, 5 features |
| Output | `[1, 1]` — SOC scalar |
| Parameters | 55,681 (217.5 KB float32) |
| Framework | PyTorch ExportedProgram (.pt2) |

## Results Summary

| Option | Approach | Status | Host C (µs) | C Lines | Embedded Coder |
|--------|----------|--------|-------------|---------|----------------|
| 1 | Manual C | **PASS** | 84.8 | 222 | N/A |
| 2 | PyTorch Coder SP | **PASS** | **48.7** | 12,322 | Yes |
| 3 | importNetworkFromPyTorch | **FAIL** | N/A | N/A | No |
| 4 | ONNX Import | **PASS** | 52.5 | 11,708 | Yes* |
| 5 | Manual dlnetwork | **PASS** | 51.5 | 11,563 | Yes |

\* Requires `DeepLearningConfig('none')` to be set explicitly.

### Numerical Equivalence (100 random test vectors)

All working options pass 100/100 tests with max absolute error < 1.5e-8.

### Key Findings

- **MATLAB Coder generates faster C code** than hand-written C on host (~1.7x) due to blocked matrix multiply optimizations
- **Option 2** (PyTorch Coder Support Package) is the fastest and most direct path
- **Option 5** (manual dlnetwork) is the most robust MathWorks approach — no custom layers, full Embedded Coder support
- **Option 3** fails due to non-codegen custom layer from `importNetworkFromPyTorch`
- **Critical config**: Always set `DeepLearningConfig('none')` when using Embedded Coder for deep learning codegen

## Project Structure

```
SOC_model/
├── soc_model.pt2                    # Original PyTorch model
├── soc_model_legacy.onnx            # ONNX export (legacy, opset 14)
├── option1_c/                       # Option 1: Manual C implementation
├── option2_matlab_pytorch_coder/    # Option 2: PyTorch Coder SP
├── option3_matlab_import_pytorch/   # Option 3: importNetworkFromPyTorch (FAILED)
├── option4_matlab_onnx/             # Option 4: ONNX import + codegen
├── option5_matlab_manual_dlnetwork/ # Option 5: Manual native dlnetwork
├── benchmarks/                      # Host benchmark harness
├── report/                          # PDF report generator
├── docs/                            # Interactive web app (GitHub Pages)
└── SOC_Model_CodeGen_Report.pdf     # Full PDF report
```

## Requirements

- **Option 1**: Any C99 compiler (gcc, arm-none-eabi-gcc)
- **Options 2-5**: MATLAB R2026a + Deep Learning Toolbox + MATLAB Coder + Embedded Coder
- **Option 2**: MATLAB Coder Support Package for PyTorch and LiteRT Models
- **Option 4**: Deep Learning Toolbox Converter for ONNX Model Format

## Quick Start

### Option 1 (Manual C)
```bash
cd option1_c
make
./soc_test
```

### Options 2-5 (MATLAB)
```matlab
cd option2_matlab_pytorch_coder  % or option3/4/5
generate_code_pytorch_coder      % run the main script
```

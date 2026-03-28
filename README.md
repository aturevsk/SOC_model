# SOC Model — Embedded C Code Generation + Compression from PyTorch LSTM

Comparative analysis of **5 approaches** for generating embedded C code from a PyTorch LSTM-based State of Charge (SOC) estimation model, targeting the **STM32F746G-Discovery** board (ARM Cortex-M7, 216 MHz), plus a **model compression sub-pipeline** for Options 4 and 5.

## [Interactive Explorer](https://arkadiyturevskiy.github.io/SOC_model/)

Browse all source code, benchmark results, accuracy data, compression results, and issues in the interactive web app.

## Model Architecture

| Property | Value |
|----------|-------|
| Architecture | 2-layer LSTM (hidden=64) + Dense Head |
| Input | `[1, 10, 5]` — 10 timesteps, 5 features |
| Output | `[1, 1]` — SOC scalar |
| Parameters | 55,681 (217.5 KB float32) |
| Framework | PyTorch ExportedProgram (.pt2) |

## Code Generation Results

| Option | Approach | Status | Host C (µs) | C Lines | Embedded Coder |
|--------|----------|--------|-------------|---------|----------------|
| 1 | Manual C | **PASS** | 84.8 | 222 | N/A |
| 2 | PyTorch Coder SP | **PASS** | **48.7** | 12,322 | Yes |
| 3 | importNetworkFromPyTorch | **FAIL** | N/A | N/A | No |
| 4 | ONNX Import | **PASS** | 52.5 | 11,708 | Yes* |
| 5 | Manual dlnetwork | **PASS** | 51.5 | 11,563 | Yes |

\* Requires `DeepLearningConfig('none')` to be set explicitly.

## Compression Results (Options 4 & 5)

Post-training compression targeting **MAE < 1e-3** vs PyTorch on 100 test vectors.

### Option 5 — Best Result: `proj10_quant` (neuronPCA projection + int8 quantization)

| Technique | Status | MAE | Size | Savings |
|-----------|--------|-----|------|---------|
| Baseline float32 | — | 5.16e-09 | 215.5 KB | 0% |
| proj_cf01 (10% projection) | ✅ PASS | 3.93e-04 | 193.6 KB | 10.2% |
| **proj10_quant (10% proj + int8)** | **✅ PASS** | **9.50e-04** | **48.4 KB** | **77.5%** |
| quant_int8 (baseline + int8) | ✅ PASS | 9.31e-04 | 53.9 KB | 75.0% |
| manual_int8 | ✅ PASS | 3.55e-04 | 53.9 KB | 75.0% |
| proj_cf07 (70% projection) | ❌ FAIL | 1.70e-03 | 61.9 KB | 71.3% |

The winner `proj10_quant` chains two stages: `neuronPCA → compressNetworkUsingProjection(10%) → dlquantizer(int8)`, achieving **77.5% Flash reduction** (215.5 KB → 48.4 KB) while staying within the accuracy budget.

### Option 4 — Best Result: `manual_int8` (75% savings)

ONNX custom layers block `dlquantizer` and Simulink export. Manual int8 weight quantization (MAE=3.55e-04, 53.9 KB) is the best achievable approach.

### Simulink & Codegen (Option 5 compressed)

| Stage | Result |
|-------|--------|
| MATLAB predict vs PyTorch | MAE = 9.50e-04 ✅ |
| Simulink simulation | MAE = 2.09e-03 ✅ |
| Simulink fixed-point codegen | 3 C files, 262 KB (**69% smaller** than float32 direct) |

### Key Technical Notes

- `prepareNetwork(qObj)` **must** be called before `calibrate()` — without it, LSTM `(h,c)` states cause `fi()` type error
- `calibrate()` only accepts `ArrayDatastore` of `[T×F]` cell sequences (not minibatchqueue)
- Projection only works at ≤10% goal — test data has very narrow output range (~-0.031 ± 0.002)
- macOS R2026a crashes after `quantize()` — `save()` immediately after to avoid losing results
- Use `PortableWordSizes=on` for ARM Cortex-M codegen on macOS ARM64

## Project Structure

```
SOC_model/
├── soc_model.pt2                    # Original PyTorch model
├── soc_model_legacy.onnx            # ONNX export (legacy, opset 14)
├── option1_c/                       # Option 1: Manual C implementation
├── option2_matlab_pytorch_coder/    # Option 2: PyTorch Coder SP
├── option3_matlab_import_pytorch/   # Option 3: importNetworkFromPyTorch (FAILED)
├── option4_matlab_onnx/             # Option 4: ONNX import + codegen
├── option4_compressed/              # Option 4: compression pipeline
│   ├── step1_compress.m             #   Compression (manual_int8 winner)
│   └── TestPipeline_opt4.m          #   Test suite (12 PASS, 13 SKIP)
├── option5_matlab_manual_dlnetwork/ # Option 5: Manual native dlnetwork
├── option5_compressed/              # Option 5: compression pipeline
│   ├── step1_compress.m             #   Compression (proj10_quant winner: 77.5%)
│   ├── step2_simulink_sim.m         #   Simulink export + simulation
│   ├── step3_codegen_compare.m      #   Fixed-point codegen comparison
│   └── TestPipeline_opt5.m          #   Test suite (25/25 PASS)
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
- **Compression**: Deep Learning Toolbox Model Compression + Fixed-Point Designer

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

### Compression (Options 4 & 5)
```matlab
cd option5_compressed
run('step1_compress.m')   % compression — proj10_quant wins at 77.5%
run('step2_simulink_sim.m')  % Simulink export + simulation
run('step3_codegen_compare.m')  % fixed-point codegen
```

## Key Findings

- **MATLAB Coder generates faster C code** than hand-written C on host (~1.7x) due to blocked matrix multiply optimizations
- **Option 2** (PyTorch Coder Support Package) is the fastest and most direct path
- **Option 5** (manual dlnetwork) is the most robust MathWorks approach — no custom layers, full Embedded Coder support
- **Option 3** fails due to non-codegen custom layer from `importNetworkFromPyTorch`
- **Critical config**: Always set `DeepLearningConfig('none')` when using Embedded Coder for deep learning codegen
- **Compression winner** (Opt 5): `neuronPCA(10%) → dlquantizer(int8)` = 77.5% Flash reduction, MAE=9.50e-04
- **Simulink fixed-point codegen** is 69% smaller than direct float32 codegen (262 KB vs 854 KB)

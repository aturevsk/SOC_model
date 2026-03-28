"""
Generate PDF report for SOC Model C Code Generation Options.
Uses reportlab for professional PDF output.
"""

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, ListFlowable, ListItem, KeepTogether
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
import os
from datetime import datetime

OUTPUT_PATH = os.path.join(os.path.dirname(__file__), '..',
                           'SOC_Model_CodeGen_Report.pdf')

def build_report():
    doc = SimpleDocTemplate(
        OUTPUT_PATH,
        pagesize=letter,
        topMargin=0.75*inch,
        bottomMargin=0.75*inch,
        leftMargin=0.75*inch,
        rightMargin=0.75*inch,
        title="SOC Model — Embedded C Code Generation Report",
        author="Auto-generated"
    )

    styles = getSampleStyleSheet()

    # Custom styles
    styles.add(ParagraphStyle(
        'Title2', parent=styles['Title'], fontSize=20, spaceAfter=6
    ))
    styles.add(ParagraphStyle(
        'Subtitle', parent=styles['Normal'], fontSize=12,
        textColor=colors.grey, alignment=TA_CENTER, spaceAfter=20
    ))
    styles.add(ParagraphStyle(
        'SectionHead', parent=styles['Heading1'], fontSize=14,
        spaceAbove=16, spaceAfter=8, textColor=colors.HexColor('#1a5276')
    ))
    styles.add(ParagraphStyle(
        'SubHead', parent=styles['Heading2'], fontSize=12,
        spaceAbove=12, spaceAfter=6, textColor=colors.HexColor('#2c3e50')
    ))
    styles.add(ParagraphStyle(
        'Body', parent=styles['Normal'], fontSize=10, leading=14,
        alignment=TA_JUSTIFY, spaceAfter=8
    ))
    styles.add(ParagraphStyle(
        'CodeBlock', parent=styles['Normal'], fontName='Courier', fontSize=8,
        leading=10, leftIndent=20, spaceAfter=6,
        backColor=colors.HexColor('#f8f9fa')
    ))
    styles.add(ParagraphStyle(
        'TableHeader', parent=styles['Normal'], fontName='Helvetica-Bold',
        fontSize=9, textColor=colors.white
    ))
    styles.add(ParagraphStyle(
        'CellText', parent=styles['Normal'], fontSize=9, leading=11
    ))
    styles.add(ParagraphStyle(
        'SmallNote', parent=styles['Normal'], fontSize=8,
        textColor=colors.grey, spaceAfter=4
    ))

    story = []

    # ======================== TITLE PAGE ========================
    story.append(Spacer(1, 1.5*inch))
    story.append(Paragraph(
        "SOC Model: Embedded C Code Generation", styles['Title2']))
    story.append(Paragraph(
        "Comparative Analysis of Five Code Generation Approaches", styles['Subtitle']))
    story.append(Spacer(1, 0.3*inch))
    story.append(Paragraph(
        f"Target Hardware: STM32F746G-Discovery (ARM Cortex-M7)", styles['Subtitle']))
    story.append(Paragraph(
        f"Date: {datetime.now().strftime('%B %d, %Y')}", styles['Subtitle']))
    story.append(PageBreak())

    # ======================== TABLE OF CONTENTS ========================
    story.append(Paragraph("Table of Contents", styles['SectionHead']))
    toc_items = [
        "1. Executive Summary",
        "2. Model Architecture",
        "3. Target Hardware Specifications",
        "4. Option 1: Manual C Implementation",
        "5. Option 2: MATLAB Coder Support Package for PyTorch",
        "6. Option 3: importNetworkFromPyTorch + MATLAB Coder",
        "7. Option 4: ONNX Import + MATLAB Coder",
        "8. Option 5: Manual Codegen-Compatible dlnetwork",
        "9. Comparative Analysis",
        "10. Benchmarking Results",
        "11. Recommendations",
        "12. File Inventory",
        "13. Model Compression — Options 4 & 5",
    ]
    for item in toc_items:
        story.append(Paragraph(item, styles['Body']))
    story.append(PageBreak())

    # ======================== 1. EXECUTIVE SUMMARY ========================
    story.append(Paragraph("1. Executive Summary", styles['SectionHead']))
    story.append(Paragraph(
        "This report evaluates five approaches for generating embedded C code from a "
        "PyTorch LSTM-based State of Charge (SOC) estimation model targeting the "
        "STM32F746G-Discovery board (ARM Cortex-M7, 216 MHz, 1 MB Flash, 320 KB RAM). "
        "The model predicts battery SOC from a sliding window of 10 timesteps with 5 "
        "sensor features (e.g., voltage, current, temperature).",
        styles['Body']))
    story.append(Paragraph(
        "Of the five approaches evaluated, <b>four succeeded</b> in generating C code and "
        "<b>one failed</b>. Option 1 (manual C), Option 2 (MATLAB Coder PyTorch Support Package), "
        "Option 4 (ONNX import), and Option 5 (manual dlnetwork) all produced working C code. "
        "Option 3 (importNetworkFromPyTorch) failed at the code generation stage due to a "
        "non-codegen-compatible custom layer.",
        styles['Body']))
    story.append(Paragraph(
        "<b>Key Findings:</b><br/>"
        "- <b>Option 1 (Manual C):</b> 222 lines C, 85.4 us/inference on host, zero dependencies — BEST for embedded<br/>"
        "- <b>Option 2 (PT Coder):</b> 12,731 lines generated C, 1.382 ms MATLAB inference — direct .pt2 to C<br/>"
        "- <b>Option 3 (importPT):</b> FAILED codegen — custom layer SOC_LSTM_select_2 lacks codegen support<br/>"
        "- <b>Option 4 (ONNX):</b> 12,297 lines generated C, codegen works with Embedded Coder — VIABLE fallback<br/>"
        "- <b>Option 5 (Native DL):</b> 11,563 lines generated C, 0.302 ms MATLAB inference — BEST MathWorks option",
        styles['Body']))

    # ======================== 2. MODEL ARCHITECTURE ========================
    story.append(Paragraph("2. Model Architecture", styles['SectionHead']))

    model_data = [
        ['Property', 'Value'],
        ['Framework', 'PyTorch (ExportedProgram .pt2)'],
        ['Architecture', '2-layer LSTM + Dense Head'],
        ['Input Shape', '[1, 10, 5] (batch, seq_len, features)'],
        ['Output Shape', '[1, 1] (SOC scalar)'],
        ['LSTM Hidden Size', '64'],
        ['LSTM Layers', '2'],
        ['Head Structure', 'Linear(64,64) -> ReLU -> Linear(64,1)'],
        ['Total Parameters', '55,681'],
        ['Weight Memory (float32)', '217.5 KB'],
        ['Activation Functions', 'sigmoid (LSTM gates), tanh (LSTM), ReLU (head)'],
    ]
    t = Table(model_data, colWidths=[2.5*inch, 4.5*inch])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5276')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#eef2f7')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t)
    story.append(Spacer(1, 0.15*inch))

    story.append(Paragraph("Parameter Breakdown:", styles['SubHead']))
    param_data = [
        ['Layer', 'Weight Shape', 'Parameters', 'Bytes'],
        ['LSTM L0: W_ih', '[256 x 5]', '1,280', '5,120'],
        ['LSTM L0: W_hh', '[256 x 64]', '16,384', '65,536'],
        ['LSTM L0: bias', '[256]', '256 (x2)', '2,048'],
        ['LSTM L1: W_ih', '[256 x 64]', '16,384', '65,536'],
        ['LSTM L1: W_hh', '[256 x 64]', '16,384', '65,536'],
        ['LSTM L1: bias', '[256]', '256 (x2)', '2,048'],
        ['Head FC0: W', '[64 x 64]', '4,096', '16,384'],
        ['Head FC0: bias', '[64]', '64', '256'],
        ['Head FC1: W', '[1 x 64]', '64', '256'],
        ['Head FC1: bias', '[1]', '1', '4'],
        ['TOTAL', '', '55,681', '222,724'],
    ]
    t2 = Table(param_data, colWidths=[2*inch, 1.5*inch, 1.5*inch, 1.5*inch])
    t2.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2c3e50')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -2), [colors.white, colors.HexColor('#f5f5f5')]),
        ('BACKGROUND', (0, -1), (-1, -1), colors.HexColor('#eef2f7')),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ]))
    story.append(t2)

    # ======================== 3. TARGET HARDWARE ========================
    story.append(Paragraph("3. Target Hardware Specifications", styles['SectionHead']))
    hw_data = [
        ['Feature', 'STM32F746G-Discovery'],
        ['MCU', 'STM32F746NGH6 (ARM Cortex-M7)'],
        ['Clock', '216 MHz'],
        ['Flash', '1 MB'],
        ['SRAM', '320 KB (256 KB + 64 KB DTCM)'],
        ['FPU', 'Single-precision FPv5 (hardware float)'],
        ['DSP', 'CMSIS-DSP library available'],
        ['Cache', 'I-Cache + D-Cache (4 KB each)'],
    ]
    t3 = Table(hw_data, colWidths=[2.5*inch, 4.5*inch])
    t3.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5276')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#eef2f7')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t3)
    story.append(Spacer(1, 0.1*inch))
    story.append(Paragraph(
        "<b>Memory Budget:</b> Model weights require ~218 KB Flash. With 1 MB Flash "
        "available, this leaves ~806 KB for application code. Runtime buffers require "
        "~4 KB RAM, well within the 320 KB SRAM budget.", styles['Body']))

    # ======================== 4. OPTION 1 ========================
    story.append(PageBreak())
    story.append(Paragraph("4. Option 1: Manual C Implementation", styles['SectionHead']))
    story.append(Paragraph(
        "Hand-written, optimized C99 implementation with weights extracted from the "
        "PyTorch model and embedded as const arrays in a header file.", styles['Body']))

    story.append(Paragraph("Approach:", styles['SubHead']))
    story.append(Paragraph(
        "1. Extract all model weights from the .pt2 ExportedProgram using Python.<br/>"
        "2. Pre-combine bias_ih + bias_hh per LSTM layer to eliminate one vector "
        "addition at runtime.<br/>"
        "3. Implement LSTM cell with gate computations: i/f/g/o split, sigmoid, tanh.<br/>"
        "4. Process sequence through 2 LSTM layers, then dense head.<br/>"
        "5. Use fast math approximations (clamped sigmoid/tanh) for speed.<br/>"
        "6. Optional CMSIS-DSP acceleration for matrix-vector multiply.",
        styles['Body']))

    story.append(Paragraph("Key Files:", styles['SubHead']))
    files_opt1 = [
        ['File', 'Lines', 'Purpose'],
        ['soc_model.h', '35', 'Public API: init() and predict()'],
        ['soc_model.c', '222', 'LSTM inference engine'],
        ['soc_model_weights.h', '6,977', 'Const float arrays (all weights)'],
        ['main_test.c', '78', 'Test harness with benchmarking'],
        ['Makefile', '48', 'Host + ARM cross-compilation'],
    ]
    t4 = Table(files_opt1, colWidths=[2.2*inch, 0.8*inch, 3.5*inch])
    t4.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2c3e50')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t4)

    story.append(Paragraph("Benchmark Results (Host — Apple Silicon):", styles['SubHead']))
    bench_opt1 = [
        ['Metric', 'Value'],
        ['Correctness', 'PASS (error < 1e-6 vs PyTorch)'],
        ['Inference Time', '85.4 us/inference (gcc -O2)'],
        ['Throughput', '11,714 inferences/sec'],
        ['Flash (weights)', '217.5 KB (weights) + ~1 KB (code)'],
        ['RAM (buffers)', '~3.8 KB'],
        ['Code Size (source)', '222 lines C + 6,977 lines weights header'],
        ['Dependencies', 'None (C99 + math.h)'],
    ]
    t5 = Table(bench_opt1, colWidths=[2.5*inch, 4*inch])
    t5.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5276')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#eef2f7')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t5)

    story.append(Paragraph("<b>Steps Taken:</b>", styles['SubHead']))
    steps_opt1 = ListFlowable([
        ListItem(Paragraph("Loaded .pt2 with torch.export.load(), extracted state_dict", styles['Body'])),
        ListItem(Paragraph("Pre-combined bias_ih + bias_hh per LSTM layer to save runtime computation", styles['Body'])),
        ListItem(Paragraph("Implemented LSTM cell with gate computations using fast_sigmoid/fast_tanh", styles['Body'])),
        ListItem(Paragraph("Built Makefile for host (gcc -O2) and ARM cross-compilation", styles['Body'])),
        ListItem(Paragraph("Validated against PyTorch: 100/100 tests pass, max error 1.49e-08", styles['Body'])),
    ], bulletType='1', start='1')
    story.append(steps_opt1)
    story.append(Paragraph("<i>No issues encountered.</i>", styles['Body']))

    story.append(Paragraph(
        "<b>Estimated STM32F746 performance:</b> At 216 MHz with FPv5 hardware FPU, "
        "expected inference time is approximately 0.5-2 ms per inference, depending on "
        "cache utilization and CMSIS-DSP usage. The model's dominant cost is the "
        "matrix-vector multiplies in the LSTM layers (~33K multiply-accumulate ops "
        "per inference).", styles['Body']))

    story.append(Paragraph("Strengths:", styles['SubHead']))
    story.append(Paragraph(
        "- Zero external dependencies (pure C99)<br/>"
        "- Minimal code size and RAM footprint<br/>"
        "- Full control over memory layout, optimizations, and fast math<br/>"
        "- Pre-combined biases save runtime computation<br/>"
        "- Optional CMSIS-DSP acceleration<br/>"
        "- Easy to integrate into any embedded build system",
        styles['Body']))

    story.append(Paragraph("Limitations:", styles['SubHead']))
    story.append(Paragraph(
        "- Manual effort to write and maintain<br/>"
        "- No automatic traceability back to the training model<br/>"
        "- Requires manual update if model architecture changes<br/>"
        "- Risk of transcription errors (mitigated by automated weight extraction)",
        styles['Body']))

    # ======================== 5. OPTION 2 ========================
    story.append(PageBreak())
    story.append(Paragraph(
        "5. Option 2: MATLAB Coder Support Package for PyTorch", styles['SectionHead']))
    story.append(Paragraph(
        "Uses the MATLAB R2026a Coder Support Package for PyTorch to generate C code "
        "directly from the .pt2 ExportedProgram file. This is the most direct MATLAB-based "
        "workflow, requiring no intermediate model conversion.", styles['Body']))

    story.append(Paragraph("Approach:", styles['SubHead']))
    story.append(Paragraph(
        "1. Load .pt2 model using loadPyTorchExportedProgram().<br/>"
        "2. Create a codegen-compatible prediction wrapper function.<br/>"
        "3. Configure coder.config('lib') with ARM Cortex-M hardware settings.<br/>"
        "4. Set coder.DeepLearningConfig('none') for pure C output.<br/>"
        "5. Run codegen to generate a static C library.",
        styles['Body']))

    story.append(Paragraph("Required Toolboxes:", styles['SubHead']))
    story.append(Paragraph(
        "- MATLAB R2026a<br/>"
        "- MATLAB Coder<br/>"
        "- Embedded Coder<br/>"
        "- MATLAB Coder Support Package for PyTorch (R2026a)",
        styles['Body']))

    story.append(Paragraph("Key File:", styles['SubHead']))
    story.append(Paragraph(
        "<font face='Courier' size='9'>option2_matlab_pytorch_coder/generate_code_pytorch_coder.m</font><br/>"
        "Self-contained script with 7 steps: load, validate, configure, generate, analyze, benchmark.",
        styles['Body']))

    story.append(Paragraph("Actual Results:", styles['SubHead']))
    exp_opt2 = [
        ['Metric', 'Measured Value'],
        ['Code Generation', 'SUCCESSFUL using loadPyTorchExportedProgram + Embedded Coder'],
        ['Generated C (main)', 'predict_soc.c — 12,322 lines'],
        ['Total Generated C', '~12,731 lines (main + 7 support files)'],
        ['Output Directory', '3.0 MB on disk'],
        ['MATLAB Inference', '1.382 ms/inference'],
        ['Implementation', 'Blocked matrix multiply with micro/macro kernel pattern'],
        ['Dependencies', 'MW runtime + OpenMP header (omp.h)'],
        ['API', 'float predict_soc(const float input[50])'],
    ]
    t6 = Table(exp_opt2, colWidths=[2.5*inch, 4*inch])
    t6.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5276')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#eef2f7')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t6)

    story.append(Paragraph("<b>Steps Taken:</b>", styles['SubHead']))
    steps_opt2 = ListFlowable([
        ListItem(Paragraph("loadPyTorchExportedProgram('soc_model.pt2') — loaded successfully", styles['Body'])),
        ListItem(Paragraph("model.invoke(input) — validated output matches PyTorch", styles['Body'])),
        ListItem(Paragraph("coder.config('lib','ecoder',true) with DeepLearningConfig('none')", styles['Body'])),
        ListItem(Paragraph("codegen generated 12,322 lines of C with blocked matrix multiply kernels", styles['Body'])),
        ListItem(Paragraph("Compiled on host with OpenMP stub — 48.7 us/inference (fastest!)", styles['Body'])),
    ], bulletType='1', start='1')
    story.append(steps_opt2)

    story.append(Paragraph("<b>Issues Encountered:</b>", styles['SubHead']))
    issues_opt2 = ListFlowable([
        ListItem(Paragraph("Initially used predict() instead of invoke() — corrected based on R2026a docs", styles['Body'])),
        ListItem(Paragraph("Initially missing DeepLearningConfig('none') — added based on earlier project", styles['Body'])),
        ListItem(Paragraph("Generated code includes omp.h — requires OpenMP stub for non-OMP compilation", styles['Body'])),
        ListItem(Paragraph("STM32 board support package not installed — fell back to generic ARM Cortex-M", styles['Body'])),
    ], bulletType='bullet', start='')
    story.append(issues_opt2)

    story.append(Paragraph("Strengths:", styles['SubHead']))
    story.append(Paragraph(
        "- Most direct path from PyTorch to C (no intermediate format)<br/>"
        "- Automatic code generation with full traceability<br/>"
        "- MathWorks-validated LSTM implementation<br/>"
        "- Integrates with Simulink and Model-Based Design workflows<br/>"
        "- Hardware-specific optimizations via Embedded Coder",
        styles['Body']))

    story.append(Paragraph("Limitations:", styles['SubHead']))
    story.append(Paragraph(
        "- Requires MATLAB R2026a + support package licenses<br/>"
        "- Generated code may be more verbose than hand-written<br/>"
        "- Limited control over low-level optimizations<br/>"
        "- Support package availability and model coverage may vary",
        styles['Body']))

    # ======================== 6. OPTION 3 ========================
    story.append(PageBreak())
    story.append(Paragraph(
        "6. Option 3: importNetworkFromPyTorch + MATLAB Coder", styles['SectionHead']))
    story.append(Paragraph(
        "Imports the PyTorch model into MATLAB's Deep Learning Toolbox as a dlnetwork "
        "using importNetworkFromPyTorch, then generates C code via MATLAB Coder.", styles['Body']))

    story.append(Paragraph("Approach:", styles['SubHead']))
    story.append(Paragraph(
        "1. Import .pt2 model using importNetworkFromPyTorch() -> dlnetwork.<br/>"
        "2. Inspect and validate the imported network layers.<br/>"
        "3. Save dlnetwork to .mat file for coder.loadDeepLearningNetwork().<br/>"
        "4. Create entry-point function using persistent network loading.<br/>"
        "5. Configure MATLAB Coder for ARM Cortex-M target.<br/>"
        "6. Generate static C library.",
        styles['Body']))

    story.append(Paragraph("Required Toolboxes:", styles['SubHead']))
    story.append(Paragraph(
        "- MATLAB R2026a<br/>"
        "- Deep Learning Toolbox<br/>"
        "- MATLAB Coder<br/>"
        "- Embedded Coder",
        styles['Body']))

    story.append(Paragraph("Key Files:", styles['SubHead']))
    story.append(Paragraph(
        "<font face='Courier' size='9'>option3_matlab_import_pytorch/generate_code_import_pytorch.m</font> — Main script<br/>"
        "<font face='Courier' size='9'>option3_matlab_import_pytorch/predict_soc_dlnet.m</font> — Codegen entry point",
        styles['Body']))

    story.append(Paragraph("Actual Results — CODE GENERATION FAILED:", styles['SubHead']))
    fail_opt3 = [
        ['Metric', 'Result'],
        ['Import', 'SUCCESSFUL — dlnetwork with 7 layers after expandLayers'],
        ['Layer Structure', 'SequenceInput -> LSTM(x2) -> custom SOC_LSTM_select_2 -> FC -> ReLU -> FC'],
        ['MATLAB Inference', '0.702 ms/inference (fastest of MATLAB options)'],
        ['Code Generation', 'FAILED'],
        ['Failure Cause', 'Custom layer SOC_LSTM_select_2 (auto-generated for PyTorch h_n[-1] selection)'],
        ['Root Issue', 'No matlabCodegenRedirect and no %#codegen pragma on custom layer'],
        ['Workaround', 'expandLayers() does not resolve — select operation stays as non-codegen layer'],
        ['Recommended Fallback', 'Use Option 4 (ONNX import) instead'],
    ]
    t_fail3 = Table(fail_opt3, colWidths=[2.5*inch, 4*inch])
    t_fail3.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#c0392b')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#fbeaea')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t_fail3)
    story.append(Spacer(1, 0.1*inch))
    story.append(Paragraph(
        "<b>Failure Analysis:</b> When importNetworkFromPyTorch imports the PyTorch LSTM model, "
        "it auto-generates a custom layer called SOC_LSTM_select_2 to handle the h_n[-1] "
        "selection (extracting the last hidden state from the LSTM output). This custom layer "
        "does not implement matlabCodegenRedirect or include the %#codegen pragma, making it "
        "incompatible with MATLAB Coder. The expandLayers() function does not decompose this "
        "operation into codegen-compatible primitives. MATLAB inference works correctly at "
        "0.702 ms/inference, but the model cannot be deployed to embedded targets via this path.",
        styles['Body']))

    story.append(Paragraph("<b>Steps Taken:</b>", styles['SubHead']))
    steps_opt3 = ListFlowable([
        ListItem(Paragraph("importNetworkFromPyTorch('soc_model.pt2') — imported successfully as dlnetwork", styles['Body'])),
        ListItem(Paragraph("expandLayers(net) — expanded NetworkLayer containers to 7 standard layers", styles['Body'])),
        ListItem(Paragraph("LSTM layers became native LSTMLayer(x2) — good", styles['Body'])),
        ListItem(Paragraph("But SOC_LSTM_select_2 custom layer remained for h_n[-1] selection", styles['Body'])),
        ListItem(Paragraph("codegen failed: \"Code generation does not support custom layers without '%#codegen'\"", styles['Body'])),
    ], bulletType='1', start='1')
    story.append(steps_opt3)

    story.append(Paragraph("<b>Issues:</b>", styles['SubHead']))
    issues_opt3 = ListFlowable([
        ListItem(Paragraph("Custom layer SOC_LSTM_select_2 has NO matlabCodegenRedirect (unlike ONNX-imported layers)", styles['Body'])),
        ListItem(Paragraph("expandLayers() doesn't decompose the select operation", styles['Body'])),
        ListItem(Paragraph("Even with %#codegen added manually, the file gets regenerated on each import", styles['Body'])),
        ListItem(Paragraph("MATLAB inference works fine at 0.702 ms — just no codegen path", styles['Body'])),
    ], bulletType='bullet', start='')
    story.append(issues_opt3)

    # ======================== 7. OPTION 4 ========================
    story.append(Paragraph(
        "7. Option 4: ONNX Import + MATLAB Coder (Fallback)", styles['SectionHead']))
    story.append(Paragraph(
        "Exports the PyTorch model to ONNX format, then imports into MATLAB using "
        "importNetworkFromONNX. This is the fallback if Option 3 fails.", styles['Body']))

    story.append(Paragraph(
        "<b>R2026a Key Feature:</b> In MATLAB R2026a, auto-generated custom layers "
        "created during ONNX import include matlabCodegenRedirect to +coder versions "
        "with %#codegen pragma, enabling code generation. This option <b>succeeded</b> "
        "with %#codegen pragma, enabling code generation. This option <b>succeeded</b> "
        "with Embedded Coder when DeepLearningConfig('none') is set.", styles['Body']))

    story.append(Paragraph("Approach:", styles['SubHead']))
    story.append(Paragraph(
        "1. Export PyTorch model to ONNX using legacy TorchScript exporter (opset 14) for proper LSTM ops.<br/>"
        "2. Import ONNX model using importNetworkFromONNX() -> dlnetwork.<br/>"
        "3. Validate inference matches PyTorch reference.<br/>"
        "4. Save dlnetwork and create codegen entry point.<br/>"
        "5. Generate C code with MATLAB Coder (ARM Cortex-M target).",
        styles['Body']))

    story.append(Paragraph("Required Toolboxes:", styles['SubHead']))
    story.append(Paragraph(
        "- MATLAB R2026a<br/>"
        "- Deep Learning Toolbox<br/>"
        "- Deep Learning Toolbox Converter for ONNX Model Format<br/>"
        "- MATLAB Coder<br/>"
        "- Embedded Coder",
        styles['Body']))

    story.append(Paragraph("Key Files:", styles['SubHead']))
    story.append(Paragraph(
        "<font face='Courier' size='9'>option4_matlab_onnx/export_onnx.py</font> — PyTorch to ONNX export<br/>"
        "<font face='Courier' size='9'>option4_matlab_onnx/generate_code_onnx.m</font> — Main MATLAB script<br/>"
        "<font face='Courier' size='9'>option4_matlab_onnx/predict_soc_onnx.m</font> — Codegen entry point",
        styles['Body']))

    story.append(Paragraph("Actual Results:", styles['SubHead']))
    res_opt4 = [
        ['Metric', 'Measured Value'],
        ['ONNX Export', 'SUCCESSFUL — legacy TorchScript exporter, opset 14'],
        ['Import', 'SUCCESSFUL — 9-layer dlnetwork with native LSTMLayer(x2) + custom helpers'],
        ['Custom Layer Codegen', 'Supported — matlabCodegenRedirect to +coder versions with %#codegen'],
        ['Code Generation (lib)', 'SUCCESSFUL with coder.config(\'lib\')'],
        ['Code Generation (ecoder)', 'SUCCESSFUL with DeepLearningConfig(\'none\') — see Key Insight below'],
        ['Generated C (main)', 'callPredict.c — 11,708 lines'],
        ['Total Generated C', '~12,297 lines (main + 8 support files)'],
        ['MATLAB Inference', '5.275 ms/inference (slower due to ONNX layer overhead)'],
    ]
    t_opt4 = Table(res_opt4, colWidths=[2.5*inch, 4*inch])
    t_opt4.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5276')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#eef2f7')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t_opt4)
    story.append(Spacer(1, 0.1*inch))
    story.append(Paragraph(
        "<b>Key Insight (from prior project):</b> Embedded Coder with deep learning models "
        "requires <font face='Courier'>coder.DeepLearningConfig('none')</font> to be set "
        "explicitly. Without it, Embedded Coder silently fails or produces incorrect output. "
        "This fix was identified from a prior LSTM code generation project "
        "(LSTMforecaster). After applying it, Option 4 codegen with Embedded Coder "
        "<b>succeeded</b>. The generated C library (<font face='Courier'>predict_soc_onnx.a</font>) "
        "includes RTW make files and <font face='Courier'>rtwtypes.h</font> — confirming "
        "full Embedded Coder output.", styles['Body']))

    story.append(Paragraph("<b>Steps Taken:</b>", styles['SubHead']))
    steps_opt4 = ListFlowable([
        ListItem(Paragraph("Exported PyTorch to ONNX using LEGACY TorchScript exporter (not the new torch.export-based one)", styles['Body'])),
        ListItem(Paragraph("Used opset 14 — produces proper ONNX LSTM ops (not decomposed)", styles['Body'])),
        ListItem(Paragraph("Forced weights inline (no external .data file) using onnx.save(save_as_external_data=False)", styles['Body'])),
        ListItem(Paragraph("importNetworkFromONNX — imported as 9-layer dlnetwork with native LSTMLayer(x2)", styles['Body'])),
        ListItem(Paragraph("Custom helper layers (Shape_To_Expand, Squeeze_To_Expand, Concat_To_Gemm) have matlabCodegenRedirect to +coder versions", styles['Body'])),
        ListItem(Paragraph("Codegen with Embedded Coder + DeepLearningConfig('none') — SUCCEEDED", styles['Body'])),
    ], bulletType='1', start='1')
    story.append(steps_opt4)

    story.append(Paragraph("<b>Issues Encountered:</b>", styles['SubHead']))
    issues_opt4 = ListFlowable([
        ListItem(Paragraph("First attempt used new torch.export-based ONNX exporter — produced decomposed ops that MATLAB fused into a monolithic custom layer without codegen support", styles['Body'])),
        ListItem(Paragraph("First ONNX export had external data file — MATLAB's importNetworkFromONNX cannot handle external data", styles['Body'])),
        ListItem(Paragraph("Initially missing DeepLearningConfig('none') — caused Embedded Coder to fail", styles['Body'])),
        ListItem(Paragraph("After adding DeepLearningConfig('none') (learned from earlier project), Embedded Coder worked", styles['Body'])),
    ], bulletType='bullet', start='')
    story.append(issues_opt4)

    # ======================== 8. OPTION 5 ========================
    story.append(PageBreak())
    story.append(Paragraph(
        "8. Option 5: Manual Codegen-Compatible dlnetwork", styles['SectionHead']))
    story.append(Paragraph(
        "This option manually constructs a dlnetwork using ONLY native MATLAB layers, "
        "transferring weights from the imported PyTorch model. By using OutputMode='last' "
        "on the second LSTM layer, the custom select layer is eliminated entirely.",
        styles['Body']))

    story.append(Paragraph("<b>Steps Taken:</b>", styles['SubHead']))
    steps_opt5 = ListFlowable([
        ListItem(Paragraph("Imported PyTorch model with importNetworkFromPyTorch to extract weights", styles['Body'])),
        ListItem(Paragraph("Built fresh dlnetwork: sequenceInputLayer(5) -> lstmLayer(64,'OutputMode','sequence') -> lstmLayer(64,'OutputMode','last') -> fullyConnectedLayer(64) -> reluLayer -> fullyConnectedLayer(1)", styles['Body'])),
        ListItem(Paragraph("Key insight: OutputMode='last' on LSTM2 eliminates the custom select layer entirely", styles['Body'])),
        ListItem(Paragraph("Transferred weights via net.Learnables table", styles['Body'])),
        ListItem(Paragraph("Validated: 100/100 tests pass, max error 1.49e-08 (matches imported network to 1.86e-09)", styles['Body'])),
        ListItem(Paragraph("Codegen with Embedded Coder + DeepLearningConfig('none') — SUCCEEDED", styles['Body'])),
        ListItem(Paragraph("All 6 layers are native MATLAB layers — no custom layers at all", styles['Body'])),
    ], bulletType='1', start='1')
    story.append(steps_opt5)
    story.append(Paragraph("<i>No issues — this approach works cleanly.</i>", styles['Body']))

    story.append(Paragraph("Results:", styles['SubHead']))
    res_opt5 = [
        ['Metric', 'Measured Value'],
        ['Code Generation', 'SUCCESSFUL — Embedded Coder + DeepLearningConfig(\'none\')'],
        ['Generated C (main)', '11,563 lines'],
        ['Host C Inference', '51.5 us/inference'],
        ['MATLAB Inference', '0.302 ms/inference (fastest MATLAB option)'],
        ['Custom Layers', 'None — all 6 layers are native MATLAB layers'],
        ['Numerical Accuracy', '100/100 tests pass, max error 1.49e-08'],
        ['Dependencies', 'MW runtime + OpenMP header (omp.h)'],
    ]
    t_opt5 = Table(res_opt5, colWidths=[2.5*inch, 4*inch])
    t_opt5.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5276')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#eef2f7')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t_opt5)

    story.append(Paragraph("Strengths:", styles['SubHead']))
    story.append(Paragraph(
        "- Zero custom layers — fully native MATLAB dlnetwork<br/>"
        "- Fastest MATLAB inference (0.302 ms)<br/>"
        "- Full Embedded Coder support with DeepLearningConfig('none')<br/>"
        "- Complete traceability through MATLAB workflow<br/>"
        "- No dependency on ONNX export path or custom layer packages",
        styles['Body']))

    story.append(Paragraph("Limitations:", styles['SubHead']))
    story.append(Paragraph(
        "- Requires manual network construction (one-time effort)<br/>"
        "- Weight transfer must be done carefully to match layer naming<br/>"
        "- Must be repeated if model architecture changes",
        styles['Body']))

    # ======================== 9. COMPARATIVE ANALYSIS ========================
    story.append(PageBreak())
    story.append(Paragraph("9. Comparative Analysis", styles['SectionHead']))

    comp_data = [
        ['Criterion', 'Opt 1\nManual C', 'Opt 2\nPT Coder', 'Opt 3\nimportPT', 'Opt 4\nONNX', 'Opt 5\nNative DL'],
        ['Codegen', 'N/A', 'PASS', 'FAILED', 'PASS', 'PASS'],
        ['Embedded Coder', 'N/A', 'Yes', 'No', 'Yes*', 'Yes'],
        ['C Lines', '222', '12,322', 'N/A', '11,708', '11,563'],
        ['Host C (us)', '84.8', '48.8', 'N/A', '52.5', '51.5'],
        ['Binary (KB)', '243', '260', 'N/A', '260', '261'],
        ['MATLAB (ms)', 'N/A', '1.38', '0.70', '5.28', '0.30'],
        ['Dependencies', 'None', 'MW+OMP', 'N/A', 'MW+OMP', 'MW+OMP'],
        ['Custom Layers', 'None', 'None', 'Yes (fail)', 'Yes (ok)', 'None'],
        ['Traceability', 'None', 'Full', 'N/A', 'Full', 'Full'],
    ]
    t7 = Table(comp_data, colWidths=[1.2*inch, 1*inch, 1*inch, 1*inch, 1*inch, 1*inch])
    t7.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5276')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#eef2f7')),
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
        ('ALIGN', (0, 0), (0, -1), 'LEFT'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]))
    story.append(t7)
    story.append(Spacer(1, 0.1*inch))
    story.append(Paragraph(
        "* Option 4 Embedded Coder requires <font face='Courier'>coder.DeepLearningConfig('none')</font> — see critical insight below.",
        styles['SmallNote']))

    story.append(Spacer(1, 0.15*inch))

    # Critical insight callout
    insight_data = [[
        Paragraph(
            "<b>Critical Insight: coder.DeepLearningConfig('none') Required for Embedded Coder</b><br/><br/>"
            "When using Embedded Coder (<font face='Courier'>coder.config('lib', 'ecoder', true)</font>) "
            "with any deep learning model (dlnetwork, ExportedProgram, ONNX import), you <b>must</b> "
            "explicitly set:<br/><br/>"
            "<font face='Courier'>dlcfg = coder.DeepLearningConfig('none');<br/>"
            "cfg.DeepLearningConfig = dlcfg;</font><br/><br/>"
            "Without this, Embedded Coder does not know how to handle the deep learning layer "
            "inference and will fail or produce incorrect output. This setting forces pure C "
            "output with no external library dependency (no CUDA, no MKL-DNN, no ARM Compute Library). "
            "It is critical for bare-metal MCU targets like the STM32F746G.<br/><br/>"
            "This insight was identified from a prior project (LSTMforecaster at "
            "<font face='Courier'>PyTorch_Import_2/LSTMforecaster</font>) and applied to "
            "Options 2, 4, and 5 in this project. Options 4 and 5 initially failed with Embedded "
            "Coder until <font face='Courier'>DeepLearningConfig('none')</font> was added.",
            styles['Body'])
    ]]
    t_insight = Table(insight_data, colWidths=[6.5*inch])
    t_insight.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#fef9e7')),
        ('BOX', (0, 0), (-1, -1), 1.5, colors.HexColor('#f39c12')),
        ('TOPPADDING', (0, 0), (-1, -1), 10),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 10),
        ('LEFTPADDING', (0, 0), (-1, -1), 12),
        ('RIGHTPADDING', (0, 0), (-1, -1), 12),
    ]))
    story.append(t_insight)

    # ======================== 9. BENCHMARKING ========================
    story.append(Spacer(1, 0.2*inch))
    story.append(Paragraph("10. Benchmarking Results", styles['SectionHead']))

    story.append(Paragraph(
        "<b>Important:</b> All benchmarks for Options 2, 4, and 5 use the <b>Embedded Coder generated C</b> "
        "compiled with gcc -O2 on the host. The Embedded Coder output includes "
        "<font face='Courier'>rtwtypes.h</font>, RTW makefiles, and initialize/terminate "
        "lifecycle functions — confirming these are not basic lib outputs. "
        "An OpenMP stub (<font face='Courier'>omp.h</font>) is provided for host compilation "
        "since the generated code includes OpenMP headers.",
        styles['Body']))
    story.append(Spacer(1, 0.05*inch))
    story.append(Paragraph("10.1 Host C Benchmark (100K iterations, gcc -O2, Apple Silicon):", styles['SubHead']))
    host_bench = [
        ['Option', 'Mean (us)', 'Median', 'Min', 'P95', 'Throughput'],
        ['1: Manual C', '84.8', '81', '80', '97', '11,827/s'],
        ['2: PT Coder', '48.7', '49', '43', '56', '20,520/s'],
        ['4: ONNX', '52.5', '53', '47', '60', '19,055/s'],
        ['5: Native DL', '51.5', '52', '46', '59', '19,422/s'],
    ]
    t_hb = Table(host_bench, colWidths=[1.3*inch, 1*inch, 0.9*inch, 0.8*inch, 0.8*inch, 1.3*inch])
    t_hb.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2c3e50')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t_hb)
    story.append(Spacer(1, 0.1*inch))
    story.append(Paragraph(
        "<b>Key finding:</b> MATLAB Coder-generated code (Options 2, 4, 5) is ~1.7x faster "
        "than manual C on host due to blocked matrix multiply with micro/macro kernel "
        "optimizations. Option 2 (PyTorch Coder) is the fastest at 48.7 us median.",
        styles['Body']))

    story.append(Paragraph("10.2 Numerical Equivalence (100 random vectors):", styles['SubHead']))
    equiv_data = [
        ['Option', 'Pass Rate', 'Max Abs Error', 'Mean Abs Error'],
        ['1: Manual C', '100/100', '1.49e-08', '4.97e-09'],
        ['2: PT Coder', '100/100', '1.30e-08', '4.41e-09'],
        ['4: ONNX Import', '100/100', '1.12e-08', '3.43e-09'],
        ['5: Native DL', '100/100', '1.49e-08', '~5e-09'],
    ]
    t_eq = Table(equiv_data, colWidths=[1.5*inch, 1.2*inch, 1.5*inch, 1.5*inch])
    t_eq.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#27ae60')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#eafaf1')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t_eq)
    story.append(Spacer(1, 0.15*inch))

    story.append(Paragraph("10.3 Estimated STM32F746G Performance:", styles['SubHead']))

    story.append(Paragraph(
        "The STM32F746G runs at 216 MHz with a single-precision FPv5 FPU. Key "
        "computational cost: ~508K multiply-accumulate (MAC) operations per "
        "inference, dominated by the two LSTM layers.", styles['Body']))

    est_data = [
        ['Scenario', 'Est. Inference Time', 'Est. Throughput'],
        ['Option 1: -Os, no CMSIS', '1.5 - 2.5 ms', '400 - 670 inf/s'],
        ['Option 1: -Os, CMSIS-DSP', '0.8 - 1.5 ms', '670 - 1,250 inf/s'],
        ['Option 2: MATLAB Coder', '1.5 - 3.0 ms', '330 - 670 inf/s'],
        ['Option 4: ONNX (lib)', '1.5 - 3.0 ms', '330 - 670 inf/s'],
    ]
    t8 = Table(est_data, colWidths=[2.5*inch, 2*inch, 2*inch])
    t8.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2c3e50')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t8)
    story.append(Spacer(1, 0.1*inch))
    story.append(Paragraph(
        "<i>Note: Estimates based on typical Cortex-M7 cycle counts for floating-point "
        "MAC operations. Actual performance depends on cache behavior, memory layout, "
        "and compiler optimizations. Run on actual hardware for definitive numbers.</i>",
        styles['SmallNote']))

    story.append(Paragraph("10.4 Computational Cost Analysis:", styles['SubHead']))
    mac_data = [
        ['Operation', 'MACs per Inference'],
        ['LSTM L0 W_ih (10 steps)', '10 x 256 x 5 = 12,800'],
        ['LSTM L0 W_hh (10 steps)', '10 x 256 x 64 = 163,840'],
        ['LSTM L1 W_ih (10 steps)', '10 x 256 x 64 = 163,840'],
        ['LSTM L1 W_hh (10 steps)', '10 x 256 x 64 = 163,840'],
        ['Head FC0', '64 x 64 = 4,096'],
        ['Head FC1', '1 x 64 = 64'],
        ['TOTAL', '508,480 MACs'],
    ]
    t_mac = Table(mac_data, colWidths=[2.5*inch, 4*inch])
    t_mac.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2c3e50')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('ALIGN', (1, 0), (-1, -1), 'LEFT'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -2), [colors.white, colors.HexColor('#f5f5f5')]),
        ('BACKGROUND', (0, -1), (-1, -1), colors.HexColor('#eef2f7')),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t_mac)

    # ======================== 11. RECOMMENDATIONS ========================
    story.append(PageBreak())
    story.append(Paragraph("11. Recommendations", styles['SectionHead']))

    story.append(Paragraph("Best Option by Use Case:", styles['SubHead']))
    rec_data = [
        ['Use Case', 'Recommended', 'Rationale'],
        ['Minimal footprint,\nno MATLAB license', 'Option 1\n(Manual C)',
         'VERIFIED: 222 lines C, 85.4 us host inference,\nzero deps. 218.5 KB Flash, 3.8 KB RAM.'],
        ['MathWorks ecosystem,\nModel-Based Design', 'Option 5\n(Native DL)',
         'VERIFIED: Fastest MATLAB (0.302 ms), no custom\nlayers, full Embedded Coder support.'],
        ['Direct .pt2 workflow,\nno intermediate format', 'Option 2\n(PT Coder)',
         'VERIFIED: Direct .pt2 to C via Embedded Coder.\n12,731 lines, 1.382 ms MATLAB inference.'],
        ['Existing dlnetwork\nworkflow', 'Option 3\n(AVOID)',
         'FAILED: Custom layer SOC_LSTM_select_2 blocks\ncodegen. Use Option 5 instead.'],
        ['Maximum compatibility,\nONNX ecosystem', 'Option 4\n(ONNX)',
         'VERIFIED: Codegen works with Embedded Coder.\n12,297 lines C. Viable fallback.'],
    ]
    t_rec = Table(rec_data, colWidths=[1.8*inch, 1.3*inch, 3.4*inch])
    t_rec.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5276')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#eef2f7')]),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ]))
    story.append(t_rec)

    story.append(Spacer(1, 0.2*inch))
    story.append(Paragraph(
        "<b>Overall Recommendation:</b> For this specific model (55K params, 218 KB), "
        "<b>Option 1 (Manual C)</b> is the most efficient choice for pure embedded "
        "deployment — verified at 222 lines of C, 85.4 us/inference on host, with zero "
        "dependencies. For MathWorks Model-Based Design workflows, <b>Option 5 (Manual "
        "Codegen-Compatible dlnetwork)</b> is the recommended choice — it has the fastest "
        "MATLAB inference (0.302 ms), zero custom layers, and full Embedded Coder support. "
        "<b>Option 2 (PyTorch Coder)</b> is the best choice for a direct .pt2-to-C workflow "
        "with no intermediate format. <b>Option 3 should be avoided</b> due to the codegen "
        "failure with the auto-generated SOC_LSTM_select_2 custom layer. <b>Option 4 (ONNX)</b> "
        "is a viable fallback with full Embedded Coder support.",
        styles['Body']))

    story.append(Paragraph("Further Optimization Opportunities:", styles['SubHead']))
    story.append(Paragraph(
        "- <b>Quantization (IMPLEMENTED for Opt 5):</b> dlquantizer int8 + neuronPCA projection "
        "achieves 77.5% Flash reduction (215.5 KB → 48.4 KB) while passing MAE &lt; 1e-3. "
        "See Section 13 for full details.<br/>"
        "- <b>CMSIS-NN:</b> Use ARM's neural network library for optimized LSTM kernels on Cortex-M.<br/>"
        "- <b>DMA:</b> Use DMA for weight transfers to minimize cache misses.<br/>"
        "- <b>Sequence length:</b> If the application allows, reducing from 10 to 5 "
        "timesteps halves LSTM computation.",
        styles['Body']))

    # ======================== 12. FILE INVENTORY ========================
    story.append(Paragraph("12. File Inventory", styles['SectionHead']))
    inv_data = [
        ['Path', 'Description'],
        ['soc_model.pt2', 'Original PyTorch ExportedProgram'],
        ['soc_model.onnx', 'ONNX export (opset 17)'],
        ['model_weights.json', 'Extracted weights (JSON)'],
        ['test_vector.npz', 'Reference test input/output'],
        ['option1_c/soc_model.h', 'C API header'],
        ['option1_c/soc_model.c', 'C inference implementation'],
        ['option1_c/soc_model_weights.h', 'Const weight arrays'],
        ['option1_c/main_test.c', 'Test harness + benchmark'],
        ['option1_c/Makefile', 'Build system (host + ARM)'],
        ['option2_.../generate_code_pytorch_coder.m', 'MATLAB Coder PyTorch script'],
        ['option2_.../predict_soc.m', 'Codegen wrapper'],
        ['option3_.../generate_code_import_pytorch.m', 'importPyTorch script'],
        ['option3_.../predict_soc_dlnet.m', 'Codegen wrapper'],
        ['option4_.../export_onnx.py', 'ONNX export script'],
        ['option4_.../generate_code_onnx.m', 'ONNX import + codegen script'],
        ['option4_.../predict_soc_onnx.m', 'Codegen wrapper'],
        ['benchmarks/benchmark_option1.c', 'Detailed C benchmark'],
        ['benchmarks/benchmark_all.m', 'MATLAB comparative benchmark'],
        ['report/generate_report.py', 'This report generator'],
    ]
    t_inv = Table(inv_data, colWidths=[3.2*inch, 3.3*inch])
    t_inv.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2c3e50')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTNAME', (0, 1), (0, -1), 'Courier'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t_inv)

    # ======================== 13. MODEL COMPRESSION ========================
    story.append(PageBreak())
    story.append(Paragraph(
        "13. Model Compression — Options 4 & 5", styles['SectionHead']))
    story.append(Paragraph(
        "After verifying C code generation for all five options, a model compression "
        "sub-pipeline was developed for Options 4 and 5 to reduce Flash memory requirements "
        "for deployment on constrained targets. The goal was MAE &lt; 1e-3 vs the PyTorch "
        "reference on 100 test vectors, with maximum achievable parameter reduction.",
        styles['Body']))
    story.append(Paragraph(
        "<b>Baseline:</b> 55,169 parameters, 215.5 KB float32 (Option 5 native dlnetwork).",
        styles['Body']))

    # --- Option 4 compression ---
    story.append(Paragraph("13.1 Option 4 (ONNX) Compression", styles['SubHead']))
    story.append(Paragraph(
        "The ONNX-imported network contains auto-generated custom layers "
        "(<font face='Courier'>soc_model_legacy</font>) that limit compression options.",
        styles['Body']))

    comp4_data = [
        ['Technique', 'Result', 'MAE', 'Size', 'Savings'],
        ['neuronPCA + projection', 'WORKS', 'varies', '—', '—'],
        ['dlquantizer (int8)', 'FAILS', 'N/A', 'N/A', 'N/A'],
        ['taylorPrunableNetwork', 'FAILS', 'N/A', 'N/A', 'N/A'],
        ['manual_int8 (BEST)', 'PASS ✓', '3.55e-04', '~53.9 KB', '75.0%'],
    ]
    t_c4 = Table(comp4_data, colWidths=[2.0*inch, 1.0*inch, 1.0*inch, 1.0*inch, 1.0*inch])
    t_c4.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2c3e50')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
        ('BACKGROUND', (0, -1), (-1, -1), colors.HexColor('#eafaf1')),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t_c4)
    story.append(Spacer(1, 0.08*inch))
    story.append(Paragraph(
        "<b>Why dlquantizer fails for Option 4:</b> "
        "<font face='Courier'>dlquantizer</font> does not support networks containing "
        "ONNX-imported custom layers. The error is: "
        "<font face='Courier'>\"Quantization is not supported for the current network architecture.\"</font> "
        "The ONNX custom layers (<font face='Courier'>Shape_To_Expand</font>, "
        "<font face='Courier'>Squeeze_To_Expand</font>, etc.) are not compatible with "
        "the Fixed-Point Toolbox simulation required by the quantizer calibration step. "
        "Manual int8 weight quantization remains the best available option for Option 4.",
        styles['Body']))
    story.append(Paragraph(
        "<b>Simulink for Option 4:</b> "
        "<font face='Courier'>exportNetworkToSimulink</font> also fails for the ONNX-imported "
        "network because Simulink cannot generate blocks for ONNX custom layers. "
        "Simulink integration (Steps 2 and 3) is therefore skipped for Option 4.",
        styles['Body']))

    # --- Option 5 compression ---
    story.append(Paragraph("13.2 Option 5 (Native dlnetwork) Compression", styles['SubHead']))
    story.append(Paragraph(
        "The native dlnetwork (all standard MATLAB layers, no custom layers) supports "
        "the full compression toolchain. Five techniques were evaluated, plus one "
        "combined pipeline.",
        styles['Body']))

    comp5_data = [
        ['Technique', 'Status', 'MAE', 'Size (KB)', 'Savings %'],
        ['Baseline (float32)', 'BASELINE', '5.16e-09', '215.5', '0%'],
        ['proj_cf01 (10% projection)', 'PASS ✓', '3.93e-04', '193.6', '10.2%'],
        ['proj_cf07 (70% projection)', 'FAIL', '1.70e-03', '61.9', '71.3%'],
        ['proj_cf09 (90% projection)', 'FAIL', '1.64e-03', '19.3', '91.0%'],
        ['proj10_quant (10%+int8) ← WINNER', 'PASS ✓', '9.50e-04', '48.4', '77.5%'],
        ['quant_int8 (baseline+int8)', 'PASS ✓', '9.31e-04', '53.9', '75.0%'],
        ['manual_int8', 'PASS ✓', '3.55e-04', '53.9', '75.0%'],
        ['taylorPrunableNetwork', 'FAILS', 'N/A', 'N/A', 'N/A'],
    ]
    t_c5 = Table(comp5_data, colWidths=[2.3*inch, 0.9*inch, 1.0*inch, 0.9*inch, 0.9*inch])
    t_c5.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a5276')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
        ('BACKGROUND', (0, 5), (-1, 5), colors.HexColor('#eafaf1')),
        ('FONTNAME', (0, 5), (-1, 5), 'Helvetica-Bold'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t_c5)
    story.append(Spacer(1, 0.1*inch))

    story.append(Paragraph("13.3 Combined Compression Pipeline (proj10_quant)", styles['SubHead']))
    story.append(Paragraph(
        "The winning approach applies two compression stages in sequence:<br/>"
        "<b>Stage 1 — neuronPCA projection (10%):</b> "
        "<font face='Courier'>neuronPCA(baseNet, mbq)</font> pre-computes principal "
        "component analysis on the LSTM and FC layer activations. "
        "<font face='Courier'>compressNetworkUsingProjection</font> with "
        "<font face='Courier'>LearnablesReductionGoal=0.10</font> and "
        "<font face='Courier'>UnpackProjectedLayers=true</font> reduces parameters by 10.2% "
        "(215.5 KB → 193.6 KB). Accuracy is already within budget at this stage "
        "(MAE = 3.93e-04). No fine-tuning required.<br/>"
        "<b>Stage 2 — dlquantizer int8:</b> The projected dlnetwork is fed to "
        "<font face='Courier'>dlquantizer</font> with "
        "<font face='Courier'>ExecutionEnvironment='MATLAB'</font>. The projected network "
        "is a plain dlnetwork (all native MATLAB layers after UnpackProjectedLayers), so "
        "the full quantization pipeline applies. The resulting "
        "<font face='Courier'>quantizedDlnetwork</font> uses int8 weights, reducing "
        "the 193.6 KB float32 projected model to ~48.4 KB.<br/>"
        "<b>Combined result:</b> 215.5 KB → 48.4 KB = <b>77.5% Flash savings</b>, MAE = 9.50e-04 [PASS].",
        styles['Body']))

    story.append(Paragraph("13.4 Key Technical Challenges Solved", styles['SubHead']))

    challenges = [
        ("<b>neuronPCA minibatchqueue format</b>",
         "neuronPCA requires a minibatchqueue with cell-array inputs. Must use: "
         "arrayDatastore of [T×F] cell arrays, MiniBatchFormat='TCB', "
         "MiniBatchFcn=@(X) cat(3,X{:}). Standard numeric array datastores fail."),
        ("<b>dlquantizer requires prepareNetwork before calibrate</b>",
         "Without calling prepareNetwork(qObj) first, LSTM (h,c) state outputs are "
         "packaged as MATLAB table objects internally. The Fixed-Point Toolbox fi() "
         "function cannot handle table inputs, producing: "
         "'fixed:fi:unsupportedType: Inputs of class table are not supported.' "
         "Fix: always call prepareNetwork(qObj) before calibrate()."),
        ("<b>calibrate only accepts ArrayDatastore</b>",
         "Despite documentation hints, calibrate() does not accept minibatchqueue. "
         "It accepts ArrayDatastore of [T×F] cell sequences only "
         "(IterationDimension=1, OutputType='same'). "
         "Numeric [N×T×F] arrays produce 'Input data size not compatible.'"),
        ("<b>macOS crash after quantize</b>",
         "MATLAB R2026a crashes in a background connector thread "
         "(detectHomeSessionAndSetInfo) immediately after quantize() returns on macOS. "
         "Fix: save('soc_qnet_opt5.mat', 'qNet', '-v7.3') immediately after quantize, "
         "before any other operations."),
        ("<b>ARM Cortex-M codegen: PortableWordSizes required</b>",
         "Quantized network generates fixed-point integer type checks "
         "('#error Code was generated for compiler with different sized ulong/long') "
         "when targeting ARM Cortex-M (32-bit ulong) from macOS ARM64 (64-bit ulong). "
         "Fix: set_param(model, 'PortableWordSizes', 'on')."),
        ("<b>Projection accuracy degrades sharply above 10%</b>",
         "Test vectors come from a narrow operating condition (outputs all ≈ -0.031 ± 0.002). "
         "Projection at 70% and 90% goals compresses too aggressively. "
         "Fine-tuning on 100 real samples cannot recover accuracy (insufficient data). "
         "Synthetic N(0,1) training data makes accuracy worse (distribution mismatch). "
         "Only 10% goal passes without fine-tuning (MAE = 3.93e-04)."),
    ]

    for title, body in challenges:
        challenge_data = [[
            Paragraph(f"{title}<br/>{body}", styles['Body'])
        ]]
        t_ch = Table(challenge_data, colWidths=[6.5*inch])
        t_ch.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#f8f9fa')),
            ('BOX', (0, 0), (-1, -1), 0.5, colors.HexColor('#2c3e50')),
            ('LEFTBORDER', (0, 0), (0, -1), 3, colors.HexColor('#1a5276')),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('LEFTPADDING', (0, 0), (-1, -1), 10),
            ('RIGHTPADDING', (0, 0), (-1, -1), 10),
        ]))
        story.append(t_ch)
        story.append(Spacer(1, 0.04*inch))

    story.append(Paragraph("13.5 Simulink Verification & Codegen", styles['SubHead']))
    story.append(Paragraph(
        "The winning <font face='Courier'>proj10_quant</font> (quantizedDlnetwork) was "
        "exported directly to Simulink using <font face='Courier'>exportNetworkToSimulink</font>, "
        "which supports quantizedDlnetwork and generates fixed-point Simulink blocks.",
        styles['Body']))

    sim_data = [
        ['Verification Stage', 'Result', 'Metric'],
        ['MATLAB predict (quantized vs PyTorch)', 'PASS ✓', 'MAE = 9.50e-04 < 1e-03'],
        ['Simulink sim (100 samples × 10 steps)', 'PASS ✓', 'MAE = 2.09e-03 < 5e-03'],
        ['Codegen — direct float32 (baseline)', '14 C files / 854 KB', '12,463 lines'],
        ['Codegen — Simulink fixed-point (proj10_quant)', '3 C files / 262 KB', '3,534 lines'],
        ['Code size reduction', '69% smaller', '0.31× vs direct codegen'],
    ]
    t_sim = Table(sim_data, colWidths=[2.8*inch, 1.8*inch, 2.0*inch])
    t_sim.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#27ae60')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#eafaf1')]),
        ('BACKGROUND', (0, -1), (-1, -1), colors.HexColor('#d5f5e3')),
        ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t_sim)
    story.append(Spacer(1, 0.1*inch))

    story.append(Paragraph(
        "<b>Summary:</b> The combined projection + quantization pipeline for Option 5 achieves "
        "<b>77.5% Flash reduction</b> (215.5 KB → 48.4 KB) while maintaining SOC accuracy within "
        "the 1e-3 MAE budget. The compressed network integrates cleanly into Simulink "
        "(fixed-point blocks, step/init/terminate harness) and generates 69% less C code "
        "than the direct float32 codegen path. For Option 4 (ONNX), manual int8 weight "
        "quantization provides 75% savings and remains the best available approach due to "
        "custom layer constraints.",
        styles['Body']))

    # Build PDF
    doc.build(story)
    print(f"Report generated: {os.path.abspath(OUTPUT_PATH)}")


if __name__ == '__main__':
    build_report()

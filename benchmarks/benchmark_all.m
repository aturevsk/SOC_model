%% Benchmark All Options — Comparative Analysis
% =========================================================================
% This script runs benchmarks for all code generation options and produces
% a comparative analysis table.
%
% Run this AFTER running the individual option scripts.
% =========================================================================

clear; clc;
fprintf('=====================================================\n');
fprintf('   SOC Model — Code Generation Benchmark Report\n');
fprintf('=====================================================\n\n');

%% Model Summary
fprintf('Model Architecture:\n');
fprintf('  2-layer LSTM (input=5, hidden=64) + Dense Head (64→64→1)\n');
fprintf('  Total parameters: 55,681 (217.5 KB float32)\n');
fprintf('  Input:  [1, 10, 5] (batch=1, seq_len=10, features=5)\n');
fprintf('  Output: [1, 1] (SOC estimate)\n');
fprintf('  Target: STM32F746G-Discovery (Cortex-M7, 216MHz, 1MB Flash, 320KB RAM)\n\n');

%% Collect metrics for each option
results = struct();

% --- Option 1: Manual C ---
fprintf('--- Option 1: Manual C Implementation ---\n');
opt1_dir = fullfile('..', 'option1_c');
if isfolder(opt1_dir)
    cFiles = dir(fullfile(opt1_dir, '*.c'));
    hFiles = dir(fullfile(opt1_dir, '*.h'));
    srcBytes = 0;
    for i = 1:numel(cFiles), srcBytes = srcBytes + cFiles(i).bytes; end
    for i = 1:numel(hFiles), srcBytes = srcBytes + hFiles(i).bytes; end

    results.opt1.name = 'Manual C';
    results.opt1.numCFiles = numel(cFiles);
    results.opt1.numHFiles = numel(hFiles);
    results.opt1.srcBytes = srcBytes;
    results.opt1.flashKB = 55681 * 4 / 1024;  % weights only
    results.opt1.ramKB = (2*2*64*4 + 256*4 + 10*64*4 + 64*4) / 1024;
    results.opt1.dependencies = 'None (standalone C99)';
    results.opt1.portability = 'Any C99 compiler';

    fprintf('  Source files: %d .c, %d .h\n', results.opt1.numCFiles, results.opt1.numHFiles);
    fprintf('  Source size:  %.1f KB\n', srcBytes/1024);
    fprintf('  Flash (weights): %.1f KB\n', results.opt1.flashKB);
    fprintf('  RAM (buffers):   %.1f KB\n', results.opt1.ramKB);
    fprintf('  Dependencies:    %s\n', results.opt1.dependencies);
else
    fprintf('  [NOT FOUND]\n');
end

% --- Option 2: PyTorch Coder ---
fprintf('\n--- Option 2: MATLAB Coder PyTorch Support Package ---\n');
opt2_dir = fullfile('..', 'option2_matlab_pytorch_coder', 'codegen_output');
if isfolder(opt2_dir)
    cFiles = dir(fullfile(opt2_dir, '**', '*.c'));
    hFiles = dir(fullfile(opt2_dir, '**', '*.h'));
    srcBytes = 0;
    for i = 1:numel(cFiles), srcBytes = srcBytes + cFiles(i).bytes; end
    for i = 1:numel(hFiles), srcBytes = srcBytes + hFiles(i).bytes; end

    results.opt2.name = 'PyTorch Coder';
    results.opt2.numCFiles = numel(cFiles);
    results.opt2.numHFiles = numel(hFiles);
    results.opt2.srcBytes = srcBytes;
    results.opt2.dependencies = 'MATLAB Coder runtime (if any)';

    fprintf('  Source files: %d .c, %d .h\n', results.opt2.numCFiles, results.opt2.numHFiles);
    fprintf('  Source size:  %.1f KB\n', srcBytes/1024);
else
    fprintf('  [NOT YET GENERATED — run generate_code_pytorch_coder.m first]\n');
    results.opt2.name = 'PyTorch Coder';
    results.opt2.srcBytes = 0;
end

% --- Option 3: importNetworkFromPyTorch ---
fprintf('\n--- Option 3: importNetworkFromPyTorch + Codegen ---\n');
opt3_dir = fullfile('..', 'option3_matlab_import_pytorch', 'codegen_output');
if isfolder(opt3_dir)
    cFiles = dir(fullfile(opt3_dir, '**', '*.c'));
    hFiles = dir(fullfile(opt3_dir, '**', '*.h'));
    srcBytes = 0;
    for i = 1:numel(cFiles), srcBytes = srcBytes + cFiles(i).bytes; end
    for i = 1:numel(hFiles), srcBytes = srcBytes + hFiles(i).bytes; end

    results.opt3.name = 'importPyTorch+Codegen';
    results.opt3.numCFiles = numel(cFiles);
    results.opt3.numHFiles = numel(hFiles);
    results.opt3.srcBytes = srcBytes;

    fprintf('  Source files: %d .c, %d .h\n', results.opt3.numCFiles, results.opt3.numHFiles);
    fprintf('  Source size:  %.1f KB\n', srcBytes/1024);
else
    fprintf('  [NOT YET GENERATED — run generate_code_import_pytorch.m first]\n');
    results.opt3.name = 'importPyTorch+Codegen';
    results.opt3.srcBytes = 0;
end

% --- Option 4: ONNX Import ---
fprintf('\n--- Option 4: ONNX Import + Codegen ---\n');
opt4_dir = fullfile('..', 'option4_matlab_onnx', 'codegen_output');
if isfolder(opt4_dir)
    cFiles = dir(fullfile(opt4_dir, '**', '*.c'));
    hFiles = dir(fullfile(opt4_dir, '**', '*.h'));
    srcBytes = 0;
    for i = 1:numel(cFiles), srcBytes = srcBytes + cFiles(i).bytes; end
    for i = 1:numel(hFiles), srcBytes = srcBytes + hFiles(i).bytes; end

    results.opt4.name = 'ONNX+Codegen';
    results.opt4.numCFiles = numel(cFiles);
    results.opt4.numHFiles = numel(hFiles);
    results.opt4.srcBytes = srcBytes;

    fprintf('  Source files: %d .c, %d .h\n', results.opt4.numCFiles, results.opt4.numHFiles);
    fprintf('  Source size:  %.1f KB\n', srcBytes/1024);
else
    fprintf('  [NOT YET GENERATED — run generate_code_onnx.m first]\n');
    results.opt4.name = 'ONNX+Codegen';
    results.opt4.srcBytes = 0;
end

%% Comparison Table
fprintf('\n=====================================================\n');
fprintf('   Comparison Summary\n');
fprintf('=====================================================\n');
fprintf('%-25s | %-12s | %-12s | %-12s | %-12s\n', ...
    'Metric', 'Option 1', 'Option 2', 'Option 3', 'Option 4');
fprintf('%s\n', repmat('-', 1, 80));
fprintf('%-25s | %-12s | %-12s | %-12s | %-12s\n', ...
    'Approach', 'Manual C', 'PT Coder', 'importPT', 'ONNX Import');
fprintf('%-25s | %-12s | %-12s | %-12s | %-12s\n', ...
    'Toolbox Required', 'None', 'Coder+SP', 'DLT+Coder', 'DLT+Coder');
fprintf('%-25s | %-12s | %-12s | %-12s | %-12s\n', ...
    'External Dependencies', 'None', 'Varies', 'None/DL lib', 'None/DL lib');
fprintf('%-25s | %-12s | %-12s | %-12s | %-12s\n', ...
    'Code Portability', 'Excellent', 'Good', 'Good', 'Good');

%% Save results
save('benchmark_results.mat', 'results');
fprintf('\nResults saved to benchmark_results.mat\n');
fprintf('\nNote: Run individual option scripts first to populate codegen_output.\n');
fprintf('Then re-run this script for complete metrics.\n');

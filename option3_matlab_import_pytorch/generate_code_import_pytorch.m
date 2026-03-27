%% Option 3: Import PyTorch Model → dlnetwork → MATLAB Coder / Embedded Coder
% =========================================================================
% This script imports the PyTorch ExportedProgram into MATLAB as a
% dlnetwork using importNetworkFromPyTorch, then attempts to use MATLAB
% Coder and Embedded Coder to generate optimized C code for STM32.
%
% RESULT: Code generation FAILS for this model. The importer creates a
% custom layer (SOC_LSTM_select_2) for the PyTorch h_n[-1] selection
% operation that does not support code generation. Unlike ONNX-imported
% custom layers, the PyTorch-imported custom layer has no
% matlabCodegenRedirect method. Use Option 4 (ONNX import) as fallback.
%
% Target: STM32F746G-Discovery (ARM Cortex-M7, FPV5 FPU)
% Model:  SOC estimation LSTM (2-layer LSTM + dense head)
%
% Requirements:
%   - MATLAB R2026a
%   - Deep Learning Toolbox
%   - MATLAB Coder
%   - Embedded Coder
%
% =========================================================================

%% Setup
clear; clc;
fprintf('=== Option 3: importNetworkFromPyTorch + Codegen ===\n');

modelPath = fullfile('..', 'soc_model.pt2');
assert(isfile(modelPath), 'Model file not found: %s', modelPath);

%% Step 1: Import PyTorch model as dlnetwork
fprintf('\n[Step 1] Importing PyTorch model as dlnetwork...\n');

try
    net = importNetworkFromPyTorch(modelPath);
    fprintf('Import SUCCESSFUL!\n');
    fprintf('Network type: %s\n', class(net));
catch ME
    fprintf('Import FAILED: %s\n', ME.message);

    % Try with explicit input size specification
    fprintf('\nRetrying with explicit InputSize...\n');
    try
        net = importNetworkFromPyTorch(modelPath, ...
            'InputSize', [1 10 5]);
        fprintf('Import with InputSize SUCCESSFUL!\n');
    catch ME2
        fprintf('Import with InputSize also FAILED: %s\n', ME2.message);
        fprintf('\nFalling back to Option 4 (ONNX import).\n');
        fprintf('Run generate_code_onnx.m instead.\n');
        return;
    end
end

%% Step 1b: Expand network layers for codegen compatibility
fprintf('\n[Step 1b] Expanding network layers for codegen...\n');
try
    net = expandLayers(net);
    fprintf('Network expanded successfully.\n');
catch ME
    fprintf('expandLayers failed: %s\n', ME.message);
    fprintf('Proceeding with original network.\n');
end

%% Step 2: Inspect the imported network
fprintf('\n[Step 2] Inspecting imported network...\n');
disp(net);

% Analyze network layers
fprintf('\nNetwork layers:\n');
if isprop(net, 'Layers')
    for i = 1:numel(net.Layers)
        fprintf('  [%d] %s (%s)\n', i, net.Layers(i).Name, class(net.Layers(i)));
    end
end

% Display learnable parameters summary
fprintf('\nLearnable parameters:\n');
if isprop(net, 'Learnables')
    learnables = net.Learnables;
    totalParams = 0;
    for i = 1:size(learnables, 1)
        paramName = learnables.Parameter{i};
        layerName = learnables.Layer{i};
        paramValue = learnables.Value{i};
        paramCount = numel(extractdata(paramValue));
        totalParams = totalParams + paramCount;
        fprintf('  %s/%s: [%s] (%d params)\n', ...
            layerName, paramName, ...
            strjoin(string(size(extractdata(paramValue))), 'x'), ...
            paramCount);
    end
    fprintf('  Total learnable parameters: %d\n', totalParams);
    fprintf('  Memory (float32): %.1f KB\n', totalParams * 4 / 1024);
end

%% Step 3: Validate inference in MATLAB
fprintf('\n[Step 3] Validating inference...\n');

% Create test input as dlarray
% PyTorch input is [batch=1, seq=10, features=5] with batch_first=True
% MATLAB dlarray format for sequence data: 'CTB' or 'SCB'
testInput = single(randn(1, 10, 5));
dlInput = dlarray(testInput, 'BTC');  % Batch-Time-Channel

try
    dlOutput = predict(net, dlInput);
    outputVal = extractdata(dlOutput);
    fprintf('MATLAB inference result: %.6f\n', outputVal);
    fprintf('Output shape: %s\n', mat2str(size(outputVal)));
catch ME
    fprintf('Inference failed: %s\n', ME.message);

    % Try alternative dlarray formats
    fprintf('Trying alternative input formats...\n');
    formats = {'CBT', 'TCB', 'BTC', 'BCT'};
    for f = 1:numel(formats)
        try
            dlInput2 = dlarray(testInput, formats{f});
            dlOutput = predict(net, dlInput2);
            outputVal = extractdata(dlOutput);
            fprintf('  Format %s works! Output: %.6f\n', formats{f}, outputVal);
            break;
        catch
            fprintf('  Format %s failed.\n', formats{f});
        end
    end
end

%% Step 4: Create entry-point function for codegen
fprintf('\n[Step 4] Creating entry-point function for codegen...\n');

entryFcnFile = 'predict_soc_dlnet.m';
fid = fopen(entryFcnFile, 'w');
fprintf(fid, 'function soc = predict_soc_dlnet(in) %%#codegen\n');
fprintf(fid, '%%%% predict_soc_dlnet - SOC prediction entry point for code generation\n');
fprintf(fid, '%%   soc = predict_soc_dlnet(in)\n');
fprintf(fid, '%%   in:  single(10x5) - 10 timesteps, 5 features (no batch dim)\n');
fprintf(fid, '%%   soc: single(1x1) - predicted state of charge\n');
fprintf(fid, '%%\n');
fprintf(fid, '%% This function is the code generation entry point.\n');
fprintf(fid, '%% The persistent network is loaded once and reused.\n');
fprintf(fid, '\n');
fprintf(fid, '    persistent net;\n');
fprintf(fid, '    if isempty(net)\n');
fprintf(fid, '        net = coder.loadDeepLearningNetwork(''soc_dlnetwork.mat'');\n');
fprintf(fid, '    end\n');
fprintf(fid, '\n');
fprintf(fid, '    %% Reshape input: add batch dimension\n');
fprintf(fid, '    x = reshape(in, [1 10 5]);\n');
fprintf(fid, '\n');
fprintf(fid, '    %% Create dlarray with appropriate format\n');
fprintf(fid, '    dlX = dlarray(x, ''BTC'');\n');
fprintf(fid, '\n');
fprintf(fid, '    %% Run prediction\n');
fprintf(fid, '    dlY = predict(net, dlX);\n');
fprintf(fid, '\n');
fprintf(fid, '    %% Extract output\n');
fprintf(fid, '    soc = extractdata(dlY);\n');
fprintf(fid, 'end\n');
fclose(fid);
fprintf('Entry-point function created: %s\n', entryFcnFile);

%% Step 5: Save the dlnetwork for codegen
fprintf('\n[Step 5] Saving dlnetwork for code generation...\n');
save('soc_dlnetwork.mat', 'net');
fprintf('Network saved to soc_dlnetwork.mat\n');

%% Step 6: Configure and run code generation
fprintf('\n[Step 6] Configuring code generation...\n');

% Define input type: single(10x5) - no batch dimension for embedded
inputType = {coder.typeof(single(0), [10 5], [false false])};

% Code generation configuration — Embedded Coder for STM32 target
cfg = coder.config('lib', 'ecoder', true);
cfg.TargetLang = 'C';
cfg.GenerateReport = true;
cfg.LaunchReport = false;

% Hardware configuration for STM32F746G
cfg.HardwareImplementation.ProdHWDeviceType = 'ARM Compatible->ARM Cortex-M';
cfg.HardwareImplementation.ProdBitPerChar = 8;
cfg.HardwareImplementation.ProdBitPerShort = 16;
cfg.HardwareImplementation.ProdBitPerInt = 32;
cfg.HardwareImplementation.ProdBitPerLong = 32;
cfg.HardwareImplementation.ProdBitPerFloat = 32;
cfg.HardwareImplementation.ProdBitPerDouble = 64;

% Optimization for size (embedded target)
cfg.SupportNonFinite = false;
cfg.PreserveVariableNames = 'None';
cfg.InlineBetweenUserFunctions = 'Always';
cfg.InlineBetweenMathWorksFunctions = 'Always';

% Deep learning code generation config — pure C, no external library
dlcfg = coder.DeepLearningConfig('none');
cfg.DeepLearningConfig = dlcfg;

outputDir = fullfile(pwd, 'codegen_output');
fprintf('Configuration complete. Generating code...\n');

%% Step 7: Generate code
fprintf('\n[Step 7] Running codegen...\n');
try
    codegen -config cfg predict_soc_dlnet -args inputType -d outputDir -report
    fprintf('\nCode generation SUCCESSFUL!\n');
    fprintf('Output: %s\n', outputDir);
catch ME
    fprintf('\nCode generation FAILED: %s\n', ME.message);

    % Try with Embedded Coder ERT target
    fprintf('\nRetrying with ERT (Embedded Real-Time) target...\n');
    try
        cfg2 = coder.config('lib');
        cfg2.TargetLang = 'C';
        cfg2.GenerateReport = true;

        % Use ARM Cortex-M hardware board if available
        cfg2.HardwareImplementation.ProdHWDeviceType = ...
            'ARM Compatible->ARM Cortex-M';

        dlcfg2 = coder.DeepLearningConfig('none');
        cfg2.DeepLearningConfig = dlcfg2;

        codegen -config cfg2 predict_soc_dlnet -args inputType -d outputDir -report
        fprintf('ERT code generation SUCCESSFUL!\n');
    catch ME2
        fprintf('ERT codegen also failed: %s\n', ME2.message);
        fprintf('\nDiagnostics:\n');
        fprintf('  Check that all layers support code generation.\n');
        fprintf('  LSTM layers may need the Deep Learning Toolbox Model\n');
        fprintf('  Quantization Library or similar support package.\n');
    end
end

%% Step 8: Analyze generated code
fprintf('\n[Step 8] Analyzing generated code...\n');
if isfolder(outputDir)
    cFiles = dir(fullfile(outputDir, '**', '*.c'));
    hFiles = dir(fullfile(outputDir, '**', '*.h'));
    fprintf('Generated files:\n');

    totalBytes = 0;
    totalLines = 0;
    for i = 1:numel(cFiles)
        totalBytes = totalBytes + cFiles(i).bytes;
        txt = fileread(fullfile(cFiles(i).folder, cFiles(i).name));
        totalLines = totalLines + numel(strfind(txt, newline));
        fprintf('  %s (%d bytes)\n', cFiles(i).name, cFiles(i).bytes);
    end
    for i = 1:numel(hFiles)
        totalBytes = totalBytes + hFiles(i).bytes;
        fprintf('  %s (%d bytes)\n', hFiles(i).name, hFiles(i).bytes);
    end

    fprintf('\nTotal source size: %d bytes (%.1f KB)\n', totalBytes, totalBytes/1024);
    fprintf('Total lines of C: %d\n', totalLines);
else
    fprintf('No output directory found.\n');
end

%% Step 9: Benchmark
fprintf('\n[Step 9] Benchmarking MATLAB inference...\n');
nRuns = 1000;
tic;
for i = 1:nRuns
    dlY = predict(net, dlInput);
end
elapsed = toc;
fprintf('dlnetwork inference: %d runs in %.3f s (%.3f ms/run)\n', ...
    nRuns, elapsed, elapsed/nRuns*1000);

fprintf('\n=== Option 3 Complete ===\n');

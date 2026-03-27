%% Option 4: Import ONNX Model → dlnetwork → MATLAB Coder / Embedded Coder
% =========================================================================
% This script imports the SOC model from ONNX format into MATLAB as a
% dlnetwork using importNetworkFromONNX, then generates C code using
% MATLAB Coder and Embedded Coder.
%
% Key R2026a Feature: Auto-generated custom layers from ONNX import now
% support code generation natively. This eliminates the previous limitation
% where custom layers created during ONNX import blocked codegen.
%
% Target: STM32F746G-Discovery (ARM Cortex-M7, FPV5 FPU)
% Model:  SOC estimation LSTM (2-layer LSTM + dense head)
%
% Requirements:
%   - MATLAB R2026a
%   - Deep Learning Toolbox
%   - Deep Learning Toolbox Converter for ONNX Model Format
%   - MATLAB Coder
%   - Embedded Coder
%
% =========================================================================

%% Setup
clear; clc;
fprintf('=== Option 4: ONNX Import + Codegen ===\n');

onnxPath = fullfile('..', 'soc_model_legacy.onnx');
assert(isfile(onnxPath), 'ONNX model not found: %s', onnxPath);

%% Step 1: Inspect ONNX model
fprintf('\n[Step 1] Inspecting ONNX model...\n');

% Display ONNX model info
try
    onnxInfo = importONNXNetwork(onnxPath, 'OutputLayerType', 'regression', ...
        'TargetNetwork', 'dlnetwork');
    fprintf('Quick inspection via importONNXNetwork succeeded.\n');
catch
    fprintf('importONNXNetwork preview not available, proceeding with importNetworkFromONNX.\n');
end

%% Step 2: Import ONNX model as dlnetwork
fprintf('\n[Step 2] Importing ONNX model as dlnetwork...\n');

try
    % R2026a importNetworkFromONNX - returns dlnetwork directly
    net = importNetworkFromONNX(onnxPath);
    fprintf('Import SUCCESSFUL!\n');
    fprintf('Network type: %s\n', class(net));
catch ME
    fprintf('Direct import failed: %s\n', ME.message);

    % Try with explicit options
    fprintf('Retrying with explicit options...\n');
    try
        net = importNetworkFromONNX(onnxPath, ...
            'InputDataFormats', 'BTC', ...
            'OutputDataFormats', 'BC');
        fprintf('Import with format spec SUCCESSFUL!\n');
    catch ME2
        fprintf('Import failed: %s\n', ME2.message);
        % Final attempt: importONNXLayers + assemble
        fprintf('Trying importONNXLayers + assembleNetwork...\n');
        try
            layers = importONNXLayers(onnxPath, 'ImportWeights', true);
            net = dlnetwork(layers);
            fprintf('Layer import + assembly SUCCESSFUL!\n');
        catch ME3
            fprintf('All import methods failed: %s\n', ME3.message);
            return;
        end
    end
end

%% Step 3: Inspect imported network
fprintf('\n[Step 3] Inspecting imported network...\n');
disp(net);

fprintf('\nNetwork layers:\n');
if isprop(net, 'Layers')
    for i = 1:numel(net.Layers)
        layerClass = class(net.Layers(i));
        % Flag auto-generated custom layers
        isCustom = contains(layerClass, 'nnet.onnx') || ...
                   contains(layerClass, 'Custom');
        customTag = '';
        if isCustom
            customTag = ' [AUTO-GENERATED CUSTOM - codegen supported in R2026a]';
        end
        fprintf('  [%d] %s (%s)%s\n', i, net.Layers(i).Name, ...
            layerClass, customTag);
    end
end

% Learnable parameters
fprintf('\nLearnable parameters:\n');
if isprop(net, 'Learnables')
    learnables = net.Learnables;
    totalParams = 0;
    for i = 1:size(learnables, 1)
        paramValue = learnables.Value{i};
        paramCount = numel(extractdata(paramValue));
        totalParams = totalParams + paramCount;
        fprintf('  %s/%s: [%s] (%d params)\n', ...
            learnables.Layer{i}, learnables.Parameter{i}, ...
            strjoin(string(size(extractdata(paramValue))), 'x'), ...
            paramCount);
    end
    fprintf('  Total: %d params (%.1f KB float32)\n', ...
        totalParams, totalParams*4/1024);
end

%% Step 4: Validate inference
fprintf('\n[Step 4] Validating inference...\n');

testInput = single(randn(1, 10, 5));

% Try different dlarray formats for ONNX-imported networks
formats = {'BTC', 'BCT', 'CBT', 'TCB'};
inferenceOK = false;

for f = 1:numel(formats)
    try
        dlX = dlarray(testInput, formats{f});
        dlY = predict(net, dlX);
        outputVal = extractdata(dlY);
        fprintf('Format %s works! Output: %.6f, shape: %s\n', ...
            formats{f}, outputVal, mat2str(size(outputVal)));
        bestFormat = formats{f};
        inferenceOK = true;
        break;
    catch ME
        fprintf('  Format %s failed: %s\n', formats{f}, ME.message);
    end
end

if ~inferenceOK
    fprintf('WARNING: Could not run inference with any format.\n');
    fprintf('Attempting without dlarray format labels...\n');
    try
        dlX = dlarray(testInput);
        dlY = predict(net, dlX);
        outputVal = extractdata(dlY);
        fprintf('Unformatted dlarray works! Output: %.6f\n', outputVal);
        bestFormat = '';
        inferenceOK = true;
    catch ME
        fprintf('Unformatted also failed: %s\n', ME.message);
        return;
    end
end

%% Step 5: Save network and create entry-point function
fprintf('\n[Step 5] Saving network and creating entry-point function...\n');

save('soc_dlnetwork_onnx.mat', 'net');
fprintf('Network saved to soc_dlnetwork_onnx.mat\n');

% Create entry-point function
entryFcnFile = 'predict_soc_onnx.m';
fid = fopen(entryFcnFile, 'w');
fprintf(fid, 'function soc = predict_soc_onnx(in) %%#codegen\n');
fprintf(fid, '%%%% predict_soc_onnx - SOC prediction from ONNX-imported network\n');
fprintf(fid, '%%   soc = predict_soc_onnx(in)\n');
fprintf(fid, '%%   in:  single(10x5) - 10 timesteps, 5 features\n');
fprintf(fid, '%%   soc: single(1x1) - predicted state of charge\n');
fprintf(fid, '%%\n');
fprintf(fid, '%% R2026a: Auto-generated custom layers from ONNX support codegen.\n');
fprintf(fid, '\n');
fprintf(fid, '    persistent net;\n');
fprintf(fid, '    if isempty(net)\n');
fprintf(fid, '        net = coder.loadDeepLearningNetwork(''soc_dlnetwork_onnx.mat'');\n');
fprintf(fid, '    end\n');
fprintf(fid, '\n');
fprintf(fid, '    x = reshape(in, [1 10 5]);\n');
if ~isempty(bestFormat)
    fprintf(fid, '    dlX = dlarray(x, ''%s'');\n', bestFormat);
else
    fprintf(fid, '    dlX = dlarray(x);\n');
end
fprintf(fid, '    dlY = predict(net, dlX);\n');
fprintf(fid, '    soc = extractdata(dlY);\n');
fprintf(fid, 'end\n');
fclose(fid);
fprintf('Entry-point function created: %s\n', entryFcnFile);

%% Step 6: Configure code generation
fprintf('\n[Step 6] Configuring code generation...\n');

inputType = {coder.typeof(single(0), [10 5], [false false])};

% Use Embedded Coder for ARM target
cfg = coder.config('lib', 'ecoder', true);
cfg.TargetLang = 'C';
cfg.GenerateReport = true;
cfg.LaunchReport = false;

% STM32F746G hardware settings
cfg.HardwareImplementation.ProdHWDeviceType = 'ARM Compatible->ARM Cortex-M';
cfg.HardwareImplementation.ProdBitPerChar = 8;
cfg.HardwareImplementation.ProdBitPerShort = 16;
cfg.HardwareImplementation.ProdBitPerInt = 32;
cfg.HardwareImplementation.ProdBitPerLong = 32;
cfg.HardwareImplementation.ProdBitPerFloat = 32;
cfg.HardwareImplementation.ProdBitPerDouble = 64;

% Deep learning config: pure C, no external library
dlcfg = coder.DeepLearningConfig('none');
cfg.DeepLearningConfig = dlcfg;

% Optimizations
cfg.SupportNonFinite = false;
cfg.PreserveVariableNames = 'None';
cfg.InlineBetweenUserFunctions = 'Always';
cfg.InlineBetweenMathWorksFunctions = 'Always';

% Deep learning codegen config - pure C
% R2026a: auto-generated custom layers from ONNX import support codegen
dlcfg = coder.DeepLearningConfig('none');
cfg.DeepLearningConfig = dlcfg;

outputDir = fullfile(pwd, 'codegen_output');

%% Step 7: Generate code
fprintf('\n[Step 7] Running code generation...\n');
fprintf('Note: R2026a supports codegen for auto-generated ONNX custom layers.\n');

try
    codegen -config cfg predict_soc_onnx -args inputType -d outputDir -report
    fprintf('\nCode generation SUCCESSFUL!\n');
    fprintf('Output: %s\n', outputDir);
catch ME
    fprintf('\nCode generation FAILED: %s\n', ME.message);
    fprintf('\nDiagnostics:\n');
    fprintf('  Error ID: %s\n', ME.identifier);

    % Check if any custom layers don't support codegen
    if isprop(net, 'Layers')
        fprintf('\nChecking layer codegen support...\n');
        for i = 1:numel(net.Layers)
            layerClass = class(net.Layers(i));
            fprintf('  %s: %s\n', net.Layers(i).Name, layerClass);
        end
    end

    fprintf('\nTroubleshooting tips:\n');
    fprintf('  1. Ensure R2026a with latest updates\n');
    fprintf('  2. Check ver(''deep_learning_toolbox'') version\n');
    fprintf('  3. ONNX opset 17+ is used (our export uses opset 17)\n');
    fprintf('  4. LSTM operations should map to native MATLAB layers\n');
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

    fprintf('\nTotal source: %d bytes (%.1f KB)\n', totalBytes, totalBytes/1024);
    fprintf('Total lines of C: %d\n', totalLines);
else
    fprintf('No output directory found.\n');
end

%% Step 9: Benchmark
fprintf('\n[Step 9] Benchmarking inference...\n');
nRuns = 1000;
dlTestInput = dlarray(testInput, bestFormat);
tic;
for i = 1:nRuns
    dlY = predict(net, dlTestInput);
end
elapsed = toc;
fprintf('dlnetwork (ONNX) inference: %d runs in %.3f s (%.3f ms/run)\n', ...
    nRuns, elapsed, elapsed/nRuns*1000);

fprintf('\n=== Option 4 Complete ===\n');

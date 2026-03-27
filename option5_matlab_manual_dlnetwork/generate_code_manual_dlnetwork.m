%% Option 5: Manually Build Codegen-Compatible dlnetwork in MATLAB
% =========================================================================
% This script leverages the weights from importNetworkFromPyTorch but
% constructs a new dlnetwork using only native MATLAB layers that support
% code generation. This avoids the non-codegen custom layers created
% during import.
%
% Approach:
%   1. Import the PyTorch model to extract weights
%   2. Build a fresh dlnetwork with native LSTM + FC layers
%   3. Transfer the learned weights from the imported network
%   4. Handle the h_n[-1] selection using OutputMode='last' on LSTM
%   5. Generate C code using MATLAB Coder
%
% Target: STM32F746G-Discovery (ARM Cortex-M7, FPV5 FPU)
% =========================================================================

%% Setup
clear; clc;
fprintf('=== Option 5: Manual Codegen-Compatible dlnetwork ===\n');

modelPath = fullfile('..', 'soc_model.pt2');
assert(isfile(modelPath), 'Model file not found: %s', modelPath);

%% Step 1: Import to extract weights
fprintf('\n[Step 1] Importing PyTorch model to extract weights...\n');
importedNet = importNetworkFromPyTorch(modelPath);
importedNet = expandLayers(importedNet);

% Extract learnables
learnables = importedNet.Learnables;
fprintf('Imported network has %d learnable parameter sets.\n', size(learnables, 1));
for i = 1:size(learnables, 1)
    fprintf('  %s/%s: [%s]\n', learnables.Layer{i}, learnables.Parameter{i}, ...
        strjoin(string(size(extractdata(learnables.Value{i}))), 'x'));
end

%% Step 2: Build native dlnetwork
fprintf('\n[Step 2] Building native codegen-compatible dlnetwork...\n');

% Architecture: SequenceInput -> LSTM1 -> LSTM2(OutputMode=last) -> FC1 -> ReLU -> FC2
layers = [
    sequenceInputLayer(5, 'Name', 'input', 'MinLength', 10)
    lstmLayer(64, 'Name', 'lstm1', 'OutputMode', 'sequence')
    lstmLayer(64, 'Name', 'lstm2', 'OutputMode', 'last')
    fullyConnectedLayer(64, 'Name', 'fc1')
    reluLayer('Name', 'relu1')
    fullyConnectedLayer(1, 'Name', 'fc2')
];

net = dlnetwork(layers);
fprintf('Built network with %d layers.\n', numel(net.Layers));

%% Step 3: Transfer weights
fprintf('\n[Step 3] Transferring weights from imported network...\n');

% Map imported layer names to our layer names
% Imported: SOC_LSTM:lstm:SOC_LSTM:lstm:LSTM_1 -> our: lstm1
% Imported: SOC_LSTM:lstm:SOC_LSTM:lstm:LSTM_2 -> our: lstm2
% Imported: SOC_LSTM:head:0 -> our: fc1
% Imported: SOC_LSTM:head:2 -> our: fc2

% Helper to find param by layer substring and param name
findParam = @(learnables, layerSubstr, paramName) ...
    learnables.Value{contains(learnables.Layer, layerSubstr) & ...
                     strcmp(learnables.Parameter, paramName)};

% Transfer weights via the Learnables table
fprintf('  Transferring LSTM1 weights...\n');
lstm1_IW = findParam(learnables, 'LSTM_1', 'InputWeights');
lstm1_RW = findParam(learnables, 'LSTM_1', 'RecurrentWeights');
lstm1_B  = findParam(learnables, 'LSTM_1', 'Bias');

nativeLearn = net.Learnables;
nativeLearn = setWeight(nativeLearn, 'lstm1', 'InputWeights', lstm1_IW);
nativeLearn = setWeight(nativeLearn, 'lstm1', 'RecurrentWeights', lstm1_RW);
nativeLearn = setWeight(nativeLearn, 'lstm1', 'Bias', lstm1_B);

fprintf('  Transferring LSTM2 weights...\n');
lstm2_IW = findParam(learnables, 'LSTM_2', 'InputWeights');
lstm2_RW = findParam(learnables, 'LSTM_2', 'RecurrentWeights');
lstm2_B  = findParam(learnables, 'LSTM_2', 'Bias');

nativeLearn = setWeight(nativeLearn, 'lstm2', 'InputWeights', lstm2_IW);
nativeLearn = setWeight(nativeLearn, 'lstm2', 'RecurrentWeights', lstm2_RW);
nativeLearn = setWeight(nativeLearn, 'lstm2', 'Bias', lstm2_B);

fprintf('  Transferring FC1 weights...\n');
fc1_W = findParam(learnables, 'head:0', 'Weights');
fc1_B = findParam(learnables, 'head:0', 'Bias');

nativeLearn = setWeight(nativeLearn, 'fc1', 'Weights', fc1_W);
nativeLearn = setWeight(nativeLearn, 'fc1', 'Bias', fc1_B);

fprintf('  Transferring FC2 weights...\n');
fc2_W = findParam(learnables, 'head:2', 'Weights');
fc2_B = findParam(learnables, 'head:2', 'Bias');

nativeLearn = setWeight(nativeLearn, 'fc2', 'Weights', fc2_W);
nativeLearn = setWeight(nativeLearn, 'fc2', 'Bias', fc2_B);

net.Learnables = nativeLearn;

fprintf('All weights transferred.\n');

%% Step 4: Validate equivalence
fprintf('\n[Step 4] Validating equivalence with imported network...\n');

testInput = single(randn(1, 10, 5));
dlInput = dlarray(testInput, 'BTC');

% Imported network
importedOut = predict(importedNet, dlInput);
importedVal = extractdata(importedOut);
% Take last timestep if multi-timestep output
if numel(importedVal) > 1
    importedVal = importedVal(end);
end

% Our native network
nativeOut = predict(net, dlInput);
nativeVal = extractdata(nativeOut);

fprintf('  Imported network output: %.8f\n', importedVal);
fprintf('  Native network output:   %.8f\n', nativeVal);
fprintf('  Absolute difference:     %.2e\n', abs(double(importedVal) - double(nativeVal)));

if abs(double(importedVal) - double(nativeVal)) < 1e-5
    fprintf('  MATCH: Networks are equivalent.\n');
else
    fprintf('  WARNING: Networks differ! Check weight transfer.\n');
end

% Run 100-sample equivalence test
fprintf('\n  Running 100-sample equivalence test...\n');
tvFile = fullfile('..', 'test_vectors_100.mat');
if isfile(tvFile)
    tv = load(tvFile);
    maxErr = 0;
    for i = 1:size(tv.inputs, 1)
        x = single(reshape(tv.inputs(i,:,:), [1 10 5]));
        dlX = dlarray(x, 'BTC');
        y = extractdata(predict(net, dlX));
        err = abs(double(y) - double(tv.expected_outputs(i)));
        maxErr = max(maxErr, err);
    end
    fprintf('  100-sample max abs error: %.2e\n', maxErr);
    fprintf('  All < 1e-5: %s\n', iif(maxErr < 1e-5, 'YES', 'NO'));
end

%% Step 5: Inspect network for codegen compatibility
fprintf('\n[Step 5] Checking codegen compatibility...\n');
disp(net);
fprintf('\nLayer types:\n');
for i = 1:numel(net.Layers)
    fprintf('  [%d] %s (%s)\n', i, net.Layers(i).Name, class(net.Layers(i)));
end
fprintf('\nAll layers are native MATLAB layers - codegen should work.\n');

%% Step 6: Save network
fprintf('\n[Step 6] Saving network...\n');
save('soc_dlnetwork_native.mat', 'net');
fprintf('Network saved to soc_dlnetwork_native.mat\n');

%% Step 7: Configure and run code generation
fprintf('\n[Step 7] Configuring code generation...\n');

inputType = {coder.typeof(single(0), [10 5], [false false])};

% Use Embedded Coder for STM32 target
cfg = coder.config('lib', 'ecoder', true);
cfg.TargetLang = 'C';
cfg.GenerateReport = true;
cfg.LaunchReport = false;

% ARM Cortex-M hardware
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

outputDir = fullfile(pwd, 'codegen_output');

fprintf('\n[Step 8] Generating C code...\n');
try
    codegen -config cfg predict_soc_native -args inputType -d outputDir -report
    fprintf('\nCode generation SUCCESSFUL with Embedded Coder!\n');
    fprintf('Output: %s\n', outputDir);
catch ME
    fprintf('\nEmbedded Coder failed: %s\n', ME.message);

    % Try basic lib config
    fprintf('Retrying with basic lib config...\n');
    cfg2 = coder.config('lib');
    cfg2.TargetLang = 'C';
    cfg2.GenerateReport = true;
    cfg2.SupportNonFinite = false;

    try
        codegen -config cfg2 predict_soc_native -args inputType -d outputDir -report
        fprintf('Code generation SUCCESSFUL with lib config!\n');
    catch ME2
        fprintf('Basic lib also failed: %s\n', ME2.message);
    end
end

%% Step 9: Analyze generated code
fprintf('\n[Step 9] Analyzing generated code...\n');
if isfolder(outputDir)
    cFiles = dir(fullfile(outputDir, '**', '*.c'));
    hFiles = dir(fullfile(outputDir, '**', '*.h'));
    totalBytes = 0;
    totalLines = 0;
    fprintf('Generated files:\n');
    for i = 1:numel(cFiles)
        totalBytes = totalBytes + cFiles(i).bytes;
        txt = fileread(fullfile(cFiles(i).folder, cFiles(i).name));
        totalLines = totalLines + numel(strfind(txt, newline));
        fprintf('  %s (%d bytes, %d lines)\n', cFiles(i).name, cFiles(i).bytes, numel(strfind(txt, newline)));
    end
    for i = 1:numel(hFiles)
        totalBytes = totalBytes + hFiles(i).bytes;
    end
    fprintf('\nTotal: %d C files, %d H files\n', numel(cFiles), numel(hFiles));
    fprintf('Total source: %d bytes (%.1f KB), %d lines\n', totalBytes, totalBytes/1024, totalLines);
else
    fprintf('No output directory found.\n');
end

%% Step 10: Benchmark
fprintf('\n[Step 10] Benchmarking inference...\n');
nRuns = 1000;
tic;
for i = 1:nRuns
    dlY = predict(net, dlInput);
end
elapsed = toc;
fprintf('dlnetwork inference: %d runs in %.3f s (%.3f ms/run)\n', ...
    nRuns, elapsed, elapsed/nRuns*1000);

fprintf('\n=== Option 5 Complete ===\n');

function s = iif(c, t, f)
    if c, s = t; else, s = f; end
end

function tbl = setWeight(tbl, layerName, paramName, value)
    idx = strcmp(tbl.Layer, layerName) & strcmp(tbl.Parameter, paramName);
    tbl.Value{idx} = value;
end

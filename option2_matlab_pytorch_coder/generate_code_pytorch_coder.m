%% Option 2: Generate C Code Using MATLAB Coder Support Package for PyTorch
% =========================================================================
% This script uses MATLAB R2026a's Coder support package for PyTorch to
% generate optimized C code directly from a PyTorch ExportedProgram (.pt2).
%
% Target: STM32F746G-Discovery (ARM Cortex-M7, FPV5 FPU)
% Model:  SOC estimation LSTM (2-layer LSTM + dense head)
%
% Requirements:
%   - MATLAB R2026a
%   - MATLAB Coder
%   - Embedded Coder
%   - MATLAB Coder Support Package for PyTorch and LiteRT Models
%     (install via Add-On Explorer)
%
% Reference:
%   https://www.mathworks.com/help/releases/R2026a/coder/ug/
%   generate-code-and-deploy-a-LSTM-PyTorch-ExportedProgram-model.html
% =========================================================================

%% Setup
clear; clc;
fprintf('=== Option 2: PyTorch Coder Support Package ===\n');

% Path to the exported PyTorch model
modelPath = fullfile('..', 'soc_model.pt2');
assert(isfile(modelPath), 'Model file not found: %s', modelPath);

%% Step 1: Load the PyTorch ExportedProgram
fprintf('\n[Step 1] Loading PyTorch ExportedProgram...\n');

% loadPyTorchExportedProgram is provided by the Coder Support Package
model = loadPyTorchExportedProgram(modelPath);

fprintf('Model loaded successfully.\n');

% Inspect model
fprintf('\nModel summary:\n');
summary(model);

fprintf('\nInput specifications:\n');
inputSpecifications(model);

fprintf('\nOutput specifications:\n');
outputSpecifications(model);

%% Step 2: Validate model inference in MATLAB
fprintf('\n[Step 2] Validating model inference in MATLAB...\n');

% Create test input: single precision, [1, 10, 5]
testInput = single(randn(1, 10, 5));

% Run inference using invoke() — the correct API for ExportedProgram
socOutput = model.invoke(testInput);
fprintf('MATLAB inference result: %.6f\n', socOutput);
fprintf('Output size: %s\n', mat2str(size(socOutput)));

%% Step 3: Create entry-point function for code generation
% The entry-point uses a persistent variable to load the network once.
fprintf('\n[Step 3] Entry-point function: predict_soc.m\n');
fprintf('  (Already created as a separate file)\n');

%% Step 4: Configure code generation
fprintf('\n[Step 4] Configuring code generation...\n');

% Define input types: the model object + input tensor
inputType = {model, coder.typeof(single(0), [1 10 5], [false false false])};

% Use Embedded Coder for STM32 deployment
cfg = coder.config('lib', 'ecoder', true);
cfg.TargetLang = 'C';
cfg.GenerateReport = true;
cfg.LaunchReport = false;

% STM32F746G-Discovery hardware board
% (Requires Embedded Coder Support Package for STMicroelectronics STM32)
try
    cfg.Hardware = coder.hardware('STM32F746G-Discovery');
    fprintf('  Hardware board: STM32F746G-Discovery (auto-configured)\n');
catch
    % Fall back to generic ARM Cortex-M if board support not installed
    fprintf('  STM32 board support not installed; using generic ARM Cortex-M.\n');
    cfg.HardwareImplementation.ProdHWDeviceType = 'ARM Compatible->ARM Cortex-M';
    cfg.HardwareImplementation.ProdBitPerChar = 8;
    cfg.HardwareImplementation.ProdBitPerShort = 16;
    cfg.HardwareImplementation.ProdBitPerInt = 32;
    cfg.HardwareImplementation.ProdBitPerLong = 32;
    cfg.HardwareImplementation.ProdBitPerFloat = 32;
    cfg.HardwareImplementation.ProdBitPerDouble = 64;
end

% Optimization settings for embedded
cfg.SupportNonFinite = false;
cfg.PreserveVariableNames = 'None';
cfg.InlineBetweenUserFunctions = 'Always';
cfg.InlineBetweenMathWorksFunctions = 'Always';

% Deep learning config: pure C, no external library
dlcfg = coder.DeepLearningConfig('none');
cfg.DeepLearningConfig = dlcfg;

% Keep model weights inline in source files (avoids separate data file)
cfg.LargeConstantGeneration = 'KeepInSourceFiles';

% Constrain stack usage for MCU target
cfg.StackUsageMax = 4096;

% Output directory
outputDir = fullfile(pwd, 'codegen_output');

fprintf('Code generation configuration:\n');
fprintf('  Target language:  C\n');
fprintf('  Target hardware:  ARM Cortex-M7\n');
fprintf('  Stack limit:      4096 bytes\n');
fprintf('  Output directory: %s\n', outputDir);

%% Step 5: Generate C code
fprintf('\n[Step 5] Generating C code...\n');
fprintf('This may take several minutes...\n');

try
    codegen -config cfg predict_soc -args inputType -d outputDir -report
    fprintf('\nCode generation SUCCESSFUL!\n');
    fprintf('Output directory: %s\n', outputDir);
catch ME
    fprintf('\nCode generation FAILED:\n');
    fprintf('  Error: %s\n', ME.message);
    fprintf('  Identifier: %s\n', ME.identifier);

    % Try alternative approach with LiteRT backend if available
    fprintf('\nAttempting with LiteRT/TFLite backend...\n');
    try
        dlcfg2 = coder.DeepLearningConfig('litert');
        cfg.DeepLearningConfig = dlcfg2;
        codegen -config cfg predict_soc -args inputType -d outputDir -report
        fprintf('Code generation with LiteRT backend SUCCESSFUL!\n');
    catch ME2
        fprintf('LiteRT backend also failed: %s\n', ME2.message);
        fprintf('\nPlease check:\n');
        fprintf('  1. MATLAB Coder Support Package for PyTorch is installed\n');
        fprintf('     (Add-On Explorer -> "MATLAB Coder Support Package for\n');
        fprintf('      PyTorch and LiteRT Models")\n');
        fprintf('  2. The model file is a valid .pt2 ExportedProgram\n');
        fprintf('  3. Required toolboxes are licensed:\n');
        fprintf('     ver(''coder''), ver(''ecoder'')\n');
    end
end

%% Step 6: Analyze generated code
fprintf('\n[Step 6] Analyzing generated code...\n');
if isfolder(outputDir)
    cFiles = dir(fullfile(outputDir, '**', '*.c'));
    hFiles = dir(fullfile(outputDir, '**', '*.h'));
    fprintf('Generated files:\n');
    fprintf('  C files:  %d\n', numel(cFiles));
    fprintf('  H files:  %d\n', numel(hFiles));

    totalLines = 0;
    totalBytes = 0;
    for i = 1:numel(cFiles)
        fpath = fullfile(cFiles(i).folder, cFiles(i).name);
        totalBytes = totalBytes + cFiles(i).bytes;
        txt = fileread(fpath);
        totalLines = totalLines + numel(strfind(txt, newline));
        fprintf('    %s (%d bytes)\n', cFiles(i).name, cFiles(i).bytes);
    end
    for i = 1:numel(hFiles)
        totalBytes = totalBytes + hFiles(i).bytes;
        fprintf('    %s (%d bytes)\n', hFiles(i).name, hFiles(i).bytes);
    end

    fprintf('\nTotal source size: %d bytes (%.1f KB)\n', totalBytes, totalBytes/1024);
    fprintf('Total lines of C code: %d\n', totalLines);
end

%% Step 7: Benchmark (MATLAB-side timing)
fprintf('\n[Step 7] Benchmarking MATLAB inference...\n');
nRuns = 1000;
tic;
for i = 1:nRuns
    socOutput = model.invoke(testInput);
end
elapsed = toc;
fprintf('MATLAB inference: %d runs in %.3f s (%.3f ms/inference)\n', ...
    nRuns, elapsed, elapsed/nRuns*1000);

%% Step 8: PIL verification (optional — requires board connection)
fprintf('\n[Step 8] PIL Verification (optional)\n');
fprintf('  To verify on hardware, connect STM32F746G-Discovery via USB and run:\n');
fprintf('    cfg.VerificationMode = ''PIL'';\n');
fprintf('    cfg.Hardware.PILInterface = ''Serial'';\n');
fprintf('    cfg.Hardware.PILCOMPort = ''<your COM port>'';\n');
fprintf('  Then re-run codegen. MATLAB will flash the board and compare\n');
fprintf('  the on-target output against MATLAB reference results.\n');

fprintf('\n=== Option 2 Complete ===\n');

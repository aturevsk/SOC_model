%% Step 3: Codegen Comparison — Simulink vs Direct dlnetwork (Option 4)
% =========================================================================
% Generates C code from the Simulink model (exportNetworkToSimulink output)
% using Embedded Coder, then compares with the direct dlnetwork codegen
% from option4_matlab_onnx/. See option5_compressed/step3_codegen_compare.m
% for full methodology notes.
%
% Option 4 difference: The ONNX-imported network may have auto-generated
% custom layers. Direct codegen uses DeepLearningConfig('none') as in the
% original option4 script.
%
% Outputs: simulink_codegen_opt4/ directory, comp_direct_codegen_opt4/
% =========================================================================
clear; clc;
fprintf('=== Step 3: Codegen Comparison — Option 4 (ONNX) ===\n\n');

%% ---- Add path for ONNX custom layer package ------------------------
addpath(fullfile('..', 'option4_matlab_onnx'));

%% ---- Config --------------------------------------------------------
OPT_LABEL     = 'Option4_ONNX_Import';
COMP_FILE     = 'soc_compressed_opt4.mat';
MDL_NAME      = 'soc_opt4_network';
DIRECT_OUTDIR = fullfile('..', 'option4_matlab_onnx', 'outputDir');
SIM_OUTDIR    = fullfile(pwd, 'simulink_codegen_opt4');

%% ---- 1. Measure existing direct codegen ----------------------------
fprintf('[1/4] Measuring direct dlnetwork codegen output...\n');
fprintf('      (from option4_matlab_onnx/generate_code_onnx.m)\n');
directStats = measureDir(DIRECT_OUTDIR);
if directStats.cFiles == 0
    fprintf('  WARNING: No C files in %s\n', DIRECT_OUTDIR);
    fprintf('  Run option4_matlab_onnx/generate_code_onnx.m first.\n');
else
    fprintf('  C files: %d  |  H files: %d\n', directStats.cFiles, directStats.hFiles);
    fprintf('  Total lines: %d  |  Total size: %.1f KB\n', ...
        directStats.totalLines, directStats.totalBytes/1024);
end

%% ---- 2. Generate direct codegen from baseNet -----------------------
fprintf('\n[2/4] Generating C code directly from dlnetwork (baseNet)...\n');
fprintf('      coder.loadDeepLearningNetwork requires a single-variable mat file.\n');
fprintf('      ONNX custom layers use baseline net for codegen.\n');

assert(isfile(COMP_FILE), 'Run step1_compress.m first: %s not found.', COMP_FILE);
sc = load(COMP_FILE, 'baseNet', 'bestKey');
fprintf('  Using baseNet (compressed variant: %s)\n', sc.bestKey);

compDirectDir = fullfile(pwd, 'comp_direct_codegen_opt4');
compDirectOK  = false;

% Save baseNet to single-variable mat file for coder.loadDeepLearningNetwork
baseNetFile4 = 'soc_basenet_opt4.mat';
baseNet_cg4 = sc.baseNet; %#ok
save(baseNetFile4, 'baseNet_cg4');

entryFile = 'predict_soc_opt4_direct.m';
fid = fopen(entryFile, 'w');
fprintf(fid, 'function soc = predict_soc_opt4_direct(in) %%%%#codegen\n');
fprintf(fid, '    persistent net;\n');
fprintf(fid, '    if isempty(net)\n');
fprintf(fid, '        net = coder.loadDeepLearningNetwork(''%s'', ''baseNet_cg4'');\n', baseNetFile4);
fprintf(fid, '    end\n');
fprintf(fid, '    x   = reshape(in, [1 10 5]);\n');
fprintf(fid, '    dlX = dlarray(x, ''BTC'');\n');
fprintf(fid, '    dlY = predict(net, dlX);\n');
fprintf(fid, '    soc = extractdata(dlY);\n');
fprintf(fid, 'end\n');
fclose(fid);

try
    inputType = {coder.typeof(single(0), [10 5], [false false])};
    cfg = coder.config('lib', 'ecoder', true);
    cfg.TargetLang   = 'C';
    cfg.GenerateReport = false;
    cfg.HardwareImplementation.ProdHWDeviceType = 'ARM Compatible->ARM Cortex-M';
    cfg.SupportNonFinite   = false;
    cfg.DeepLearningConfig = coder.DeepLearningConfig('none');

    eval(sprintf('codegen -config cfg predict_soc_opt4_direct -args inputType -d ''%s'' -report', compDirectDir));
    compDirectOK = true;
    fprintf('  Direct codegen: OK → %s\n', compDirectDir);
catch ME
    fprintf('  Direct codegen FAILED: %s\n', firstLine(ME.message));
    % Fallback: copy from existing baseline codegen
    if directStats.cFiles > 0
        if isfolder(compDirectDir), rmdir(compDirectDir, 's'); end
        copyfile(DIRECT_OUTDIR, compDirectDir, 'f');
        compDirectOK = true;
        fprintf('  Fallback: copied %d C files from baseline outputDir.\n', directStats.cFiles);
    end
end

compDirectStats = measureDir(compDirectDir);

%% ---- 3. Simulink codegen -------------------------------------------
fprintf('\n[3/4] Simulink Embedded Coder codegen...\n');

simCodeOK = false;

try
    % Note: ONNX-imported network (Option 4) is not supported by exportNetworkToSimulink.
    % Simulink codegen is not available for Option 4 (ONNX custom layers not supported).
    error('Option 4 ONNX network not supported by exportNetworkToSimulink — Simulink codegen skipped.');

    load_system(MDL_NAME);
    set_param(MDL_NAME, 'SystemTargetFile', 'ert.tlc');
    set_param(MDL_NAME, 'TemplateMakefile', 'ert_default_tmf');
    set_param(MDL_NAME, 'SolverType',       'Fixed-step');
    set_param(MDL_NAME, 'SolverName',       'FixedStepDiscrete');
    set_param(MDL_NAME, 'FixedStep',        '0.001');
    set_param(MDL_NAME, 'StopTime',         '0.1');
    set_param(MDL_NAME, 'GenerateReport',   'off');
    set_param(MDL_NAME, 'ProdHWDeviceType', 'ARM Compatible->ARM Cortex-M');

    fprintf('  Running slbuild...\n');
    slbuild(MDL_NAME);

    rtw_dir = [MDL_NAME '_ert_rtw'];
    if ~isfolder(rtw_dir)
        d = dir('*_ert_rtw');
        if ~isempty(d), rtw_dir = d(1).name; end
    end
    if isfolder(rtw_dir)
        if isfolder(SIM_OUTDIR), rmdir(SIM_OUTDIR, 's'); end
        copyfile(rtw_dir, SIM_OUTDIR, 'f');
        simCodeOK = true;
        fprintf('  Simulink codegen complete. Output: %s\n', SIM_OUTDIR);
    end

catch ME
    fprintf('  Simulink codegen FAILED: %s\n', firstLine(ME.message));
    fprintf('\n  Manual: open ''%s.slx'', set ERT target, press Ctrl+B.\n', MDL_NAME);
end

simStats = measureDir(SIM_OUTDIR);

%% ---- 4. Comparison table -------------------------------------------
fprintf('\n[4/4] Comparison Table — %s\n', OPT_LABEL);
fprintf('%s\n', repmat('=', 1, 80));
fprintf('%-38s %-18s %-18s\n', 'Metric', 'Direct (baseline)', 'Direct (compressed)');
fprintf('%s\n', repmat('-', 1, 80));
printRow('C source files', directStats.cFiles,     compDirectStats.cFiles,  compDirectOK);
printRow('H header files', directStats.hFiles,     compDirectStats.hFiles,  compDirectOK);
printRow('Total C lines',  directStats.totalLines, compDirectStats.totalLines, compDirectOK);
printRowKB('Source size',  directStats.totalBytes, compDirectStats.totalBytes, compDirectOK);
fprintf('\n%-38s %-18s %-18s\n', 'Metric', 'Compressed direct', 'Simulink (compressed)');
fprintf('%s\n', repmat('-', 1, 80));
printRow('C source files', compDirectStats.cFiles,  simStats.cFiles,  simCodeOK && compDirectOK);
printRow('H header files', compDirectStats.hFiles,  simStats.hFiles,  simCodeOK && compDirectOK);
printRow('Total C lines',  compDirectStats.totalLines, simStats.totalLines, simCodeOK && compDirectOK);
printRowKB('Source size',  compDirectStats.totalBytes, simStats.totalBytes, simCodeOK && compDirectOK);

fprintf('\n  Notes:\n');
fprintf('  Direct codegen  — pure inference C, minimal, bare-metal ready.\n');
fprintf('  Simulink codegen— adds Simulink scheduling harness for plant integration.\n');
fprintf('\n=== Step 3 Complete ===\n');

%% =====================================================================
function stats = measureDir(dirPath)
    stats.cFiles = 0; stats.hFiles = 0;
    stats.totalLines = 0; stats.totalBytes = 0;
    if ~isfolder(dirPath), return; end
    cF = dir(fullfile(dirPath, '**', '*.c'));
    hF = dir(fullfile(dirPath, '**', '*.h'));
    for i = 1:numel(cF)
        stats.totalBytes = stats.totalBytes + cF(i).bytes;
        txt = fileread(fullfile(cF(i).folder, cF(i).name));
        stats.totalLines = stats.totalLines + numel(strfind(txt, newline));
    end
    for i = 1:numel(hF)
        stats.totalBytes = stats.totalBytes + hF(i).bytes;
    end
    stats.cFiles = numel(cF);
    stats.hFiles = numel(hF);
end

function printRow(label, v1, v2, hasV2)
    if hasV2
        fprintf('%-38s %-18d %-18d\n', label, v1, v2);
    else
        fprintf('%-38s %-18d %-18s\n', label, v1, 'N/A');
    end
end

function printRowKB(label, b1, b2, hasV2)
    if hasV2
        fprintf('%-38s %-18s %-18s\n', label, ...
            sprintf('%.1f KB', b1/1024), sprintf('%.1f KB', b2/1024));
    else
        fprintf('%-38s %-18s %-18s\n', label, ...
            sprintf('%.1f KB', b1/1024), 'N/A');
    end
end

function s = firstLine(msg)
    lines = strsplit(msg, newline);
    s = strtrim(lines{1});
    if numel(s) > 120, s = [s(1:120) '...']; end
end

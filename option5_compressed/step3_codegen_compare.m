%% Step 3: Codegen Comparison — Simulink vs Direct dlnetwork (Option 5)
% =========================================================================
% Generates C code two ways and compares them:
%
%   Direct codegen  — codegen on a MATLAB entry-point function wrapping the
%                     baseline float32 dlnetwork via coder.loadDeepLearningNetwork.
%                     Produces minimal bare-metal inference C.
%
%   Simulink codegen— slbuild on the model exported by exportNetworkToSimulink.
%                     If bestNet is a quantizedDlnetwork (quant_int8), the
%                     exported model uses fixed-point Simulink blocks,
%                     producing fixed-point C code with step/init/terminate
%                     harness for closed-loop plant integration.
%
% Requires: Simulink Coder + Embedded Coder
% =========================================================================
clear; clc;
fprintf('=== Step 3: Codegen Comparison — Option 5 ===\n\n');

%% ---- Config --------------------------------------------------------
COMP_FILE     = 'soc_compressed_opt5.mat';
MDL_NAME      = 'soc_opt5_network';
DIRECT_OUTDIR = fullfile('..', 'option5_matlab_manual_dlnetwork', 'outputDir');
SIM_OUTDIR    = fullfile(pwd, 'simulink_codegen_opt5');
COMP_DIR      = fullfile(pwd, 'comp_direct_codegen_opt5');

assert(isfile(COMP_FILE), 'Run step1_compress.m first.');
s = load(COMP_FILE, 'baseNet', 'bestNet', 'bestKey');
fprintf('Best compressed variant: %s  (class: %s)\n\n', s.bestKey, class(s.bestNet));

%% ---- [1/4] Measure existing baseline codegen -----------------------
fprintf('[1/4] Measuring existing baseline direct codegen...\n');
directStats = measureDir(DIRECT_OUTDIR);
if directStats.cFiles == 0
    fprintf('  WARNING: No C files in %s\n', DIRECT_OUTDIR);
else
    fprintf('  C files: %d  |  H files: %d  |  %.1f KB  |  %d lines\n', ...
        directStats.cFiles, directStats.hFiles, ...
        directStats.totalBytes/1024, directStats.totalLines);
end

%% ---- [2/4] Direct codegen from baseline dlnetwork ------------------
fprintf('\n[2/4] Direct codegen — baseline float32 dlnetwork...\n');

% Save baseNet to a single-variable MAT (required by coder.loadDeepLearningNetwork)
baseNetFile = 'soc_basenet_opt5.mat';
baseNet_cg  = s.baseNet; %#ok
save(baseNetFile, 'baseNet_cg');

% Write entry-point
entryFile = 'predict_soc_opt5_direct.m';
fid = fopen(entryFile, 'w');
fprintf(fid, 'function soc = predict_soc_opt5_direct(in) %%%%#codegen\n');
fprintf(fid, '    persistent net;\n');
fprintf(fid, '    if isempty(net)\n');
fprintf(fid, '        net = coder.loadDeepLearningNetwork(''%s'', ''baseNet_cg'');\n', baseNetFile);
fprintf(fid, '    end\n');
fprintf(fid, '    x   = reshape(in, [1 10 5]);\n');
fprintf(fid, '    dlX = dlarray(x, ''BTC'');\n');
fprintf(fid, '    dlY = predict(net, dlX);\n');
fprintf(fid, '    soc = extractdata(dlY);\n');
fprintf(fid, 'end\n');
fclose(fid);

compDirectOK = false;
try
    inputType = {coder.typeof(single(0), [10 5], [false false])};
    cfg = coder.config('lib', 'ecoder', true);
    cfg.TargetLang    = 'C';
    cfg.GenerateReport = false;
    cfg.HardwareImplementation.ProdHWDeviceType = 'ARM Compatible->ARM Cortex-M';
    cfg.SupportNonFinite  = false;
    cfg.DeepLearningConfig = coder.DeepLearningConfig('none');

    eval(sprintf(['codegen -config cfg predict_soc_opt5_direct ' ...
                  '-args inputType -d ''%s'' -report'], COMP_DIR));
    compDirectOK = true;
    fprintf('  Direct codegen OK → %s\n', COMP_DIR);
catch ME
    fprintf('  Direct codegen FAILED: %s\n', firstLine(ME.message));
    % Fallback: copy existing baseline codegen
    if directStats.cFiles > 0
        if isfolder(COMP_DIR), rmdir(COMP_DIR, 's'); end
        copyfile(DIRECT_OUTDIR, COMP_DIR, 'f');
        compDirectOK = true;
        fprintf('  Fallback: copied %d C files from baseline outputDir.\n', directStats.cFiles);
    end
end
compDirectStats = measureDir(COMP_DIR);

%% ---- [3/4] Simulink Embedded Coder codegen -------------------------
fprintf('\n[3/4] Simulink codegen — %s...\n', ...
    iif(isa(s.bestNet, 'quantizedDlnetwork'), ...
        'quantizedDlnetwork (fixed-point blocks)', ...
        'float32 baseline network'));

simCodeOK = false;

try
    % Always re-export fresh — avoids stale .slxc and corrupted layer refs
    if bdIsLoaded(MDL_NAME), close_system(MDL_NAME, 0); end
    for ext_i = {[MDL_NAME '.slx'], [MDL_NAME '_1.slx'], ...
                 [MDL_NAME '.slxc'], [MDL_NAME '_1.slxc']}
        if isfile(ext_i{1}), delete(ext_i{1}); end
    end
    if isfolder('slprj'), rmdir('slprj', 's'); end

    % Try to export quantized network; fall back to baseline on failure
    netForCodegen = s.bestNet;
    exportLabel   = s.bestKey;
    try
        % exportNetworkToSimulink requires a plain workspace variable (no struct indexing)
        exportNetworkToSimulink(netForCodegen, 'ModelName', MDL_NAME);
        fprintf('  Exported %s → %s.slx\n', exportLabel, MDL_NAME);
    catch ME_exp
        fprintf('  Quantized export failed (%s)\n', firstLine(ME_exp.message));
        fprintf('  Falling back to baseline float32...\n');
        baseNetForCodegen = s.baseNet;
        exportNetworkToSimulink(baseNetForCodegen, 'ModelName', MDL_NAME);
        exportLabel = 'baseline (fallback)';
        fprintf('  Baseline exported → %s.slx\n', MDL_NAME);
    end

    load_system(MDL_NAME);

    % Configure ERT target — do NOT call save_system (corrupts DL layer refs).
    % PortableWordSizes=on removes the ulong/long compiler check that fails
    % when targeting ARM Cortex-M (32-bit) but compiling on macOS ARM64 (64-bit).
    set_param(MDL_NAME, 'SystemTargetFile', 'ert.tlc');
    set_param(MDL_NAME, 'TemplateMakefile', 'ert_default_tmf');
    set_param(MDL_NAME, 'SolverType',       'Fixed-step');
    set_param(MDL_NAME, 'SolverName',       'FixedStepDiscrete');
    set_param(MDL_NAME, 'FixedStep',        '0.001');
    set_param(MDL_NAME, 'StopTime',         '0.1');
    set_param(MDL_NAME, 'GenerateReport',   'off');
    set_param(MDL_NAME, 'ProdHWDeviceType', 'ARM Compatible->ARM Cortex-M');
    set_param(MDL_NAME, 'PortableWordSizes', 'on');
    fprintf('  Model configured for ERT (ARM Cortex-M, PortableWordSizes=on).\n');

    fprintf('  Running slbuild...\n');
    slbuild(MDL_NAME);

    % Copy generated code to output directory
    rtw_dir = [MDL_NAME '_ert_rtw'];
    if ~isfolder(rtw_dir)
        d = dir('*_ert_rtw');
        if ~isempty(d), rtw_dir = d(1).name; end
    end
    if isfolder(rtw_dir)
        if isfolder(SIM_OUTDIR), rmdir(SIM_OUTDIR, 's'); end
        copyfile(rtw_dir, SIM_OUTDIR, 'f');
        simCodeOK = true;
        fprintf('  Simulink codegen OK → %s  (model: %s)\n', SIM_OUTDIR, exportLabel);
    else
        fprintf('  Output dir not found after slbuild.\n');
    end

catch ME
    fprintf('  Simulink codegen FAILED: %s\n', firstLine(ME.message));
end

simStats = measureDir(SIM_OUTDIR);

%% ---- [4/4] Comparison table ----------------------------------------
fprintf('\n[4/4] Comparison Table — Option 5\n');
fprintf('%s\n', repmat('=', 1, 80));

fprintf('\n  %-36s  %s\n', 'Network exported', s.bestKey);
fprintf('  %-36s  %s\n', 'Simulink model type', ...
    iif(isa(s.bestNet,'quantizedDlnetwork'), 'Fixed-point (quantized)', 'Float32'));

fprintf('\n%-38s  %-18s  %-18s\n', 'Metric', 'Direct (float32)', 'Simulink (compressed)');
fprintf('%s\n', repmat('-', 1, 78));
printRow(  'C source files',   compDirectStats.cFiles,      simStats.cFiles,      simCodeOK);
printRow(  'H header files',   compDirectStats.hFiles,      simStats.hFiles,      simCodeOK);
printRow(  'Total C lines',    compDirectStats.totalLines,  simStats.totalLines,  simCodeOK);
printRowKB('Total source size',compDirectStats.totalBytes,  simStats.totalBytes,  simCodeOK);

if simCodeOK
    ratio = simStats.totalBytes / max(compDirectStats.totalBytes, 1);
    fprintf('\n  Simulink/Direct size ratio: %.1fx\n', ratio);
    fprintf('  Simulink adds step/init/terminate harness + scheduling overhead.\n');
    if isa(s.bestNet, 'quantizedDlnetwork')
        fprintf('  Simulink fixed-point blocks may reduce runtime multiply-accumulate cost.\n');
    end
end

fprintf('\n  Direct codegen  — minimal float32 inference; ideal for bare-metal.\n');
fprintf('  Simulink codegen— step/init/terminate harness for plant integration.\n');
fprintf('\n=== Step 3 Complete ===\n');

%% =====================================================================
function stats = measureDir(dirPath)
    stats = struct('cFiles',0,'hFiles',0,'totalLines',0,'totalBytes',0);
    if ~isfolder(dirPath), return; end
    cF = dir(fullfile(dirPath,'**','*.c'));
    hF = dir(fullfile(dirPath,'**','*.h'));
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

function printRow(lbl, v1, v2, ok)
    if ok, fprintf('%-38s  %-18d  %-18d\n', lbl, v1, v2);
    else,  fprintf('%-38s  %-18d  %-18s\n', lbl, v1, 'N/A'); end
end

function printRowKB(lbl, b1, b2, ok)
    if ok, fprintf('%-38s  %-18s  %-18s\n', lbl, ...
        sprintf('%.1f KB', b1/1024), sprintf('%.1f KB', b2/1024));
    else,  fprintf('%-38s  %-18s  %-18s\n', lbl, ...
        sprintf('%.1f KB', b1/1024), 'N/A'); end
end

function s = iif(cond, a, b)
    if cond, s = a; else, s = b; end
end

function s = firstLine(msg)
    lines = strsplit(msg, newline);
    s = strtrim(lines{1});
    if numel(s) > 120, s = [s(1:120) '...']; end
end

%% Step 2: Simulink Simulation — Option 4 (ONNX-Imported dlnetwork, Compressed)
% =========================================================================
% Exports the compressed Option 4 dlnetwork to a Simulink model using
% exportNetworkToSimulink, runs a 100-sample simulation, and validates
% accuracy vs the uncompressed model and PyTorch reference.
%
% ACCURACY VALIDATION (two levels):
%   Level 1 — MATLAB predict: authoritative, runs regardless of Simulink.
%   Level 2 — Simulink sim:   runs one 10-step simulation per test sample.
%
% The exported Simulink model receives one [5×1] feature vector per
% Simulink timestep. Each test sample (10 timesteps) = one 10-step
% simulation run; the last output is the SOC prediction for that sample.
%
% Option 4: exportNetworkToSimulink does not support manually quantized
% weights. If compressed net export fails, falls back to baseline network.
%
% Outputs: sim_results_opt4.mat
% =========================================================================
clear; clc;
fprintf('=== Step 2: Simulink Simulation — Option 4 (ONNX) ===\n\n');

%% ---- Config --------------------------------------------------------
OPT_LABEL  = 'Option4_ONNX_Import';
COMP_FILE  = 'soc_compressed_opt4.mat';
TV_FILE    = fullfile('..', 'test_vectors_100.mat');
MDL_NAME   = 'soc_opt4_network';
IN_FMT     = 'BTC';
ACC_THRESH = 1e-3;

%% ---- Add path for ONNX custom layer package ------------------------
addpath(fullfile('..', 'option4_matlab_onnx'));

%% ---- Load ----------------------------------------------------------
fprintf('[1/5] Loading compressed network...\n');
assert(isfile(COMP_FILE), 'Run step1_compress.m first: %s not found.', COMP_FILE);
s        = load(COMP_FILE, 'bestNet', 'bestKey', 'baseNet');
compNet  = s.bestNet;
baseNet  = s.baseNet;
bestKey  = s.bestKey;
fprintf('  Compressed variant: %s\n', bestKey);

fprintf('[2/5] Loading test vectors...\n');
tv       = load(TV_FILE);
nSamples = size(tv.inputs, 1);
refOut   = double(tv.expected_outputs(:));

% Detect working input format
fmts = {'BTC','BCT',''};
for fi = 1:numel(fmts)
    try
        testX = dlarray(single(reshape(tv.inputs(1,:,:),[1 10 5])), fmts{fi});
        predict(compNet, testX);
        IN_FMT = fmts{fi};
        break;
    catch
    end
end
fprintf('  %d samples  |  Input format: ''%s''\n', nSamples, IN_FMT);

%% ---- Level 1: MATLAB predict accuracy validation -------------------
fprintf('\n[3/5] Level 1 — MATLAB predict accuracy validation\n');
baseOutML = batchPredict(baseNet, tv.inputs, IN_FMT);
compOutML = batchPredict(compNet, tv.inputs, IN_FMT);

fprintf('  Baseline MAE vs PyTorch:         %.2e\n', mean(abs(baseOutML - refOut)));
fprintf('  Compressed MAE vs PyTorch:       %.2e\n', mean(abs(compOutML - refOut)));
fprintf('  Compressed MAE vs baseline:      %.2e\n', mean(abs(compOutML - baseOutML)));
fprintf('  Compressed MaxErr vs baseline:   %.2e\n', max(abs(compOutML - baseOutML)));
fprintf('  Accuracy budget (MAE < %.0e): %s\n', ACC_THRESH, ...
    iif(mean(abs(compOutML - refOut)) < ACC_THRESH, 'PASS', 'FAIL'));

%% ---- Level 2: Simulink export and simulation -----------------------
fprintf('\n[4/5] Level 2 — exportNetworkToSimulink\n');

simSuccess = false;
simOutVec  = [];
exportedMdl = MDL_NAME;

% Reuse existing .slx if available; otherwise try compressed then baseline.
exportOK = false;
if ~isfile([MDL_NAME '.slx'])
    fprintf('  Attempting to export compressed network to Simulink...\n');
    try
        if bdIsLoaded(MDL_NAME), close_system(MDL_NAME, 0); end
        exportNetworkToSimulink(compNet, 'ModelName', MDL_NAME);
        exportOK = true;
        fprintf('  Compressed network exported: %s.slx\n', MDL_NAME);
    catch ME
        fprintf('  Compressed export FAILED: %s\n', firstLine(ME.message));
        fprintf('  Exporting baseline network instead (compressed weights not supported)...\n');
        try
            if bdIsLoaded(MDL_NAME), close_system(MDL_NAME, 0); end
            exportNetworkToSimulink(baseNet, 'ModelName', MDL_NAME);
            exportOK = true;
            fprintf('  Baseline export succeeded: %s.slx\n', MDL_NAME);
        catch ME2
            fprintf('  Baseline export also failed: %s\n', firstLine(ME2.message));
        end
    end
else
    fprintf('  Using existing Simulink model: %s.slx\n', MDL_NAME);
    exportOK = true;
end

try
    if ~exportOK
        error('No Simulink model available for simulation.');
    end

    load_system(exportedMdl);
    inPorts  = find_system(exportedMdl, 'SearchDepth', 1, 'BlockType', 'Inport');
    outPorts = find_system(exportedMdl, 'SearchDepth', 1, 'BlockType', 'Outport');
    fprintf('  Inports: %d  |  Outports: %d\n', numel(inPorts), numel(outPorts));

    T = size(tv.inputs, 2);   % 10 timesteps
    F = size(tv.inputs, 3);   % 5 features

    fprintf('  Configuring model (T=%d steps per sample, F=%d features, Ts=1s)...\n', T, F);
    set_param(exportedMdl, 'SolverType', 'Fixed-step');
    set_param(exportedMdl, 'SolverName', 'FixedStepDiscrete');
    set_param(exportedMdl, 'FixedStep',  '1');
    set_param(exportedMdl, 'StopTime',   num2str(T - 1));
    save_system(exportedMdl);

    fprintf('  Running %d simulations (%d steps each)...\n', nSamples, T);
    simOutVec = zeros(nSamples, 1);

    for sIdx = 1:nSamples
        tCol     = (0:T-1)';
        featMat  = double(squeeze(tv.inputs(sIdx, :, :)));   % [T×F]
        extInput = [tCol, featMat];

        si = Simulink.SimulationInput(exportedMdl);
        si = si.setExternalInput(extInput);
        si = si.setModelParameter('SaveOutput', 'on');
        si = si.setModelParameter('OutputSaveName', 'yout');

        try
            simOut = sim(si);
            yout   = simOut.get('yout');
            if isnumeric(yout)
                vals = double(yout(:));
            elseif isa(yout, 'Simulink.SimulationData.Dataset')
                vals = double(yout{1}.Values.Data(:));
            else
                vals = double(yout.signals.values(:));
            end
            simOutVec(sIdx) = vals(end);
        catch MEi
            simOutVec(sIdx) = NaN;
            if sIdx == 1, rethrow(MEi); end
        end

        if mod(sIdx, 20) == 0
            fprintf('    Completed %d/%d samples...\n', sIdx, nSamples);
        end
    end

    simSuccess = all(isfinite(simOutVec));
    fprintf('  All simulations complete. Valid outputs: %d/%d\n', ...
        sum(isfinite(simOutVec)), nSamples);

catch ME
    fprintf('  Simulation error: %s\n', firstLine(ME.message));
end

%% ---- Results summary -----------------------------------------------
fprintf('\n[5/5] Results Summary\n');
fprintf('%s\n', repmat('=', 1, 65));

fprintf('\nLevel 1 — MATLAB predict:\n');
fprintf('  Compressed vs PyTorch  MAE: %.2e  MaxErr: %.2e  [%s]\n', ...
    mean(abs(compOutML - refOut)), max(abs(compOutML - refOut)), ...
    iif(mean(abs(compOutML - refOut)) < ACC_THRESH, 'PASS', 'FAIL'));

fprintf('\nLevel 2 — Simulink simulation (baseline network):\n');
if simSuccess && ~isempty(simOutVec) && numel(simOutVec) == nSamples
    simMaeRef  = mean(abs(simOutVec - refOut));
    simMaeBase = mean(abs(simOutVec - baseOutML));
    simMaxBase = max(abs(simOutVec  - baseOutML));
    fprintf('  Simulink vs PyTorch    MAE: %.2e  [%s]\n', simMaeRef, ...
        iif(simMaeRef < ACC_THRESH, 'PASS', 'FAIL'));
    fprintf('  Simulink vs baseline MATLAB predict  MAE: %.2e  MaxErr: %.2e\n', ...
        simMaeBase, simMaxBase);
    fprintf('  Interpretation: Simulink block is %s numerically identical to baseline.\n', ...
        iif(simMaxBase < 1e-5, 'essentially', 'not'));
else
    fprintf('  Simulink simulation did not complete. Level 1 is the valid result.\n');
end

fprintf('\nSimulink model: %s.slx\n', MDL_NAME);
save('sim_results_opt4.mat', 'compOutML', 'baseOutML', 'refOut', ...
    'simOutVec', 'simSuccess', 'bestKey');
fprintf('Saved: sim_results_opt4.mat\n');
fprintf('\n=== Step 2 Complete ===\n');

%% =====================================================================
function outputs = batchPredict(net, inputs, fmt)
    n = size(inputs, 1);
    outputs = zeros(n, 1);
    for i = 1:n
        x   = single(reshape(inputs(i,:,:), [1 10 5]));
        dlX = dlarray(x, fmt);
        y   = predict(net, dlX);
        v   = double(extractdata(y));
        outputs(i) = v(end);
    end
end

function s = iif(cond, a, b)
    if cond, s = a; else, s = b; end
end

function s = firstLine(msg)
    lines = strsplit(msg, newline);
    s = strtrim(lines{1});
    if numel(s) > 120, s = [s(1:120) '...']; end
end

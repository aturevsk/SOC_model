%% Step 2: Simulink Simulation — Option 5 (Compressed Network)
% =========================================================================
% Exports the compressed network to Simulink using exportNetworkToSimulink,
% then runs a 100-sample simulation and validates accuracy vs PyTorch.
%
% bestNet is now a quantizedDlnetwork (from dlquantizer + prepareNetwork),
% which exportNetworkToSimulink supports directly with fixed-point blocks.
% The Simulink model therefore simulates the actual quantized inference,
% not just the float32 baseline.
%
% ACCURACY VALIDATION (two levels):
%   Level 1 — MATLAB predict: authoritative, runs regardless of Simulink.
%   Level 2 — Simulink sim:   verifies quantized Simulink block matches.
%
% Outputs: sim_results_opt5.mat
% =========================================================================
clear; clc;
fprintf('=== Step 2: Simulink Simulation — Option 5 ===\n\n');

%% ---- Config --------------------------------------------------------
COMP_FILE  = 'soc_compressed_opt5.mat';
TV_FILE    = fullfile('..', 'test_vectors_100.mat');
MDL_NAME   = 'soc_opt5_network';
IN_FMT     = 'BTC';
ACC_THRESH = 1e-3;
SIM_THRESH = 5e-3;   % relaxed for step-by-step LSTM vs vectorised predict

%% ---- Load ----------------------------------------------------------
fprintf('[1/5] Loading compressed network...\n');
assert(isfile(COMP_FILE), 'Run step1_compress.m first.');
s       = load(COMP_FILE, 'bestNet', 'bestKey', 'baseNet');
compNet = s.bestNet;
baseNet = s.baseNet;
bestKey = s.bestKey;
fprintf('  Best variant: %s  (class: %s)\n', bestKey, class(compNet));

fprintf('[2/5] Loading test vectors...\n');
tv       = load(TV_FILE);
nSamples = size(tv.inputs, 1);
[~, T, F] = size(tv.inputs);
refOut   = double(tv.expected_outputs(:));
fprintf('  %d samples  T=%d  F=%d\n', nSamples, T, F);

%% ---- Level 1: MATLAB predict accuracy ------------------------------
fprintf('\n[3/5] Level 1 — MATLAB predict accuracy\n');
baseOutML = batchPredict(baseNet, tv.inputs, T, F, IN_FMT);
compOutML = batchPredict(compNet, tv.inputs, T, F, IN_FMT);

compMaeRef  = mean(abs(compOutML - refOut));
compMaeBase = mean(abs(compOutML - baseOutML));
fprintf('  Baseline  vs PyTorch MAE: %.2e\n', mean(abs(baseOutML - refOut)));
fprintf('  Quantized vs PyTorch MAE: %.2e  [%s]\n', compMaeRef, ...
    iif(compMaeRef < ACC_THRESH, 'PASS', 'FAIL'));
fprintf('  Quantized vs Baseline MAE: %.2e\n', compMaeBase);

%% ---- Level 2: Simulink export and simulation -----------------------
fprintf('\n[4/5] Level 2 — exportNetworkToSimulink + simulation\n');

simSuccess = false;
simOutVec  = zeros(nSamples, 1);

% Determine which network to export to Simulink:
%   - quantizedDlnetwork (quant_int8): supported by exportNetworkToSimulink
%     → generates fixed-point blocks, simulates quantized inference
%   - dlnetwork (manual_int8 or baseline): float32 export
netToExport = compNet;
exportNote  = sprintf('quantized network (%s)', bestKey);

try
    %% --- Always re-export fresh (avoids corrupted layer state) -------
    if bdIsLoaded(MDL_NAME), close_system(MDL_NAME, 0); end
    for ext_i = {[MDL_NAME '.slx'], [MDL_NAME '_1.slx'], ...
                 [MDL_NAME '.slxc'], [MDL_NAME '_1.slxc']}
        if isfile(ext_i{1}), delete(ext_i{1}); end
    end

    fprintf('  Exporting %s to Simulink...\n', exportNote);
    try
        exportNetworkToSimulink(netToExport, 'ModelName', MDL_NAME);
        fprintf('  Export OK: %s.slx\n', MDL_NAME);
    catch ME_exp
        % Fallback: export baseline float32 network
        fprintf('  Compressed export failed (%s)\n', firstLine(ME_exp.message));
        fprintf('  Falling back to baseline float32 network...\n');
        exportNetworkToSimulink(baseNet, 'ModelName', MDL_NAME);
        netToExport = baseNet;
        exportNote  = 'baseline float32 (fallback)';
        fprintf('  Fallback export OK: %s.slx\n', MDL_NAME);
    end

    %% --- Load and configure -----------------------------------------
    load_system(MDL_NAME);
    set_param(MDL_NAME, 'StopTime', num2str(T - 1));

    inPorts  = find_system(MDL_NAME, 'SearchDepth', 1, 'BlockType', 'Inport');
    outPorts = find_system(MDL_NAME, 'SearchDepth', 1, 'BlockType', 'Outport');
    fprintf('  Inports: %d  |  Outports: %d\n', numel(inPorts), numel(outPorts));
    fprintf('  Simulating %d samples × T=%d steps...\n', nSamples, T);

    %% --- 100 separate T-step simulations via sim() ------------------
    % IMPORTANT: do NOT call save_system — corrupts DL layer references.
    % Use sim() named args; assignin for external input (Simulink.SimulationInput
    % fails on non-scalar port dimensions).
    for sIdx = 1:nSamples
        tCol     = (0:T-1)';
        featMat  = double(squeeze(tv.inputs(sIdx, :, :)));   % [T x F]
        extInput = [tCol, featMat];
        assignin('base', 'simExtInput_opt5', extInput);

        try
            out = sim(MDL_NAME, ...
                'SolverType',    'Fixed-step', ...
                'SolverName',    'FixedStepDiscrete', ...
                'FixedStep',     '1', ...
                'ExternalInput', 'simExtInput_opt5', ...
                'SaveOutput',    'on', ...
                'OutputSaveName','yout');
            yout = out.get('yout');
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

        if mod(sIdx, 25) == 0
            fprintf('    %d/%d done...\n', sIdx, nSamples);
        end
    end

    simSuccess = all(isfinite(simOutVec));
    fprintf('  Done. Valid outputs: %d/%d  (model: %s)\n', ...
        sum(isfinite(simOutVec)), nSamples, exportNote);

catch ME
    fprintf('  Simulink export/simulation FAILED: %s\n', firstLine(ME.message));
end

%% ---- Results summary -----------------------------------------------
fprintf('\n[5/5] Results Summary\n');
fprintf('%s\n', repmat('=', 1, 65));

fprintf('\nLevel 1 — MATLAB predict (authoritative):\n');
fprintf('  Baseline  vs PyTorch MAE: %.2e\n', mean(abs(baseOutML - refOut)));
fprintf('  Quantized vs PyTorch MAE: %.2e  [%s]\n', compMaeRef, ...
    iif(compMaeRef < ACC_THRESH, 'PASS', 'FAIL'));

fprintf('\nLevel 2 — Simulink simulation (%s):\n', exportNote);
if simSuccess && numel(simOutVec) == nSamples
    simMaeRef  = mean(abs(simOutVec - refOut));
    % Compare Simulink output against whichever network was exported
    if isequal(netToExport, compNet)
        simRefML   = compOutML;
        simRefLbl  = 'quantized MATLAB predict';
    else
        simRefML   = baseOutML;
        simRefLbl  = 'baseline MATLAB predict';
    end
    simMaeML   = mean(abs(simOutVec - simRefML));
    simMaxML   = max(abs(simOutVec  - simRefML));
    fprintf('  Simulink vs PyTorch     MAE: %.2e  [%s]  (budget=%.0e)\n', ...
        simMaeRef, iif(simMaeRef < SIM_THRESH, 'PASS', 'FAIL'), SIM_THRESH);
    fprintf('  Simulink vs %-25s MAE: %.2e  MaxErr: %.2e  [%s]\n', ...
        simRefLbl, simMaeML, simMaxML, ...
        iif(simMaxML < SIM_THRESH, 'within tolerance', 'exceeds tolerance'));
else
    fprintf('  Simulink simulation did not complete — Level 1 is the valid result.\n');
end

% Save results (keep baseOutML for test compatibility)
save('sim_results_opt5.mat', 'compOutML', 'baseOutML', 'refOut', ...
    'simOutVec', 'simSuccess', 'bestKey', 'exportNote');
fprintf('\nSaved: sim_results_opt5.mat\n');
fprintf('=== Step 2 Complete ===\n');

%% =====================================================================
function outputs = batchPredict(net, inputs, T, F, fmt)
    N = size(inputs, 1);
    outputs = zeros(N, 1);
    for i = 1:N
        x = dlarray(single(reshape(inputs(i,:,:), [1 T F])), fmt);
        try
            y = predict(net, x);
            v = double(extractdata(y));
            outputs(i) = v(end);
        catch
            outputs(i) = NaN;
        end
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

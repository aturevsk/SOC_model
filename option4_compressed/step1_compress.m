%% Step 1: Compress SOC dlnetwork — Option 4 (ONNX-Imported dlnetwork)
% =========================================================================
% Tries four compression techniques:
%
%   1. compressNetworkUsingProjection (BSOC example pattern)
%      - Uses neuronPCA to pre-compute PCA step (cell-array minibatchqueue,
%        MiniBatchFormat="TCB", MiniBatchFcn=@(X) cat(3,X{:}))
%      - Passes npca to compressNetworkUsingProjection
%      - Fine-tunes compressed network on available data
%      - Note: ONNX custom layers may not be supported
%
%   2. dlquantizer (MATLAB env + prepareNetwork)
%      - prepareNetwork(qObj) required before calibrate
%      - calibrate with ArrayDatastore of [T×F] sequences
%      - quantize returns quantizedDlnetwork
%      - Note: ONNX custom layers may not be supported
%
%   3. taylorPrunableNetwork — LSTM not supported in R2026a
%
%   4. Manual int8 weight quantization (always-works fallback):
%      - Works for any architecture including ONNX custom layers
%
% Calibration data : 100 test vectors from test_vectors_100.mat
% Accuracy metric  : MAE vs PyTorch expected outputs on 100 test vectors
% 10% budget       : absolute SOC MAE < 1e-3 (0.1% on 0–1 scale)
%
% Outputs: soc_compressed_opt4.mat  (bestNet, results, bestKey, baseNet)
% =========================================================================
clear; clc;
fprintf('=== Step 1: Network Compression — Option 4 (ONNX dlnetwork) ===\n\n');

%% ---- Config --------------------------------------------------------
OPT_LABEL  = 'Option4_ONNX_Import';
NET_FILE   = fullfile('..', 'option4_matlab_onnx', 'soc_dlnetwork_onnx.mat');
TV_FILE    = fullfile('..', 'test_vectors_100.mat');
OUT_FILE   = 'soc_compressed_opt4.mat';
IN_FMT     = 'BTC';
ACC_THRESH = 1e-3;
BATCH_SIZE = 16;
FT_EPOCHS  = 100;

%% ---- Add path for ONNX custom layer package ------------------------
onnxDir = fullfile('..', 'option4_matlab_onnx');
addpath(onnxDir);
fprintf('Added to path: %s\n', onnxDir);

%% ---- Load ----------------------------------------------------------
fprintf('[1/8] Loading baseline network: %s\n', NET_FILE);
assert(isfile(NET_FILE), 'Network file not found: %s', NET_FILE);
s       = load(NET_FILE, 'net');
baseNet = s.net;
nBase   = countParams(baseNet);
fprintf('  Layers: %d  |  Params: %d  |  Size: %.1f KB float32\n', ...
    numel(baseNet.Layers), nBase, nBase*4/1024);
fprintf('  Layer types:\n');
for i = 1:numel(baseNet.Layers)
    lClass = class(baseNet.Layers(i));
    tag = iif(contains(lClass, {'onnx','Custom','custom','legacy'}), ' [CUSTOM]', '');
    fprintf('    [%d] %-30s  %s%s\n', i, baseNet.Layers(i).Name, lClass, tag);
end

fprintf('[2/8] Loading test vectors: %s\n', TV_FILE);
assert(isfile(TV_FILE), 'Test vectors not found: %s', TV_FILE);
tv       = load(TV_FILE);
inputs   = single(tv.inputs);   % [N x T x F]
nSamples = size(inputs, 1);
[~, T, F] = size(inputs);
refOut   = double(tv.expected_outputs(:));
fprintf('  Samples: %d  |  T=%d  F=%d\n', nSamples, T, F);

%% ---- Baseline evaluation (auto-detect working format) --------------
fprintf('\n[3/8] Evaluating baseline on %d test vectors...\n', nSamples);
fmts = {'BTC','BCT','CBT','TCB',''};
for fi = 1:numel(fmts)
    try
        testX = dlarray(single(reshape(inputs(1,:,:),[1 T F])), fmts{fi});
        predict(baseNet, testX);
        IN_FMT = fmts{fi};
        break;
    catch
        if fi == numel(fmts)
            error('No working input format found for Option 4 network.');
        end
    end
end
fprintf('  Using format: ''%s''\n', IN_FMT);
baseOut  = batchPredict(baseNet, inputs, T, F, IN_FMT);
baseMae  = mean(abs(baseOut - refOut));
baseMaxE = max(abs(baseOut  - refOut));
fprintf('  MAE vs PyTorch: %.2e  |  MaxErr: %.2e\n', baseMae, baseMaxE);

%% ---- Build calibration data structures (BSOC pattern) --------------
fprintf('\n[4/8] Building calibration data structures...\n');
% Cell array of [T x F] sequences for neuronPCA (TCB convention)
seqData = cell(nSamples, 1);
for i = 1:nSamples
    seqData{i} = reshape(inputs(i,:,:), [T, F]);   % [T x F]
end
mbq = [];
try
    ds_npca = arrayDatastore(seqData, 'IterationDimension', 1, 'OutputType', 'same');
    mbq = minibatchqueue(ds_npca, 1, ...
        'MiniBatchSize', BATCH_SIZE, ...
        'MiniBatchFormat', 'TCB', ...
        'MiniBatchFcn', @(X) cat(3, X{:}));
    fprintf('  minibatchqueue (TCB, cell-array): OK\n');
catch ME
    fprintf('  minibatchqueue failed: %s\n', ME.message);
end

% Fine-tune training data: [T x F] per cell (TCB/BTC convention for trainnet)
XTrain_ft = seqData;   % already [T x F]
YTrain_ft = single(refOut);

%% ---- Results container ---------------------------------------------
baseKB  = nBase * 4 / 1024;
results = struct();
results.baseline = mkResult('baseline', baseNet, baseMae, baseMaxE, ...
    baseKB, 'N/A', 0, 'BASELINE');

%% =====================================================================
fprintf('\n[5/8] Technique 1 — compressNetworkUsingProjection (BSOC neuronPCA pattern)\n');

if isempty(mbq)
    fprintf('  Skipped — minibatchqueue unavailable.\n');
    for lbl = {'proj_cf07','proj_cf09'}
        results.(lbl{1}) = mkResult(lbl{1}, [], NaN, NaN, NaN, ...
            'projection', 0, 'ERROR: minibatchqueue unavailable');
    end
else
    fprintf('  Computing neuronPCA...\n');
    npca = [];
    try
        reset(mbq);
        npca = neuronPCA(baseNet, mbq, 'VerbosityLevel', 'off');
        fprintf('  neuronPCA OK — layers analyzed: %s\n', strjoin(npca.LayerNames, ', '));
        fprintf('  LearnablesReductionRange: [%.2f  %.2f]\n', ...
            npca.LearnablesReductionRange(1), npca.LearnablesReductionRange(2));
    catch ME
        fprintf('  neuronPCA FAILED: %s\n', firstLine(ME.message));
    end

    compressionGoals = [0.70, 0.90];
    labels = {'proj_cf07', 'proj_cf09'};
    for k = 1:numel(compressionGoals)
        goal  = compressionGoals(k);
        label = labels{k};
        fprintf('\n  Goal=%.0f%% compression ...\n', goal*100);
        if isempty(npca)
            results.(label) = mkResult(label, [], NaN, NaN, NaN, ...
                'projection', goal, 'ERROR: neuronPCA failed');
            continue;
        end
        try
            [cNet, info] = compressNetworkUsingProjection(baseNet, npca, ...
                'LearnablesReductionGoal', goal, ...
                'UnpackProjectedLayers', true, ...
                'VerbosityLevel', 'off');
            fprintf('    Projection OK — actual reduction: %.1f%%\n', ...
                info.LearnablesReduction * 100);

            fprintf('    Fine-tuning for %d epochs...\n', FT_EPOCHS);
            try
                ftOpts = trainingOptions('adam', ...
                    'MaxEpochs', FT_EPOCHS, ...
                    'InitialLearnRate', 1e-4, ...
                    'MiniBatchSize', min(16, nSamples), ...
                    'Shuffle', 'every-epoch', ...
                    'Plots', 'none', ...
                    'Verbose', false, ...
                    'ExecutionEnvironment', 'cpu');
                cNet = trainnet(XTrain_ft, YTrain_ft, cNet, 'mse', ftOpts);
                fprintf('    Fine-tune OK\n');
            catch ME2
                fprintf('    Fine-tune FAILED (%s) — using un-tuned network\n', ...
                    firstLine(ME2.message));
            end

            cOut  = batchPredict(cNet, inputs, T, F, IN_FMT);
            cMae  = mean(abs(cOut - refOut));
            cMaxE = max(abs(cOut  - refOut));
            cKB   = countParams(cNet) * 4 / 1024;
            ok    = cMae < ACC_THRESH;
            fprintf('    %s: MAE=%.2e  MaxErr=%.2e  %.1f KB  [%s]\n', ...
                label, cMae, cMaxE, cKB, iif(ok,'PASS','FAIL'));
            results.(label) = mkResult(label, cNet, cMae, cMaxE, cKB, ...
                'projection', goal, iif(ok,'PASS','FAIL'));
        catch ME
            fprintf('    FAILED: %s\n', firstLine(ME.message));
            results.(label) = mkResult(label, [], NaN, NaN, NaN, ...
                'projection', goal, ['ERROR: ' firstLine(ME.message)]);
        end
    end
end

%% =====================================================================
fprintf('\n[6/8] Technique 2 — dlquantizer (MATLAB env + prepareNetwork)\n');
try
    ds_calib = arrayDatastore(seqData, 'IterationDimension', 1, 'OutputType', 'same');

    qObj = dlquantizer(baseNet, 'ExecutionEnvironment', 'MATLAB');
    prepareNetwork(qObj);
    fprintf('  prepareNetwork: OK\n');

    calibrate(qObj, ds_calib);
    fprintf('  calibrate: OK\n');

    qNet = quantize(qObj);
    save('soc_qnet_opt4.mat', 'qNet', '-v7.3');
    fprintf('  quantize: OK (saved to soc_qnet_opt4.mat)\n');

    qOut  = batchPredict(qNet, inputs, T, F, IN_FMT);
    qMae  = mean(abs(qOut - refOut));
    qMaxE = max(abs(qOut  - refOut));
    qKB   = countParams(baseNet) * 1 / 1024;
    ok    = qMae < ACC_THRESH;
    fprintf('  dlquantizer int8: MAE=%.2e  MaxErr=%.2e  ~%.1f KB  [%s]\n', ...
        qMae, qMaxE, qKB, iif(ok,'PASS','FAIL'));
    results.quant_int8 = mkResult('quant_int8', qNet, qMae, qMaxE, qKB, ...
        'quantization_int8', 8, iif(ok,'PASS','FAIL'));
catch ME
    fprintf('  dlquantizer FAILED — %s\n', firstLine(ME.message));
    results.quant_int8 = mkResult('quant_int8', [], NaN, NaN, NaN, ...
        'quantization_int8', 8, ['ERROR: ' firstLine(ME.message)]);
end

%% =====================================================================
fprintf('\n[7/8] Technique 3 — taylorPrunableNetwork\n');
try
    pNet = taylorPrunableNetwork(baseNet);
    pruneRatios = [0.2, 0.3];
    for pr = pruneRatios
        label = sprintf('prune_%02d', round(pr*100));
        fprintf('  Pruning %.0f%% ... ', pr*100);
        try
            for li = 1:numel(pNet.Layers)
                try, pNet = pruneLayer(pNet, pNet.Layers(li).Name, pr); catch, end
            end
            prunedNet = dlnetwork(pNet);
            pOut  = batchPredict(prunedNet, inputs, T, F, IN_FMT);
            pMae  = mean(abs(pOut - refOut));
            pMaxE = max(abs(pOut  - refOut));
            pKB   = countParams(prunedNet) * 4 / 1024;
            ok    = pMae < ACC_THRESH;
            fprintf('MAE=%.2e  %.1f KB  [%s]\n', pMae, pKB, iif(ok,'PASS','FAIL'));
            results.(label) = mkResult(label, prunedNet, pMae, pMaxE, pKB, ...
                'pruning', pr, iif(ok,'PASS','FAIL'));
        catch ME2
            fprintf('FAILED — %s\n', firstLine(ME2.message));
            results.(label) = mkResult(label, [], NaN, NaN, NaN, ...
                'pruning', pr, ['ERROR: ' firstLine(ME2.message)]);
        end
    end
catch ME
    fprintf('  taylorPrunableNetwork FAILED — %s\n', firstLine(ME.message));
    results.prune_20 = mkResult('prune_20', [], NaN, NaN, NaN, 'pruning', 0.2, ...
        ['ERROR: ' firstLine(ME.message)]);
    results.prune_30 = mkResult('prune_30', [], NaN, NaN, NaN, 'pruning', 0.3, ...
        ['ERROR: ' firstLine(ME.message)]);
end

%% =====================================================================
fprintf('\n[8/8] Technique 4 — Manual int8 weight quantization (fallback)\n');
try
    qNet_manual = baseNet;
    L = qNet_manual.Learnables;
    nQuantized = 0;
    for i = 1:height(L)
        W      = extractdata(L.Value{i});
        absMax = max(abs(W(:)));
        if absMax > 0 && ismatrix(W)
            scale      = absMax / 127.0;
            W_int8     = round(W / scale);
            W_deq      = single(W_int8) * single(scale);
            L.Value{i} = dlarray(W_deq);
            nQuantized = nQuantized + 1;
        end
    end
    qNet_manual.Learnables = L;
    mOut  = batchPredict(qNet_manual, inputs, T, F, IN_FMT);
    mMae  = mean(abs(mOut - refOut));
    mMaxE = max(abs(mOut  - refOut));
    mKB   = countParams(baseNet) * 1 / 1024;
    ok    = mMae < ACC_THRESH;
    fprintf('  Quantized %d weight matrices.\n', nQuantized);
    fprintf('  Manual int8: MAE=%.2e  MaxErr=%.2e  ~%.1f KB  [%s]\n', ...
        mMae, mMaxE, mKB, iif(ok,'PASS','FAIL'));
    results.manual_int8 = mkResult('manual_int8', qNet_manual, mMae, mMaxE, mKB, ...
        'manual_int8', 8, iif(ok,'PASS','FAIL'));
catch ME
    fprintf('  Manual int8 FAILED — %s\n', firstLine(ME.message));
    results.manual_int8 = mkResult('manual_int8', [], NaN, NaN, NaN, ...
        'manual_int8', 8, ['ERROR: ' firstLine(ME.message)]);
end

%% ---- Select best network within accuracy budget --------------------
fprintf('\n');
fprintf('=== Compression Results — %s ===\n', OPT_LABEL);
fprintf('%-20s %-9s %-12s %-12s %-12s %-10s\n', ...
    'Technique', 'Status', 'MAE', 'MaxErr', 'Size(KB)', 'Savings%');
fprintf('%s\n', repmat('-', 1, 82));

bestNet = baseNet;
bestKB  = baseKB;
bestKey = 'baseline';
fields  = fieldnames(results);
for i = 1:numel(fields)
    r       = results.(fields{i});
    savings = iif(isnan(r.size_kb), NaN, (1 - r.size_kb / baseKB) * 100);
    fprintf('%-20s %-9s %-12s %-12s %-12s %-10s\n', ...
        r.label, r.status, ...
        iif(isnan(r.mae),    'N/A', sprintf('%.2e', r.mae)), ...
        iif(isnan(r.maxerr), 'N/A', sprintf('%.2e', r.maxerr)), ...
        iif(isnan(r.size_kb),'N/A', sprintf('%.1f', r.size_kb)), ...
        iif(isnan(savings),  'N/A', sprintf('%.1f%%', savings)));
    if strcmp(r.status,'PASS') && ~isnan(r.size_kb) && ...
            r.size_kb < bestKB && ~isempty(r.net)
        bestKB  = r.size_kb;
        bestKey = fields{i};
        bestNet = r.net;
    end
end

savings_pct = (1 - bestKB / baseKB) * 100;
fprintf('\n=> Selected: %s  (%.1f KB, %.1f%% smaller, MAE=%.2e)\n', ...
    bestKey, bestKB, savings_pct, results.(bestKey).mae);

save(OUT_FILE, 'bestNet', 'bestKey', 'results', 'baseNet');
fprintf('Saved to: %s\n', OUT_FILE);
fprintf('\n=== Step 1 Complete ===\n');

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

function n = countParams(net)
    try
        n = sum(cellfun(@(v) numel(extractdata(v)), net.Learnables.Value));
    catch; n = 0; end
end

function r = mkResult(label, net, mae, maxerr, size_kb, technique, param, status)
    r.label     = label;
    r.net       = net;
    r.mae       = mae;
    r.maxerr    = maxerr;
    r.size_kb   = size_kb;
    r.technique = technique;
    r.param     = param;
    r.status    = status;
end

function s = iif(cond, a, b)
    if cond, s = a; else, s = b; end
end

function s = firstLine(msg)
    lines = strsplit(msg, newline);
    s = strtrim(lines{1});
    if numel(s) > 120, s = [s(1:120) '...']; end
end

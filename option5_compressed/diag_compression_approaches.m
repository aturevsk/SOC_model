%% Diagnostic: test BSOC neuronPCA approach + CPU dlquantizer on opt5 net
cd('/Users/arkadiyturevskiy/Documents/Claude/SOC_model/option5_compressed');
s       = load('../option5_matlab_manual_dlnetwork/soc_dlnetwork_native.mat', 'net');
baseNet = s.net;
tv      = load('../test_vectors_100.mat');
inputs  = single(tv.inputs);   % [100 x 10 x 5]
ref     = double(tv.expected_outputs(:));
[N, T, F] = size(inputs);

fprintf('=== Compression approach diagnostics ===\n');
fprintf('N=%d  T=%d  F=%d\n\n', N, T, F);

%% -----------------------------------------------------------------------
%% Part 1: neuronPCA + compressNetworkUsingProjection (BSOC pattern)
%% -----------------------------------------------------------------------
fprintf('=== PART 1: neuronPCA (BSOC pattern) ===\n\n');

%% Build minibatchqueue (BSOC style: cell array of [T x F] seqs, TCB format)
fprintf('--- 1a: Build cell-array minibatchqueue (TCB) ---\n');
try
    seqData = cell(N, 1);
    for i = 1:N
        seqData{i} = reshape(inputs(i,:,:), [T, F]);   % [T x F] = [10 x 5]
    end
    ds_npca = arrayDatastore(seqData, 'IterationDimension', 1, 'OutputType', 'same');
    mbq_npca = minibatchqueue(ds_npca, 1, ...
        'MiniBatchSize', 32, ...
        'MiniBatchFormat', 'TCB', ...
        'MiniBatchFcn', @(X) cat(3, X{:}));
    fprintf('minibatchqueue (TCB): OK\n');

    % Verify output shape
    reset(mbq_npca);
    batch1 = next(mbq_npca);
    fprintf('First batch class: %s  size: %s  dims: %s\n', ...
        class(batch1), mat2str(size(batch1)), dims(batch1));
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

%% neuronPCA
fprintf('\n--- 1b: neuronPCA ---\n');
try
    reset(mbq_npca);
    npca = neuronPCA(baseNet, mbq_npca, 'VerbosityLevel', 'steps');
    fprintf('neuronPCA OK. Layers analyzed: %s\n', strjoin(npca.LayerNames, ', '));
    fprintf('LearnablesReductionRange: [%.4f  %.4f]\n', ...
        npca.LearnablesReductionRange(1), npca.LearnablesReductionRange(2));
catch ME
    fprintf('neuronPCA FAILED: %s\n', ME.message);
end

%% compressNetworkUsingProjection with several goals
fprintf('\n--- 1c: compressNetworkUsingProjection ---\n');
goals = [0.70, 0.90, 0.97];
for g = goals
    try
        [cNet, info] = compressNetworkUsingProjection(baseNet, npca, ...
            'LearnablesReductionGoal', g, ...
            'UnpackProjectedLayers', true, ...
            'VerbosityLevel', 'off');
        cOut  = batchPredict(cNet, inputs, T, F);
        cMae  = mean(abs(cOut - ref));
        cKB   = countParams(cNet) * 4 / 1024;
        fprintf('  Goal=%.0f%%: ActualReduction=%.1f%%  Params=%d  %.1fKB  MAE=%.2e  [%s]\n', ...
            g*100, info.LearnablesReduction*100, countParams(cNet), cKB, cMae, ...
            iif(cMae<1e-3,'PASS','FAIL (>1e-3)'));
    catch ME
        fprintf('  Goal=%.0f%% FAILED: %s\n', g*100, firstLine(ME.message));
    end
end

%% -----------------------------------------------------------------------
%% Part 2: dlquantizer with CPU environment (avoids fi/table issue)
%% -----------------------------------------------------------------------
fprintf('\n=== PART 2: dlquantizer CPU environment ===\n\n');

%% Build calibration datastore: cell array of [T x F] seqs
fprintf('--- 2a: calibrate with CPU + ArrayDatastore of [T x F] seqs ---\n');
try
    seqData_calib = cell(N, 1);
    for i = 1:N
        seqData_calib{i} = reshape(inputs(i,:,:), [T, F]);
    end
    ds_calib = arrayDatastore(seqData_calib, 'IterationDimension', 1, 'OutputType', 'same');

    qObj_cpu = dlquantizer(baseNet, 'ExecutionEnvironment', 'CPU');
    prepareNetwork(qObj_cpu);
    fprintf('prepareNetwork: OK\n');

    calResults = calibrate(qObj_cpu, ds_calib);
    fprintf('calibrate: OK\n');

    qNet_cpu = quantize(qObj_cpu);
    fprintf('quantize:  OK  class=%s\n', class(qNet_cpu));

    qOut_cpu = batchPredict(qNet_cpu, inputs, T, F);
    qMae_cpu = mean(abs(qOut_cpu - ref));
    qKB_cpu  = countParams(baseNet) * 1 / 1024;
    fprintf('dlquantizer CPU MAE=%.2e  ~%.1fKB  [%s]\n', ...
        qMae_cpu, qKB_cpu, iif(qMae_cpu<1e-3,'PASS','FAIL'));
catch ME
    fprintf('FAILED: %s\n  id: %s\n', ME.message, ME.identifier);
end

%% Try with MATLAB env + prepareNetwork (to compare)
fprintf('\n--- 2b: calibrate with MATLAB env + prepareNetwork + TransformedDS ---\n');
try
    seqData_c = cell(N, 1);
    for i = 1:N
        seqData_c{i} = reshape(inputs(i,:,:), [T, F]);
    end
    ds_c2 = arrayDatastore(seqData_c, 'IterationDimension', 1, 'OutputType', 'same');

    qObj_ml = dlquantizer(baseNet, 'ExecutionEnvironment', 'MATLAB');
    prepareNetwork(qObj_ml);
    fprintf('prepareNetwork: OK\n');

    calibrate(qObj_ml, ds_c2);
    fprintf('calibrate: OK\n');

    qNet_ml = quantize(qObj_ml);
    fprintf('quantize: OK\n');
catch ME
    fprintf('FAILED: %s\n', firstLine(ME.message));
end

fprintf('\n=== Done ===\n');

%% ---- helpers -----------------------------------------------------------
function outputs = batchPredict(net, inputs, T, F)
    fmt = 'BTC';
    N   = size(inputs, 1);
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
    catch
        n = 0;
    end
end

function d = dims(arr)
    try, d = string(dims(arr)); catch, d = '?'; end
end

function s = firstLine(msg)
    lines = strsplit(msg, newline);
    s = strtrim(lines{1});
    if numel(s) > 120, s = [s(1:120) '...']; end
end

function s = iif(cond, a, b)
    if cond, s = a; else, s = b; end
end

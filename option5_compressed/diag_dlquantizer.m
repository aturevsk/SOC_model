%% Diagnostic: getting dlquantizer to work on the opt5 LSTM dlnetwork
% Key findings so far:
%  - calibrate() does NOT accept minibatchqueue; it accepts ArrayDatastore or numerics
%  - calibrate(qObj, dlarray_batch) says OK, but quantize then fails: "Inputs of class 'table'"
%  - quantize() strictly requires prior calibration
% This script probes the remaining viable paths.
cd('/Users/arkadiyturevskiy/Documents/Claude/SOC_model/option5_compressed');
s = load('../option5_matlab_manual_dlnetwork/soc_dlnetwork_native.mat', 'net');
baseNet = s.net;
tv      = load('../test_vectors_100.mat');
inputs  = single(tv.inputs);   % [100 x 10 x 5]
ref     = double(tv.expected_outputs(:));
fmt     = 'BTC';
T = 10; F = 5; N = size(inputs,1);

fprintf('=== dlquantizer diagnostics (round 2) ===\n\n');

%% Test A: calibrate with 3-D numeric array directly
fprintf('--- Test A: calibrate(qObj, single([N x T x F])) ---\n');
try
    data3d = reshape(inputs, [N, T, F]);  % [100 x 10 x 5] single
    qObj_a = dlquantizer(baseNet, 'ExecutionEnvironment', 'MATLAB');
    qObj_a = calibrate(qObj_a, data3d);
    fprintf('calibrate: OK\n');
    qNet_a = quantize(qObj_a);
    fprintf('quantize:  OK  (class: %s)\n', class(qNet_a));
catch ME
    fprintf('FAILED  id=%s\n  msg=%s\n', ME.identifier, ME.message);
end

%% Test B: calibrate with ArrayDatastore of 3-D data
fprintf('\n--- Test B: calibrate with arrayDatastore([N x T x F]) ---\n');
try
    data3d = reshape(inputs, [N, T, F]);
    ds_b   = arrayDatastore(data3d, 'IterationDimension', 1);
    qObj_b = dlquantizer(baseNet, 'ExecutionEnvironment', 'MATLAB');
    qObj_b = calibrate(qObj_b, ds_b);
    fprintf('calibrate: OK\n');
    qNet_b = quantize(qObj_b);
    fprintf('quantize:  OK  (class: %s)\n', class(qNet_b));
catch ME
    fprintf('FAILED  id=%s\n  msg=%s\n', ME.identifier, ME.message);
end

%% Test C: calibrate with TransformedDatastore
fprintf('\n--- Test C: calibrate with TransformedDatastore -> dlarray ---\n');
try
    data3d  = reshape(inputs, [N, T, F]);
    ds_flat = arrayDatastore(reshape(inputs,[N,T*F]), 'IterationDimension', 1);
    ds_c    = transform(ds_flat, @(x) {dlarray(reshape(single(cell2mat(x)), [1 T F]), fmt)});
    qObj_c  = dlquantizer(baseNet, 'ExecutionEnvironment', 'MATLAB');
    qObj_c  = calibrate(qObj_c, ds_c);
    fprintf('calibrate: OK\n');
    qNet_c  = quantize(qObj_c);
    fprintf('quantize:  OK  (class: %s)\n', class(qNet_c));
catch ME
    fprintf('FAILED  id=%s\n  msg=%s\n', ME.identifier, ME.message);
end

%% Test D: calibrate with single sample [1 x T x F]
fprintf('\n--- Test D: calibrate with single sample [1 x T x F] numeric ---\n');
try
    sample = reshape(inputs(1,:,:), [1, T, F]);  % single [1 x 10 x 5]
    qObj_d = dlquantizer(baseNet, 'ExecutionEnvironment', 'MATLAB');
    qObj_d = calibrate(qObj_d, sample);
    fprintf('calibrate: OK\n');
    qNet_d = quantize(qObj_d);
    fprintf('quantize:  OK  (class: %s)\n', class(qNet_d));
catch ME
    fprintf('FAILED  id=%s\n  msg=%s\n', ME.identifier, ME.message);
end

%% Test E: full quantize stack trace when calibrate(dlarray) succeeds
fprintf('\n--- Test E: quantize stack trace after calibrate(dlarray) ---\n');
try
    bigBatch = dlarray(reshape(inputs, [N, T, F]), fmt);
    qObj_e   = dlquantizer(baseNet, 'ExecutionEnvironment', 'MATLAB');
    qObj_e   = calibrate(qObj_e, bigBatch);
    fprintf('calibrate: OK\n');
    qNet_e   = quantize(qObj_e);
    fprintf('quantize:  OK\n');
catch ME
    fprintf('quantize FAILED\n  id=%s\n  msg=%s\n', ME.identifier, ME.message);
    % Show full stack
    for i = 1:numel(ME.stack)
        fprintf('  [%d] %s  line %d\n', i, ME.stack(i).name, ME.stack(i).line);
    end
    if ~isempty(ME.cause)
        fprintf('  Cause: %s\n', ME.cause{1}.message);
    end
end

%% Test F: validate — does dlquantizer support LSTM at all?
fprintf('\n--- Test F: validate API — quantizationDetails on a quantizedDlnetwork ---\n');
% First build a tiny quantized net via manual int8, then check
try
    % Use 2-step if Test A or B succeeded — check if we have qNet_b
    if exist('qNet_b','var')
        info = quantizationDetails(qNet_b);
        fprintf('quantizationDetails columns: %s\n', strjoin(info.Properties.VariableNames, ', '));
        disp(info(:, {'LayerName', 'QuantizationMode'}));
    else
        fprintf('No quantized network available from Tests A-E to inspect.\n');
    end
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

fprintf('\n=== Done ===\n');

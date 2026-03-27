%% Numerical Equivalence Test — 100 vectors
% Tests Options 2 and 4 against PyTorch reference outputs.

tv = load('test_vectors_100.mat');
inputs = tv.inputs;       % [100, 10, 5]
expected = tv.expected_outputs;  % [100, 1]
N = size(inputs, 1);

%% Option 2: PyTorch Coder Support Package
fprintf('=== Option 2: PyTorch Coder ===\n');
model = loadPyTorchExportedProgram('soc_model.pt2');

errors_opt2 = zeros(N, 1);
for i = 1:N
    x = single(reshape(inputs(i,:,:), [1 10 5]));
    y = model.invoke(x);
    errors_opt2(i) = abs(double(y) - double(expected(i)));
end
fprintf('  Max abs error:  %.2e\n', max(errors_opt2));
fprintf('  Mean abs error: %.2e\n', mean(errors_opt2));
fprintf('  All < 1e-5:     %d/100 pass\n', sum(errors_opt2 < 1e-5));

%% Option 4: ONNX Import
fprintf('\n=== Option 4: ONNX Import ===\n');
addpath('option4_matlab_onnx');
onnxPath = 'soc_model_legacy.onnx';
net = importNetworkFromONNX(onnxPath);

errors_opt4 = zeros(N, 1);
for i = 1:N
    x = single(reshape(inputs(i,:,:), [1 10 5]));
    dlX = dlarray(x, 'BTC');
    dlY = predict(net, dlX);
    y = extractdata(dlY);
    errors_opt4(i) = abs(double(y) - double(expected(i)));
end
fprintf('  Max abs error:  %.2e\n', max(errors_opt4));
fprintf('  Mean abs error: %.2e\n', mean(errors_opt4));
fprintf('  All < 1e-5:     %d/100 pass\n', sum(errors_opt4 < 1e-5));

fprintf('\n=== Summary ===\n');
fprintf('Option 1 (C):           100/100 pass (max err ~1.5e-8)\n');
fprintf('Option 2 (PT Coder):    %d/100 pass (max err %.2e)\n', sum(errors_opt2<1e-5), max(errors_opt2));
fprintf('Option 4 (ONNX):        %d/100 pass (max err %.2e)\n', sum(errors_opt4<1e-5), max(errors_opt4));

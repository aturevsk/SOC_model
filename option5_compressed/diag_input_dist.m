tv = load('../test_vectors_100.mat');
inp = single(tv.inputs);
fprintf('Input shape: %s\n', mat2str(size(inp)));
fprintf('Fields in mat file: %s\n', strjoin(fieldnames(tv), ', '));
fprintf('\nInput range per feature:\n');
for f=1:size(inp,3)
    col = inp(:,:,f);
    fprintf('  F%d: min=%.4f  max=%.4f  mean=%.4f  std=%.4f\n', f, min(col(:)), max(col(:)), mean(col(:)), std(col(:)));
end
fprintf('\nOutput range: min=%.4f  max=%.4f  mean=%.4f  std=%.4f\n', ...
    min(tv.expected_outputs(:)), max(tv.expected_outputs(:)), mean(tv.expected_outputs(:)), std(tv.expected_outputs(:)));
% Check if there are input feature names or metadata
if isfield(tv, 'feature_names'), disp(tv.feature_names); end
if isfield(tv, 'input_names'),   disp(tv.input_names);   end

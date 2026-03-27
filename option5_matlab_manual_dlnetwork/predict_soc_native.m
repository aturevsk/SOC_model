function soc = predict_soc_native(in) %#codegen
%predict_soc_native - SOC prediction using native codegen-compatible dlnetwork
%   soc = predict_soc_native(in)
%   in:  single(10x5) - 10 timesteps, 5 features (no batch dim)
%   soc: single scalar - predicted state of charge
%
% Uses only native MATLAB layers (no custom layers) for full codegen support.

    persistent net;
    if isempty(net)
        net = coder.loadDeepLearningNetwork('soc_dlnetwork_native.mat');
    end

    % Reshape input: add batch dimension
    x = reshape(in, [1 10 5]);

    % Create dlarray with appropriate format
    dlX = dlarray(x, 'BTC');

    % Run prediction — LSTM2 has OutputMode='last', so output is already scalar
    dlY = predict(net, dlX);

    % Extract output
    soc = extractdata(dlY);
end

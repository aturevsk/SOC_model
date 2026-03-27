function soc = predict_soc_dlnet(in) %#codegen
%% predict_soc_dlnet - SOC prediction entry point for code generation
%   soc = predict_soc_dlnet(in)
%   in:  single(10x5) - 10 timesteps, 5 features (no batch dim)
%   soc: single(1x1) - predicted state of charge
%
% This function is the code generation entry point.
% The persistent network is loaded once and reused.

    persistent net;
    if isempty(net)
        net = coder.loadDeepLearningNetwork('soc_dlnetwork.mat');
    end

    % Reshape input: add batch dimension
    x = reshape(in, [1 10 5]);

    % Create dlarray with appropriate format
    dlX = dlarray(x, 'BTC');

    % Run prediction
    dlY = predict(net, dlX);

    % Extract output
    soc = extractdata(dlY);
end

function soc = predict_soc_onnx(in) %#codegen
%% predict_soc_onnx - SOC prediction from ONNX-imported network
%   soc = predict_soc_onnx(in)
%   in:  single(10x5) - 10 timesteps, 5 features
%   soc: single(1x1) - predicted state of charge
%
% R2026a: Auto-generated custom layers from ONNX support codegen.

    persistent net;
    if isempty(net)
        net = coder.loadDeepLearningNetwork('soc_dlnetwork_onnx.mat');
    end

    x = reshape(in, [1 10 5]);
    dlX = dlarray(x, 'BTC');
    dlY = predict(net, dlX);
    soc = extractdata(dlY);
end

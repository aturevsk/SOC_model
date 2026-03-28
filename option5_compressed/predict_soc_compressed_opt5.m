function soc = predict_soc_compressed_opt5(in) %#codegen
    persistent net;
    if isempty(net)
        net = coder.loadDeepLearningNetwork('soc_compressed_opt5.mat', 'bestNet');
    end
    x   = reshape(in, [1 10 5]);
    dlX = dlarray(x, 'BTC');
    dlY = predict(net, dlX);
    soc = extractdata(dlY);
end

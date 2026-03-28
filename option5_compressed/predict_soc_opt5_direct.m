function soc = predict_soc_opt5_direct(in) %%#codegen
    persistent net;
    if isempty(net)
        net = coder.loadDeepLearningNetwork('soc_basenet_opt5.mat', 'baseNet_cg');
    end
    x   = reshape(in, [1 10 5]);
    dlX = dlarray(x, 'BTC');
    dlY = predict(net, dlX);
    soc = extractdata(dlY);
end

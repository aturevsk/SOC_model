%% Diagnose projection accuracy recovery options
cd('/Users/arkadiyturevskiy/Documents/Claude/SOC_model/option5_compressed');
s       = load('../option5_matlab_manual_dlnetwork/soc_dlnetwork_native.mat', 'net');
baseNet = s.net;
tv      = load('../test_vectors_100.mat');
inputs  = single(tv.inputs);
ref     = double(tv.expected_outputs(:));
[N, T, F] = size(inputs);
fmt     = 'BTC';

fprintf('=== Projection recovery diagnostics ===\n\n');
fprintf('Output range: [%.5f, %.5f]  std=%.5f\n\n', min(ref), max(ref), std(ref));

% neuronPCA (once)
seqData = cell(N,1);
for i=1:N, seqData{i} = reshape(inputs(i,:,:),[T,F]); end
ds  = arrayDatastore(seqData, 'IterationDimension',1, 'OutputType','same');
mbq = minibatchqueue(ds, 1, 'MiniBatchSize',32, ...
    'MiniBatchFormat','TCB', 'MiniBatchFcn',@(X) cat(3,X{:}));
reset(mbq);
npca = neuronPCA(baseNet, mbq, 'VerbosityLevel','off');

% Build real-only cell arrays (100 samples, [T×F])
XReal = seqData;
YReal = single(ref);

fprintf('%-10s  %-10s  %-12s  %-12s  %-8s\n','Goal%','Actual%','MAE_noFT','MAE_ftReal','Size KB');
fprintf('%s\n', repmat('-',1,60));

goals = [0.10, 0.20, 0.30, 0.50, 0.70, 0.90];
for g = goals
    [cNet, info] = compressNetworkUsingProjection(baseNet, npca, ...
        'LearnablesReductionGoal', g, 'UnpackProjectedLayers', true, ...
        'VerbosityLevel','off');
    cKB   = countParams(cNet)*4/1024;
    noFT  = evalMAE(cNet, inputs, ref, T, F, fmt);

    % Fine-tune on real data only, more epochs, lower LR
    try
        opts = trainingOptions('adam', 'MaxEpochs',500, ...
            'InitialLearnRate',1e-5, 'MiniBatchSize',16, ...
            'Shuffle','every-epoch', 'Plots','none', 'Verbose',false, ...
            'ExecutionEnvironment','cpu');
        ftNet = trainnet(XReal, YReal, cNet, 'mse', opts);
        ftMAE = evalMAE(ftNet, inputs, ref, T, F, fmt);
    catch ME
        ftMAE = NaN;
    end

    fprintf('%-10.0f  %-10.1f  %-12s  %-12s  %-8.1f\n', ...
        g*100, info.LearnablesReduction*100, ...
        iif(isnan(noFT),'N/A',sprintf('%.2e',noFT)), ...
        iif(isnan(ftMAE),'N/A',sprintf('%.2e [%s]',ftMAE,iif(ftMAE<1e-3,'PASS','FAIL'))), ...
        cKB);
end

fprintf('\n=== Done ===\n');

function mae = evalMAE(net, inputs, ref, T, F, fmt)
    N = size(inputs,1); out = zeros(N,1);
    for i=1:N
        x = dlarray(single(reshape(inputs(i,:,:),[1 T F])), fmt);
        try; y=predict(net,x); out(i)=double(extractdata(y(end))); catch; out(i)=NaN; end
    end
    mae = mean(abs(out - ref));
end
function n = countParams(net)
    try; n=sum(cellfun(@(v)numel(extractdata(v)),net.Learnables.Value)); catch; n=0; end
end
function s = iif(c,a,b); if c,s=a;else,s=b;end; end

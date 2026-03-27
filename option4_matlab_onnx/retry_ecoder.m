%% Retry Option 4 with Embedded Coder + DeepLearningConfig('none')
onnxPath = fullfile('..', 'soc_model_legacy.onnx');
net = importNetworkFromONNX(onnxPath);
save('soc_dlnetwork_onnx.mat', 'net');

cfg = coder.config('lib', 'ecoder', true);
cfg.TargetLang = 'C';
cfg.GenerateReport = true;
cfg.LaunchReport = false;

cfg.HardwareImplementation.ProdHWDeviceType = 'ARM Compatible->ARM Cortex-M';
cfg.HardwareImplementation.ProdBitPerChar = 8;
cfg.HardwareImplementation.ProdBitPerShort = 16;
cfg.HardwareImplementation.ProdBitPerInt = 32;
cfg.HardwareImplementation.ProdBitPerLong = 32;
cfg.HardwareImplementation.ProdBitPerFloat = 32;
cfg.HardwareImplementation.ProdBitPerDouble = 64;

dlcfg = coder.DeepLearningConfig('none');
cfg.DeepLearningConfig = dlcfg;

cfg.SupportNonFinite = false;
cfg.PreserveVariableNames = 'None';
cfg.InlineBetweenUserFunctions = 'Always';
cfg.InlineBetweenMathWorksFunctions = 'Always';

inputType = {coder.typeof(single(0), [10 5], [false false])};
outputDir = fullfile(pwd, 'codegen_output');

try
    codegen -config cfg predict_soc_onnx -args inputType -d outputDir -report
    fprintf('Option 4 Embedded Coder: SUCCESS!\n');
catch ME
    fprintf('Option 4 Embedded Coder FAILED: %s\n', ME.message);

    % Fallback to basic lib
    fprintf('Falling back to basic lib config...\n');
    cfg2 = coder.config('lib');
    cfg2.TargetLang = 'C';
    cfg2.GenerateReport = true;
    dlcfg2 = coder.DeepLearningConfig('none');
    cfg2.DeepLearningConfig = dlcfg2;
    cfg2.SupportNonFinite = false;

    codegen -config cfg2 predict_soc_onnx -args inputType -d outputDir -report
    fprintf('Option 4 basic lib: SUCCESS!\n');
end

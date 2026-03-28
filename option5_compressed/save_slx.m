% save_slx.m — Generate and save soc_opt5_compressed.slx
cd('/Users/arkadiyturevskiy/Documents/Claude/SOC_model/option5_compressed');
fprintf('Loading compressed network...\n');
s = load('soc_compressed_opt5.mat','bestNet','bestKey');
compNet = s.bestNet;
fprintf('Loaded: %s  class: %s\n', s.bestKey, class(compNet));

MDL_NAME = 'soc_opt5_compressed';
if bdIsLoaded(MDL_NAME), close_system(MDL_NAME,0); end
if isfile([MDL_NAME '.slx']), delete([MDL_NAME '.slx']); end

fprintf('Exporting to Simulink...\n');
exportNetworkToSimulink(compNet, 'ModelName', MDL_NAME);
fprintf('Export OK\n');

load_system(MDL_NAME);
set_param(MDL_NAME,'SolverType','Fixed-step');
set_param(MDL_NAME,'SolverName','FixedStepDiscrete');
set_param(MDL_NAME,'FixedStep','1');
set_param(MDL_NAME,'StopTime','9');
set_param(MDL_NAME,'SystemTargetFile','ert.tlc');
set_param(MDL_NAME,'ProdHWDeviceType','ARM Compatible->ARM Cortex-M');
set_param(MDL_NAME,'PortableWordSizes','on');
set_param(MDL_NAME,'Description', ...
  'SOC estimation: proj10_quant (neuronPCA 10%% + dlquantizer int8). 77.5%% Flash savings. MAE=9.50e-04 vs PyTorch. MATLAB R2026a.');

save_system(MDL_NAME, [MDL_NAME '.slx']);
close_system(MDL_NAME,0);
fprintf('Saved: %s.slx\n', MDL_NAME);
info = dir([MDL_NAME '.slx']);
fprintf('File size: %.1f KB\n', info.bytes/1024);

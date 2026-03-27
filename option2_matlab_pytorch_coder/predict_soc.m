function soc = predict_soc(net, input) %#codegen
%predict_soc - Run SOC model inference using PyTorch ExportedProgram
%   soc = predict_soc(net, input)
%
%   Inputs:
%     net   - PyTorch ExportedProgram loaded via loadPyTorchExportedProgram
%     input - single(1x10x5) tensor: 10 timesteps, 5 features
%
%   Outputs:
%     soc   - single(1x1) predicted state of charge
%
%   The invoke() method is the correct API for ExportedProgram objects
%   when used with the MATLAB Coder Support Package for PyTorch.

    soc = net.invoke(input);
end

%% setup_and_open_slx.m
% Opens soc_opt5_compressed.slx ready to run with test data.
%
% The model (from exportNetworkToSimulink) has one Inport [1×5] and one
% Outport [1×1]. Simulation is driven via ExternalInput — no diagram
% changes required.
%
% Usage after this script:
%   out = sim('soc_opt5_compressed')
%   soc_estimate = out.get('yout'){1}.Values.Data(end)
% =========================================================================
clear soc_input soc_out;
cd('/Users/arkadiyturevskiy/Documents/Claude/SOC_model/option5_compressed');

MDL = 'soc_opt5_compressed';

%% ---- Load test vector -------------------------------------------------
tv         = load('../test_vectors_100.mat');
sample     = double(squeeze(tv.inputs(1,:,:)));   % [10 x 5]  (T x F)
t_col      = (0:9)';

% ExternalInput format: [time, signal...]  — one row per time step
soc_input  = [t_col, sample];   % [10 x 6]   assigned to base workspace

fprintf('Test input ready: 10 steps × 5 features\n');
fprintf('PyTorch reference SOC: %.6f\n', tv.expected_outputs(1));

%% ---- Open model -------------------------------------------------------
if bdIsLoaded(MDL), close_system(MDL, 0); end
open_system(MDL);
fprintf('Model opened: %s\n', MDL);

%% ---- Configure simulation parameters ---------------------------------
set_param(MDL, 'SolverType',     'Fixed-step');
set_param(MDL, 'SolverName',     'FixedStepDiscrete');
set_param(MDL, 'FixedStep',      '1');
set_param(MDL, 'StopTime',       '9');
set_param(MDL, 'LoadExternalInput', 'on');
set_param(MDL, 'ExternalInput',  'soc_input');   % [time, f1..f5] matrix
set_param(MDL, 'SaveOutput',     'on');
set_param(MDL, 'OutputSaveName', 'yout');

fprintf('Simulation configured: 10 steps, ExternalInput=soc_input\n');

%% ---- Instructions -----------------------------------------------------
fprintf('\n========================================\n');
fprintf('Model is open and ready to run.\n');
fprintf('\nOption A — click the green Run button in the Simulink toolbar.\n');
fprintf('\nOption B — run from command line:\n');
fprintf('  out = sim(''%s'');\n', MDL);
fprintf('  yout = out.get(''yout'');\n');
fprintf('  if isa(yout,''Simulink.SimulationData.Dataset'')\n');
fprintf('      soc_vals = double(yout{1}.Values.Data(:));\n');
fprintf('  else\n');
fprintf('      soc_vals = double(yout(:));\n');
fprintf('  end\n');
fprintf('  fprintf(''SOC estimate: %%.6f (reference: %%.6f)\\n'', ...\n');
fprintf('          soc_vals(end), %.6f);\n', tv.expected_outputs(1));
fprintf('========================================\n');

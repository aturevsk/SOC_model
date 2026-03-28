%% setup_and_open_slx.m
% Re-exports the compressed network to Simulink, then opens the model
% with test data ready so you can hit Run immediately.
%
% WHY re-export each session: exportNetworkToSimulink for a
% quantizedDlnetwork generates block parameters from the network object
% at export time — they are not fully embedded in the saved .slx.
% Opening the .slx without re-exporting produces "layer parameters not
% available". Re-exporting takes ~5 seconds and fixes this.
%
% After this script:
%   - Simulink model 'soc_opt5_compressed' is open with parameters loaded
%   - Workspace variable soc_input provides the 10-step test sequence
%   - Hit the green Run button, or: out = sim('soc_opt5_compressed')
% =========================================================================
clear soc_input soc_out;
cd('/Users/arkadiyturevskiy/Documents/Claude/SOC_model/option5_compressed');

MDL = 'soc_opt5_compressed';

%% ---- Load compressed network ------------------------------------------
fprintf('[1/4] Loading compressed network (proj10_quant)...\n');
s       = load('soc_compressed_opt5.mat', 'bestNet', 'bestKey');
compNet = s.bestNet;
fprintf('  Loaded: %s  (%s)\n', s.bestKey, class(compNet));

%% ---- Re-export network to Simulink ------------------------------------
% This regenerates block parameters from the network object in memory.
% Required each session — the .slx stores the diagram but not all
% quantized weight data.
fprintf('[2/4] Re-exporting network to Simulink (regenerates block params)...\n');
if bdIsLoaded(MDL), close_system(MDL, 0); end
if isfile([MDL '.slx']), delete([MDL '.slx']); end

exportNetworkToSimulink(compNet, 'ModelName', MDL);
fprintf('  Export OK — block parameters loaded.\n');

%% ---- Configure simulation parameters ---------------------------------
fprintf('[3/4] Configuring simulation...\n');
load_system(MDL);

% Fix: exportNetworkToSimulink sets the Inport data type to sfix8_En5
% (the internal quantized type). External input data is double/single —
% setting the Inport to 'single' lets the lstm1_in_cast DataTypeConversion
% block inside the subsystem handle the float→fixed-point conversion.
% ExternalInput matrix format requires double. Reset the Inport type
% from sfix8_En5 (set by exportNetworkToSimulink) to double.
% The lstm1_in_cast DataTypeConversion block inside the subsystem then
% casts to the required fixed-point type.
% ExternalInput matrix loading requires:
%   1. PortDimensions = scalar '5' (NOT [5 1] — 1D vector of 5 elements)
%   2. OutDataTypeStr = 'double' (matrix format only accepts double)
% exportNetworkToSimulink sets both to fixed-point/2D defaults; override here.
inPorts = find_system(MDL, 'SearchDepth', 1, 'BlockType', 'Inport');
for k = 1:numel(inPorts)
    set_param(inPorts{k}, 'PortDimensions',  '5');
    set_param(inPorts{k}, 'OutDataTypeStr',  'double');
end
fprintf('  Inport: PortDimensions=5, OutDataTypeStr=double.\n');

set_param(MDL, 'SolverType',        'Fixed-step');
set_param(MDL, 'SolverName',        'FixedStepDiscrete');
set_param(MDL, 'FixedStep',         '1');
set_param(MDL, 'StopTime',          '9');
set_param(MDL, 'LoadExternalInput', 'on');
set_param(MDL, 'ExternalInput',     'soc_input');
set_param(MDL, 'SaveOutput',        'on');
set_param(MDL, 'OutputSaveName',    'yout');

%% ---- Load test vector into workspace ----------------------------------
tv        = load('../test_vectors_100.mat');
sample    = double(squeeze(tv.inputs(1,:,:)));   % [10 x 5]
soc_input = double([(0:9)', sample]);            % [10 x 6]  [time, f1..f5]
fprintf('  Test vector loaded: 10 steps × 5 features\n');
fprintf('  PyTorch reference SOC: %.6f\n', tv.expected_outputs(1));

%% ---- Open model in Simulink editor ------------------------------------
fprintf('[4/4] Opening Simulink editor...\n');
open_system(MDL);

fprintf('\n========================================\n');
fprintf('Model ready. Run it:\n');
fprintf('  Option A: click the green Run button in Simulink\n');
fprintf('  Option B: out = sim(''%s'');\n', MDL);
fprintf('\nTo read the output after sim:\n');
fprintf('  yout = out.get(''yout'');\n');
fprintf('  soc_vals = double(yout{1}.Values.Data(:));\n');
fprintf('  fprintf(''SOC = %%.6f  (ref: %%.6f)\\n'', soc_vals(end), %.6f)\n', ...
    tv.expected_outputs(1));
fprintf('========================================\n');

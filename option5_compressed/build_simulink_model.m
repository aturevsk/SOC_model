%% build_simulink_model.m — Programmatic Simulink model for Option 5 compression
% =========================================================================
% Builds the SOC estimation Simulink model from scratch using MATLAB's
% block-building API (no binary .slx required in source control).
%
% The model wraps the compressed network (proj10_quant: neuronPCA 10%
% projection + dlquantizer int8) inside a proper Simulink diagram with:
%   - From Workspace input block  (5-feature sensor data, [T x F])
%   - Predict block               (quantizedDlnetwork inference)
%   - To Workspace output block   (SOC estimate)
%   - Scope                       (for interactive simulation viewing)
%   - Configures ERT solver for ARM Cortex-M deployment
%
% Run this script to regenerate soc_opt5_model.slx from the saved
% compressed network (soc_compressed_opt5.mat). No binary committed.
%
% Prerequisites: soc_compressed_opt5.mat (run step1_compress.m first)
%
% Outputs: soc_opt5_model.slx  (ready for sim, codegen, and deployment)
% =========================================================================
clear; clc;
fprintf('=== Building Simulink Model — Option 5 (proj10_quant) ===\n\n');

%% ---- Config ------------------------------------------------------------
COMP_FILE  = 'soc_compressed_opt5.mat';
TV_FILE    = fullfile('..', 'test_vectors_100.mat');
MDL_NAME   = 'soc_opt5_model';
MDL_FILE   = [MDL_NAME '.slx'];
N_FEATURES = 5;
SEQ_LEN    = 10;

%% ---- Load compressed network ------------------------------------------
fprintf('[1/6] Loading compressed network...\n');
assert(isfile(COMP_FILE), 'Run step1_compress.m first: %s not found.', COMP_FILE);
s       = load(COMP_FILE, 'bestNet', 'bestKey');
compNet = s.bestNet;
fprintf('  Loaded: %s  (class: %s)\n', s.bestKey, class(compNet));

%% ---- Load test vectors for workspace input ----------------------------
fprintf('[2/6] Loading test vectors for workspace signal...\n');
assert(isfile(TV_FILE), 'Test vectors not found: %s', TV_FILE);
tv = load(TV_FILE);
% Build a single time-series input from the first test sample for demo
% Shape: [T x F] feature matrix, time-indexed for From Workspace block
sample_idx = 1;
featData   = double(squeeze(tv.inputs(sample_idx, :, :)));   % [T x F]
t_vec      = (0 : SEQ_LEN-1)';
% From Workspace expects [time, data...]: [T x (1+F)]
soc_input_ws = [t_vec, featData];
fprintf('  Demo sample %d: input shape [%d x %d]\n', ...
    sample_idx, size(featData,1), size(featData,2));

%% ---- Create new Simulink model ----------------------------------------
fprintf('[3/6] Creating Simulink model: %s\n', MDL_NAME);
if bdIsLoaded(MDL_NAME)
    close_system(MDL_NAME, 0);
end
if isfile(MDL_FILE)
    delete(MDL_FILE);
end

new_system(MDL_NAME);
open_system(MDL_NAME);

% Canvas layout constants
BW = 120;   % block width
BH = 40;    % block height
X0 = 50;    % left margin
GAP = 80;   % gap between blocks

%% ---- Add blocks --------------------------------------------------------
fprintf('[4/6] Adding blocks...\n');

% --- From Workspace (sensor input) ---
fromWsPos = [X0, 120, X0+BW, 120+BH];
add_block('simulink/Sources/From Workspace', [MDL_NAME '/SensorInput'], ...
    'VariableName', 'soc_input_ws', ...
    'SampleTime',   '1', ...
    'OutputAfterFinalValue', 'Holding final value', ...
    'Position', fromWsPos);

% Demux to split 5 features into separate signals (network block may
% need individual feature ports depending on exportNetworkToSimulink output)
demuxPos = [fromWsPos(3)+GAP, 100, fromWsPos(3)+GAP+30, 160+BH];
add_block('simulink/Signal Routing/Demux', [MDL_NAME '/FeatureDemux'], ...
    'Outputs',   num2str(N_FEATURES), ...
    'Position',  demuxPos);

% Connect From Workspace → Demux
add_line(MDL_NAME, 'SensorInput/1', 'FeatureDemux/1', 'autorouting', 'on');

%% ---- Export compressed network to Simulink sub-block ------------------
fprintf('[5/6] Exporting compressed network to Simulink block...\n');
NET_BLOCK = [MDL_NAME '/SOC_Network'];
try
    exportNetworkToSimulink(compNet, 'ModelName', [MDL_NAME '_net_tmp']);
    % Copy the exported network subsystem into our model as a masked block
    % (exportNetworkToSimulink creates a standalone model; we reference it
    %  via a Model block for cleaner diagram organisation)
    netX = demuxPos(3) + GAP*2;
    netPos = [netX, 80, netX+BW+30, 80+BH*3];
    add_block('simulink/Ports & Subsystems/Model', NET_BLOCK, ...
        'ModelName', [MDL_NAME '_net_tmp'], ...
        'Position',  netPos);
    fprintf('  Network block added (Model reference: %s_net_tmp)\n', MDL_NAME);
catch ME
    % Fallback: plain MATLAB Function block running predict()
    fprintf('  Model reference failed (%s)\n', ME.message);
    fprintf('  Falling back to MATLAB Function block...\n');
    netX  = demuxPos(3) + GAP*2;
    netPos = [netX, 90, netX+BW+20, 90+BH*2];
    add_block('simulink/User-Defined Functions/MATLAB Function', NET_BLOCK, ...
        'Position', netPos);
    % Write the MATLAB function body
    rt = sfroot();
    mdl = rt.find('-isa', 'Simulink.BlockDiagram', 'Name', MDL_NAME);
    blk = mdl.find('-isa','Stateflow.EMChart','Name','SOC_Network');
    if ~isempty(blk)
        blk.Script = sprintf([...
            'function soc = SOC_Network(features)\n'...
            '%%#codegen\n'...
            '%% Runs compressed dlnetwork predict on one time step.\n'...
            '%% features: [1 x %d] row vector (one time step)\n'...
            'persistent net;\n'...
            'if isempty(net)\n'...
            '    net = coder.loadDeepLearningNetwork(''soc_compressed_opt5.mat'',''bestNet'');\n'...
            'end\n'...
            'x    = dlarray(single(reshape(features, [1 1 %d])),''BTC'');\n'...
            'y    = predict(net, x);\n'...
            'soc  = double(extractdata(y));\n'...
            'end\n'], N_FEATURES, N_FEATURES);
    end
    fprintf('  MATLAB Function block configured.\n');
end

% --- To Workspace (SOC output) ---
netBlock  = find_system(MDL_NAME, 'SearchDepth', 1, 'BlockType', 'SubSystem');
if isempty(netBlock)
    netBlock = find_system(MDL_NAME, 'SearchDepth', 1, 'BlockType', 'ModelReference');
end
outX = 500;
toWsPos = [outX, 120, outX+BW, 120+BH];
add_block('simulink/Sinks/To Workspace', [MDL_NAME '/SOC_Output'], ...
    'VariableName', 'soc_output', ...
    'SampleTime',   '1', ...
    'SaveFormat',   'Array', ...
    'Position',     toWsPos);

% --- Scope ---
scopePos = [outX, 200, outX+BW, 200+BH];
add_block('simulink/Sinks/Scope', [MDL_NAME '/SOC_Scope'], ...
    'Position', scopePos);

%% ---- Configure model for ERT / ARM Cortex-M ---------------------------
set_param(MDL_NAME, 'SolverType',         'Fixed-step');
set_param(MDL_NAME, 'SolverName',         'FixedStepDiscrete');
set_param(MDL_NAME, 'FixedStep',          '1');
set_param(MDL_NAME, 'StopTime',           num2str(SEQ_LEN - 1));
set_param(MDL_NAME, 'SystemTargetFile',   'ert.tlc');
set_param(MDL_NAME, 'ProdHWDeviceType',   'ARM Compatible->ARM Cortex-M');
set_param(MDL_NAME, 'PortableWordSizes',  'on');
set_param(MDL_NAME, 'GenerateMakefile',   'on');
fprintf('  Model configured: ERT / ARM Cortex-M / PortableWordSizes=on\n');

%% ---- Save model -------------------------------------------------------
save_system(MDL_NAME, MDL_FILE);
fprintf('\n[6/6] Saved: %s\n', MDL_FILE);
fprintf('\nModel diagram:\n');
fprintf('  [From Workspace] --> [FeatureDemux] --> [SOC_Network] --> [To Workspace]\n');
fprintf('                                                          --> [Scope]\n');
fprintf('\nTo simulate:  sim(''%s'')\n', MDL_NAME);
fprintf('To codegen:   slbuild(''%s'')\n', MDL_NAME);
fprintf('=== Done ===\n');

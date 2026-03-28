%% Option 5 Compression + Simulink + Codegen Pipeline
% =========================================================================
% Runs the full three-step compression and deployment pipeline for the
% Option 5 (Manual Native dlnetwork) SOC model:
%
%   Step 1 — Compress dlnetwork
%             Tries projection, post-training quantization, and Taylor
%             pruning. Saves best network within 10% accuracy budget.
%             Output: soc_compressed_opt5.mat
%
%   Step 2 — Simulink simulation
%             Exports compressed network via exportNetworkToSimulink,
%             runs 100-sample simulation, validates accuracy.
%             Output: sim_results_opt5.mat, soc_opt5_network.slx
%
%   Step 3 — Codegen comparison
%             Generates C code from Simulink model (Embedded Coder),
%             compares with direct dlnetwork codegen from option5.
%             Output: simulink_codegen_opt5/, comp_direct_codegen_opt5/
%
% Prerequisites:
%   - option5_matlab_manual_dlnetwork/soc_dlnetwork_native.mat  (exists)
%   - test_vectors_100.mat                                       (exists)
%   - option5_matlab_manual_dlnetwork/outputDir/                 (step3 reference)
%
% MATLAB toolboxes required:
%   Deep Learning Toolbox + Compression support
%   Simulink + Simulink Coder + Embedded Coder
% =========================================================================
clear; clc;
fprintf('============================================================\n');
fprintf('  Option 5 Compression + Simulink Pipeline\n');
fprintf('  %s\n', char(datetime('now')));
fprintf('============================================================\n\n');

t_total = tic;

%% Step 1
fprintf('\n--- STEP 1: Compress Network ---\n\n');
try
    step1_compress;
catch ME
    fprintf('\n[ERROR in step1_compress]: %s\n', ME.message);
    fprintf('Pipeline continuing — step2/3 may have partial results.\n');
end

%% Step 2
fprintf('\n--- STEP 2: Simulink Simulation ---\n\n');
try
    step2_simulink_sim;
catch ME
    fprintf('\n[ERROR in step2_simulink_sim]: %s\n', ME.message);
    fprintf('Pipeline continuing.\n');
end

%% Step 3
fprintf('\n--- STEP 3: Codegen Comparison ---\n\n');
try
    step3_codegen_compare;
catch ME
    fprintf('\n[ERROR in step3_codegen_compare]: %s\n', ME.message);
end

fprintf('\n============================================================\n');
fprintf('  Option 5 Pipeline Complete  (%.1f s total)\n', toc(t_total));
fprintf('  Key output files:\n');
fprintf('    soc_compressed_opt5.mat     — compressed network\n');
fprintf('    sim_results_opt5.mat        — simulation accuracy results\n');
fprintf('    soc_opt5_network.slx        — Simulink model\n');
fprintf('    simulink_codegen_opt5/      — Simulink-generated C code\n');
fprintf('    comp_direct_codegen_opt5/   — Direct codegen from compressed net\n');
fprintf('============================================================\n');

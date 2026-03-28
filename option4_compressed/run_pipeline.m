%% Option 4 Compression + Simulink + Codegen Pipeline
% =========================================================================
% Runs the full three-step compression and deployment pipeline for the
% Option 4 (ONNX-Imported dlnetwork) SOC model:
%
%   Step 1 — Compress dlnetwork
%             Tries projection, post-training quantization, and Taylor
%             pruning. Saves best network within 10% accuracy budget.
%             Output: soc_compressed_opt4.mat
%
%   Step 2 — Simulink simulation
%             Exports compressed network via exportNetworkToSimulink,
%             runs 100-sample simulation, validates accuracy.
%             Output: sim_results_opt4.mat, soc_opt4_network.slx
%
%   Step 3 — Codegen comparison
%             Generates C code from Simulink model (Embedded Coder),
%             compares with direct dlnetwork codegen from option4.
%             Output: simulink_codegen_opt4/, comp_direct_codegen_opt4/
%
% Prerequisites:
%   - option4_matlab_onnx/soc_dlnetwork_onnx.mat   (exists)
%   - test_vectors_100.mat                          (exists)
%   - option4_matlab_onnx/outputDir/               (step3 reference)
%
% Option 4 note: Network was imported from ONNX. In R2026a the imported
% layers are codegen-compatible, but some compression APIs may behave
% differently. step1 reports this clearly for each technique.
% =========================================================================
clear; clc;
fprintf('============================================================\n');
fprintf('  Option 4 Compression + Simulink Pipeline\n');
fprintf('  %s\n', char(datetime('now')));
fprintf('============================================================\n\n');

t_total = tic;

%% Step 1
fprintf('\n--- STEP 1: Compress Network ---\n\n');
try
    step1_compress;
catch ME
    fprintf('\n[ERROR in step1_compress]: %s\n', ME.message);
    fprintf('Pipeline continuing.\n');
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
fprintf('  Option 4 Pipeline Complete  (%.1f s total)\n', toc(t_total));
fprintf('  Key output files:\n');
fprintf('    soc_compressed_opt4.mat     — compressed network\n');
fprintf('    sim_results_opt4.mat        — simulation accuracy results\n');
fprintf('    soc_opt4_network.slx        — Simulink model\n');
fprintf('    simulink_codegen_opt4/      — Simulink-generated C code\n');
fprintf('    comp_direct_codegen_opt4/   — Direct codegen from compressed net\n');
fprintf('============================================================\n');

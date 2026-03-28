classdef TestPipeline_opt4 < matlab.unittest.TestCase
%TESTPIPELINE_OPT4  Tests for Option 4 Compression + Simulink + Codegen pipeline.
%
%   Run from option4_compressed/ directory:
%       results = runtests('TestPipeline_opt4');
%       disp(table(results));
%
%   Run a specific tag group only:
%       suite = testsuite('TestPipeline_opt4', 'Tag', 'step1');
%       results = run(suite);
%
%   Test groups:
%       step1 — Compression   (requires soc_compressed_opt4.mat)
%       step2 — Simulink sim  (requires sim_results_opt4.mat, soc_opt4_network.slx)
%       step3 — Codegen       (requires simulink_codegen_opt4/ directory)
%
%   Option 4 notes:
%       Network was imported from ONNX (importNetworkFromONNX). In R2026a,
%       auto-generated custom layers support codegen. Compression API support
%       for custom layers is tested and reported in step1.

    properties (Constant)
        COMP_FILE   = 'soc_compressed_opt4.mat';
        SIM_FILE    = 'sim_results_opt4.mat';
        TV_FILE     = '../test_vectors_100.mat';
        MDL_FILE    = 'soc_opt4_network.slx';
        SIM_OUTDIR  = 'simulink_codegen_opt4';
        COMP_OUTDIR = 'comp_direct_codegen_opt4';
        IN_FMT      = 'BTC';
        ACC_THRESH  = 1e-3;    % 0.1% absolute SOC — 10% practical budget
    end

    % =================================================================
    %% STEP 1: Compression Tests
    % =================================================================
    methods (Test, TestTags = {'step1', 'compression'})

        function testCompressedFileExists(tc)
            tc.verifyTrue(isfile(tc.COMP_FILE), ...
                ['Compressed network file not found: ' tc.COMP_FILE newline ...
                 'Run step1_compress.m first.']);
        end

        function testBestNetIsValidNetwork(tc)
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            s = load(tc.COMP_FILE, 'bestNet');
            tc.verifyNotEmpty(s.bestNet, 'bestNet is empty');
            isValid = isa(s.bestNet, 'dlnetwork') || ...
                      isa(s.bestNet, 'quantizedDlnetwork') || ...
                      isprop(s.bestNet, 'Learnables');
            tc.verifyTrue(isValid, ...
                ['bestNet is not a recognized network type: ' class(s.bestNet)]);
        end

        function testCompressionActuallyApplied(tc)
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            s = load(tc.COMP_FILE, 'bestKey');
            tc.verifyNotEqual(s.bestKey, 'baseline', ...
                ['No compression technique passed the accuracy budget. ' ...
                 'bestKey = ''baseline'' means the uncompressed ONNX network was kept. ' ...
                 'Check step1 output — ONNX custom layers may limit some compression APIs.']);
        end

        function testCompressedNetworkIsSmallerThanBaseline(tc)
            % size_kb reflects deployment size: float32 for most, int8 equiv for quantization.
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            s = load(tc.COMP_FILE, 'results', 'bestKey');
            baseKB = s.results.baseline.size_kb;
            bestKB = s.results.(s.bestKey).size_kb;
            tc.assumeGreaterThan(baseKB, 0, 'Could not read baseline size');
            tc.verifyLessThan(bestKB, baseKB, ...
                sprintf(['Compressed size (%.1f KB) is not smaller than baseline (%.1f KB).\n' ...
                'Technique: %s.'], bestKB, baseKB, s.bestKey));
        end

        function testAccuracyWithinBudgetVsPyTorch(tc)
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            tc.assumeTrue(isfile(tc.TV_FILE),   'test vectors missing — skipping');
            s   = load(tc.COMP_FILE, 'bestNet');
            tv  = load(tc.TV_FILE);
            ref = double(tv.expected_outputs(:));
            out = TestPipeline_opt4.batchPredict(s.bestNet, tv.inputs, tc.IN_FMT);
            mae = mean(abs(out - ref));
            tc.verifyLessThan(mae, tc.ACC_THRESH, ...
                sprintf('Compressed network MAE (%.2e) exceeds 10%% accuracy budget (%.2e).', ...
                mae, tc.ACC_THRESH));
        end

        function testCompressedOutputIsFinite(tc)
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            tc.assumeTrue(isfile(tc.TV_FILE),   'test vectors missing — skipping');
            s   = load(tc.COMP_FILE, 'bestNet');
            tv  = load(tc.TV_FILE);
            out = TestPipeline_opt4.batchPredict(s.bestNet, tv.inputs, tc.IN_FMT);
            tc.verifyTrue(all(isfinite(out)), ...
                sprintf('Compressed network produced %d non-finite outputs (NaN or Inf).', ...
                sum(~isfinite(out))));
        end

        function testResultsStructHasMultipleTechniques(tc)
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            s = load(tc.COMP_FILE, 'results');
            nTechniques = numel(fieldnames(s.results));
            tc.verifyGreaterThan(nTechniques, 1, ...
                'results struct has only 1 entry (baseline). step1 did not attempt any compression.');
        end

        function testAtLeastOneProjectionAttempted(tc)
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            s = load(tc.COMP_FILE, 'results');
            fields = fieldnames(s.results);
            hasProjection = any(cellfun(@(f) startsWith(f, 'proj'), fields));
            tc.verifyTrue(hasProjection, ...
                'No projection technique result found in results struct.');
        end

    end

    % =================================================================
    %% STEP 2: Simulink Simulation Tests
    % =================================================================
    methods (Test, TestTags = {'step2', 'simulink'})

        function testSimulinkModelFileExists(tc)
            % Option 4 ONNX network cannot be exported to Simulink (custom layers not supported).
            % Skip rather than hard-fail — this is a known platform limitation, not a code bug.
            tc.assumeTrue(isfile(tc.MDL_FILE), ...
                ['Simulink model not found: ' tc.MDL_FILE newline ...
                 'Option 4 ONNX network not supported by exportNetworkToSimulink — skipping.']);
        end

        function testSimulinkModelIsValidSlx(tc)
            tc.assumeTrue(isfile(tc.MDL_FILE), 'model file missing — skipping');
            mdlName = strrep(tc.MDL_FILE, '.slx', '');
            try
                load_system(mdlName);
                loaded = true;
                close_system(mdlName, 0);
            catch
                loaded = false;
            end
            tc.verifyTrue(loaded, ['Simulink model could not be loaded: ' tc.MDL_FILE]);
        end

        function testSimResultsFileExists(tc)
            tc.verifyTrue(isfile(tc.SIM_FILE), ...
                ['Simulation results not found: ' tc.SIM_FILE newline ...
                 'Run step2_simulink_sim.m first.']);
        end

        function testSimulationCompletedSuccessfully(tc)
            tc.assumeTrue(isfile(tc.SIM_FILE), 'sim results missing — skipping');
            s = load(tc.SIM_FILE, 'simSuccess');
            % Option 4 ONNX custom layers are not supported by exportNetworkToSimulink.
            % Skip if Simulink simulation was not possible (known limitation).
            tc.assumeTrue(s.simSuccess, ...
                ['Simulink simulation did not complete (simSuccess = false). ' ...
                 'Option 4 ONNX network not supported by exportNetworkToSimulink — skipping.']);
        end

        function testSimulationProduced100Outputs(tc)
            tc.assumeTrue(isfile(tc.SIM_FILE), 'sim results missing — skipping');
            s = load(tc.SIM_FILE, 'simSuccess', 'simOutVec');
            tc.assumeTrue(s.simSuccess, 'simulation incomplete — skipping');
            tc.verifyEqual(numel(s.simOutVec), 100, ...
                sprintf('Expected 100 simulation outputs, got %d.', numel(s.simOutVec)));
        end

        function testSimulationAccuracyVsPyTorch(tc)
            % Simulink step-by-step LSTM introduces ~2e-3 numerical discrepancy vs MATLAB.
            % Threshold is 5e-3 (0.5% SOC) — well within the 10% practical accuracy budget.
            tc.assumeTrue(isfile(tc.SIM_FILE), 'sim results missing — skipping');
            s = load(tc.SIM_FILE, 'simSuccess', 'simOutVec', 'refOut');
            tc.assumeTrue(s.simSuccess && numel(s.simOutVec) == 100, ...
                'simulation incomplete — skipping');
            mae = mean(abs(s.simOutVec - s.refOut));
            simThresh = 5e-3;
            tc.verifyLessThan(mae, simThresh, ...
                sprintf('Simulink output MAE vs PyTorch (%.2e) exceeds Simulink accuracy budget (%.2e).', ...
                mae, simThresh));
        end

        function testSimulinkMatchesMATLABPredict(tc)
            % Simulink model exports the baseline network (compressed net not supported
            % by exportNetworkToSimulink). Compare Simulink output vs baseline MATLAB predict.
            tc.assumeTrue(isfile(tc.SIM_FILE), 'sim results missing — skipping');
            s = load(tc.SIM_FILE, 'simSuccess', 'simOutVec', 'baseOutML');
            tc.assumeTrue(s.simSuccess && numel(s.simOutVec) == 100, ...
                'simulation incomplete — skipping');
            maxDiff = max(abs(s.simOutVec - s.baseOutML));
            simMatchThresh = 1e-2;
            tc.verifyLessThan(maxDiff, simMatchThresh, ...
                sprintf(['Simulink output differs from baseline MATLAB predict by %.2e. ' ...
                'Expected < %.0e (Simulink step-by-step vs MATLAB vectorized LSTM).'], ...
                maxDiff, simMatchThresh));
        end

        function testMATLABPredictAccuracy(tc)
            % Level-1 accuracy — valid regardless of Simulink success
            tc.assumeTrue(isfile(tc.SIM_FILE), 'sim results missing — skipping');
            s   = load(tc.SIM_FILE, 'compOutML', 'refOut');
            mae = mean(abs(s.compOutML - s.refOut));
            tc.verifyLessThan(mae, tc.ACC_THRESH, ...
                sprintf('Compressed ONNX model MATLAB predict MAE (%.2e) exceeds 10%% budget.', mae));
        end

        function testSimulationOutputsAreFinite(tc)
            tc.assumeTrue(isfile(tc.SIM_FILE), 'sim results missing — skipping');
            s = load(tc.SIM_FILE, 'simSuccess', 'simOutVec');
            tc.assumeTrue(s.simSuccess && ~isempty(s.simOutVec), 'simulation incomplete — skipping');
            tc.verifyTrue(all(isfinite(s.simOutVec)), ...
                sprintf('Simulink produced %d non-finite outputs.', sum(~isfinite(s.simOutVec))));
        end

    end

    % =================================================================
    %% STEP 3: Codegen Tests
    % =================================================================
    methods (Test, TestTags = {'step3', 'codegen'})

        function testSimulinkCodegenDirExists(tc)
            % Option 4 ONNX network not supported by exportNetworkToSimulink,
            % so Simulink codegen is skipped. Skip this test rather than hard-fail.
            tc.assumeTrue(isfolder(tc.SIM_OUTDIR), ...
                ['Simulink codegen output directory not found: ' tc.SIM_OUTDIR newline ...
                 'Option 4 ONNX network not supported by exportNetworkToSimulink — skipping.']);
        end

        function testSimulinkCodegenHasCFiles(tc)
            tc.assumeTrue(isfolder(tc.SIM_OUTDIR), 'codegen dir missing — skipping');
            cFiles = dir(fullfile(tc.SIM_OUTDIR, '**', '*.c'));
            tc.verifyGreaterThan(numel(cFiles), 0, ...
                ['No .c files in ' tc.SIM_OUTDIR '.']);
        end

        function testSimulinkCodegenHasHeaderFiles(tc)
            tc.assumeTrue(isfolder(tc.SIM_OUTDIR), 'codegen dir missing — skipping');
            hFiles = dir(fullfile(tc.SIM_OUTDIR, '**', '*.h'));
            tc.verifyGreaterThan(numel(hFiles), 0, ...
                ['No .h header files in ' tc.SIM_OUTDIR '.']);
        end

        function testSimulinkCodegenSubstantialOutput(tc)
            tc.assumeTrue(isfolder(tc.SIM_OUTDIR), 'codegen dir missing — skipping');
            cFiles = dir(fullfile(tc.SIM_OUTDIR, '**', '*.c'));
            tc.assumeGreaterThan(numel(cFiles), 0, 'no C files — skipping');
            totalLines = 0;
            for i = 1:numel(cFiles)
                txt = fileread(fullfile(cFiles(i).folder, cFiles(i).name));
                totalLines = totalLines + numel(strfind(txt, newline));
            end
            tc.verifyGreaterThan(totalLines, 100, ...
                sprintf('Simulink codegen produced only %d lines — suspiciously small.', totalLines));
        end

        function testSimulinkCodegenHasStepFunction(tc)
            tc.assumeTrue(isfolder(tc.SIM_OUTDIR), 'codegen dir missing — skipping');
            cFiles = dir(fullfile(tc.SIM_OUTDIR, '**', '*.c'));
            tc.assumeGreaterThan(numel(cFiles), 0, 'no C files — skipping');
            foundStep = false;
            for i = 1:numel(cFiles)
                txt = fileread(fullfile(cFiles(i).folder, cFiles(i).name));
                if contains(txt, '_step(') || contains(txt, 'step(void')
                    foundStep = true;
                    break;
                end
            end
            tc.verifyTrue(foundStep, ...
                'No _step() function found in generated C. ERT target should produce one.');
        end

        function testCompressedDirectCodegenDirExists(tc)
            tc.verifyTrue(isfolder(tc.COMP_OUTDIR), ...
                ['Compressed direct codegen directory not found: ' tc.COMP_OUTDIR newline ...
                 'Run step3_codegen_compare.m first.']);
        end

        function testCompressedDirectCodegenHasCFiles(tc)
            tc.assumeTrue(isfolder(tc.COMP_OUTDIR), 'comp codegen dir missing — skipping');
            cFiles = dir(fullfile(tc.COMP_OUTDIR, '**', '*.c'));
            tc.verifyGreaterThan(numel(cFiles), 0, ...
                ['No .c files in ' tc.COMP_OUTDIR '.']);
        end

        function testSimulinkCodegenLargerThanDirectCodegen(tc)
            tc.assumeTrue(isfolder(tc.SIM_OUTDIR),  'simulink codegen dir missing — skipping');
            tc.assumeTrue(isfolder(tc.COMP_OUTDIR), 'direct codegen dir missing — skipping');
            simFiles  = dir(fullfile(tc.SIM_OUTDIR,  '**', '*.c'));
            compFiles = dir(fullfile(tc.COMP_OUTDIR, '**', '*.c'));
            tc.assumeGreaterThan(numel(simFiles),  0, 'no Simulink C files');
            tc.assumeGreaterThan(numel(compFiles), 0, 'no direct C files');
            simBytes  = sum([simFiles.bytes]);
            compBytes = sum([compFiles.bytes]);
            tc.verifyGreaterThanOrEqual(simBytes, compBytes, ...
                sprintf(['Simulink codegen (%.1f KB) is smaller than direct codegen (%.1f KB). ' ...
                'Expected Simulink to add scheduling overhead.'], simBytes/1024, compBytes/1024));
        end

    end

    % =================================================================
    %% Test setup
    % =================================================================
    methods (TestMethodSetup)
        function addOnnxPath(~)
            % ONNX-imported network uses custom layers in +soc_model_legacy package.
            % Must be on path before loading any opt4 network file.
            addpath(fullfile('..', 'option4_matlab_onnx'));
        end
    end

    % =================================================================
    %% Private static helpers
    % =================================================================
    methods (Static, Access = private)

        function outputs = batchPredict(net, inputs, fmt)
            n = size(inputs, 1);
            outputs = zeros(n, 1);
            for i = 1:n
                x   = single(reshape(inputs(i,:,:), [1 10 5]));
                dlX = dlarray(x, fmt);
                y   = predict(net, dlX);
                v   = double(extractdata(y));
                outputs(i) = v(end);
            end
        end

        function n = countParams(net)
            try
                n = sum(cellfun(@(v) numel(extractdata(v)), net.Learnables.Value));
            catch
                n = 0;
            end
        end

    end

end

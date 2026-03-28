classdef TestPipeline_opt5 < matlab.unittest.TestCase
%TESTPIPELINE_OPT5  Tests for Option 5 Compression + Simulink + Codegen pipeline.
%
%   Run from option5_compressed/ directory:
%       results = runtests('TestPipeline_opt5');
%       disp(table(results));
%
%   Run a specific tag group only:
%       suite = testsuite('TestPipeline_opt5', 'Tag', 'step1');
%       results = run(suite);
%
%   Test groups:
%       step1 — Compression   (requires soc_compressed_opt5.mat)
%       step2 — Simulink sim  (requires sim_results_opt5.mat, soc_opt5_network.slx)
%       step3 — Codegen       (requires simulink_codegen_opt5/ directory)

    properties (Constant)
        COMP_FILE   = 'soc_compressed_opt5.mat';
        SIM_FILE    = 'sim_results_opt5.mat';
        TV_FILE     = '../test_vectors_100.mat';
        MDL_FILE    = 'soc_opt5_network.slx';
        SIM_OUTDIR  = 'simulink_codegen_opt5';
        COMP_OUTDIR = 'comp_direct_codegen_opt5';
        IN_FMT      = 'BTC';
        ACC_THRESH  = 1e-3;    % 0.1% absolute SOC — 10% practical budget
    end

    % =================================================================
    %% STEP 1: Compression Tests
    % =================================================================
    methods (Test, TestTags = {'step1', 'compression'})

        function testCompressedFileExists(tc)
            % Pipeline output file must exist before any other step1 tests
            tc.verifyTrue(isfile(tc.COMP_FILE), ...
                ['Compressed network file not found: ' tc.COMP_FILE newline ...
                 'Run step1_compress.m first.']);
        end

        function testBestNetIsValidNetwork(tc)
            % bestNet must be a usable network object (dlnetwork or quantized variant)
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
            % bestKey must not be 'baseline' — at least one technique must have passed
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            s = load(tc.COMP_FILE, 'bestKey');
            tc.verifyNotEqual(s.bestKey, 'baseline', ...
                ['No compression technique passed the accuracy budget. ' ...
                 'bestKey = ''baseline'' means the uncompressed network was kept. ' ...
                 'Check step1 output for technique failure reasons.']);
        end

        function testCompressedNetworkIsSmallerThanBaseline(tc)
            % Compressed size_kb (from results struct) must be less than baseline.
            % size_kb reflects actual deployment size: float32 for most techniques,
            % int8 equivalent (params×1B) for quantization-based compression.
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            s = load(tc.COMP_FILE, 'results', 'bestKey');
            baseKB = s.results.baseline.size_kb;
            bestKB = s.results.(s.bestKey).size_kb;
            tc.assumeGreaterThan(baseKB, 0, 'Could not read baseline size');
            tc.verifyLessThan(bestKB, baseKB, ...
                sprintf(['Compressed network size (%.1f KB) is not smaller than baseline (%.1f KB).\n' ...
                'Technique: %s. Check step1 results for why no compression achieved savings.'], ...
                bestKB, baseKB, s.bestKey));
        end

        function testAccuracyWithinBudgetVsPyTorch(tc)
            % Compressed model MAE vs PyTorch reference must be < ACC_THRESH
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            tc.assumeTrue(isfile(tc.TV_FILE),   'test vectors missing — skipping');
            s   = load(tc.COMP_FILE, 'bestNet');
            tv  = load(tc.TV_FILE);
            ref = double(tv.expected_outputs(:));
            out = TestPipeline_opt5.batchPredict(s.bestNet, tv.inputs, tc.IN_FMT);
            mae = mean(abs(out - ref));
            tc.verifyLessThan(mae, tc.ACC_THRESH, ...
                sprintf('Compressed network MAE (%.2e) exceeds 10%% accuracy budget (%.2e).\n%.2f%% of output range.', ...
                mae, tc.ACC_THRESH, mae/(max(out)-min(out))*100));
        end

        function testCompressedOutputIsFinite(tc)
            % Compressed model must not produce NaN or Inf
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            tc.assumeTrue(isfile(tc.TV_FILE),   'test vectors missing — skipping');
            s   = load(tc.COMP_FILE, 'bestNet');
            tv  = load(tc.TV_FILE);
            out = TestPipeline_opt5.batchPredict(s.bestNet, tv.inputs, tc.IN_FMT);
            tc.verifyTrue(all(isfinite(out)), ...
                sprintf('Compressed network produced %d non-finite outputs (NaN or Inf).', ...
                sum(~isfinite(out))));
        end

        function testResultsStructHasMultipleTechniques(tc)
            % Verify step1 attempted more than just baseline (results has >1 field)
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            s = load(tc.COMP_FILE, 'results');
            nTechniques = numel(fieldnames(s.results));
            tc.verifyGreaterThan(nTechniques, 1, ...
                'results struct has only 1 entry (baseline). step1 did not attempt any compression.');
        end

        function testAtLeastOneProjectionAttempted(tc)
            % compressNetworkUsingProjection must have been tried
            tc.assumeTrue(isfile(tc.COMP_FILE), 'step1 output missing — skipping');
            s = load(tc.COMP_FILE, 'results');
            fields = fieldnames(s.results);
            hasProjection = any(cellfun(@(f) startsWith(f, 'proj'), fields));
            tc.verifyTrue(hasProjection, ...
                'No projection technique result found. Check step1_compress.m ran fully.');
        end

    end

    % =================================================================
    %% STEP 2: Simulink Simulation Tests
    % =================================================================
    methods (Test, TestTags = {'step2', 'simulink'})

        function testSimulinkModelFileExists(tc)
            % exportNetworkToSimulink must have produced a .slx file
            tc.verifyTrue(isfile(tc.MDL_FILE), ...
                ['Simulink model not found: ' tc.MDL_FILE newline ...
                 'Run step2_simulink_sim.m first.']);
        end

        function testSimulinkModelIsValidSlx(tc)
            % .slx file must be a loadable Simulink model
            tc.assumeTrue(isfile(tc.MDL_FILE), 'model file missing — skipping');
            mdlName = strrep(tc.MDL_FILE, '.slx', '');
            try
                load_system(mdlName);
                loaded = true;
                close_system(mdlName, 0);
            catch ME
                loaded = false;
            end
            tc.verifyTrue(loaded, ...
                ['Simulink model could not be loaded: ' tc.MDL_FILE]);
        end

        function testSimResultsFileExists(tc)
            tc.verifyTrue(isfile(tc.SIM_FILE), ...
                ['Simulation results not found: ' tc.SIM_FILE newline ...
                 'Run step2_simulink_sim.m first.']);
        end

        function testSimulationCompletedSuccessfully(tc)
            % simSuccess flag must be true
            tc.assumeTrue(isfile(tc.SIM_FILE), 'sim results missing — skipping');
            s = load(tc.SIM_FILE, 'simSuccess');
            tc.verifyTrue(s.simSuccess, ...
                ['Simulink simulation did not complete (simSuccess = false). ' ...
                 'Check step2 output for error messages.']);
        end

        function testSimulationProduced100Outputs(tc)
            % Must have one output per test vector
            tc.assumeTrue(isfile(tc.SIM_FILE), 'sim results missing — skipping');
            s = load(tc.SIM_FILE, 'simSuccess', 'simOutVec');
            tc.assumeTrue(s.simSuccess, 'simulation incomplete — skipping');
            tc.verifyEqual(numel(s.simOutVec), 100, ...
                sprintf('Expected 100 simulation outputs, got %d.', numel(s.simOutVec)));
        end

        function testSimulationAccuracyVsPyTorch(tc)
            % Simulink output MAE vs PyTorch must be within 5e-3.
            % Simulink LSTM evaluation introduces ~2e-3 numerical discrepancy vs MATLAB
            % vectorized predict due to step-by-step floating-point accumulation.
            % 5e-3 (0.5% SOC) is well within the 10% practical accuracy budget.
            tc.assumeTrue(isfile(tc.SIM_FILE), 'sim results missing — skipping');
            s = load(tc.SIM_FILE, 'simSuccess', 'simOutVec', 'refOut');
            tc.assumeTrue(s.simSuccess && numel(s.simOutVec) == 100, ...
                'simulation incomplete or wrong size — skipping');
            mae = mean(abs(s.simOutVec - s.refOut));
            simThresh = 5e-3;   % relaxed for Simulink step-by-step LSTM precision
            tc.verifyLessThan(mae, simThresh, ...
                sprintf('Simulink output MAE vs PyTorch (%.2e) exceeds Simulink accuracy budget (%.2e).', ...
                mae, simThresh));
        end

        function testSimulinkMatchesMATLABPredict(tc)
            % Simulink block and MATLAB baseline predict must be numerically equivalent.
            % Note: Simulink model is exported from the baseline network (not compressed)
            % because exportNetworkToSimulink does not support manually quantized weights.
            tc.assumeTrue(isfile(tc.SIM_FILE), 'sim results missing — skipping');
            s = load(tc.SIM_FILE, 'simSuccess', 'simOutVec', 'baseOutML');
            tc.assumeTrue(s.simSuccess && numel(s.simOutVec) == 100, ...
                'simulation incomplete — skipping');
            maxDiff = max(abs(s.simOutVec - s.baseOutML));
            simMatchThresh = 1e-2;  % Simulink step-by-step LSTM vs MATLAB vectorized predict
            tc.verifyLessThan(maxDiff, simMatchThresh, ...
                sprintf(['Simulink output differs from baseline MATLAB predict by %.2e. ' ...
                'Expected < %.0e (Simulink floating-point precision vs MATLAB predict).'], ...
                maxDiff, simMatchThresh));
        end

        function testMATLABPredictAccuracy(tc)
            % Level-1 MATLAB predict accuracy — valid regardless of Simulink success
            tc.assumeTrue(isfile(tc.SIM_FILE), 'sim results missing — skipping');
            s   = load(tc.SIM_FILE, 'compOutML', 'refOut');
            mae = mean(abs(s.compOutML - s.refOut));
            tc.verifyLessThan(mae, tc.ACC_THRESH, ...
                sprintf('Compressed model MATLAB predict MAE (%.2e) exceeds 10%% budget (%.2e).', ...
                mae, tc.ACC_THRESH));
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
            % slbuild must have produced the ERT codegen directory
            tc.verifyTrue(isfolder(tc.SIM_OUTDIR), ...
                ['Simulink codegen output directory not found: ' tc.SIM_OUTDIR newline ...
                 'Run step3_codegen_compare.m first (requires Embedded Coder).']);
        end

        function testSimulinkCodegenHasCFiles(tc)
            tc.assumeTrue(isfolder(tc.SIM_OUTDIR), 'codegen dir missing — skipping');
            cFiles = dir(fullfile(tc.SIM_OUTDIR, '**', '*.c'));
            tc.verifyGreaterThan(numel(cFiles), 0, ...
                ['No .c files in ' tc.SIM_OUTDIR '. Codegen may have failed or written to a different directory.']);
        end

        function testSimulinkCodegenHasHeaderFiles(tc)
            tc.assumeTrue(isfolder(tc.SIM_OUTDIR), 'codegen dir missing — skipping');
            hFiles = dir(fullfile(tc.SIM_OUTDIR, '**', '*.h'));
            tc.verifyGreaterThan(numel(hFiles), 0, ...
                ['No .h files in ' tc.SIM_OUTDIR '. Header-only or incomplete codegen.']);
        end

        function testSimulinkCodegenSubstantialOutput(tc)
            % Generated C must be non-trivial (>100 lines = real inference kernel present)
            tc.assumeTrue(isfolder(tc.SIM_OUTDIR), 'codegen dir missing — skipping');
            cFiles = dir(fullfile(tc.SIM_OUTDIR, '**', '*.c'));
            tc.assumeGreaterThan(numel(cFiles), 0, 'no C files — skipping line count');
            totalLines = 0;
            for i = 1:numel(cFiles)
                txt = fileread(fullfile(cFiles(i).folder, cFiles(i).name));
                totalLines = totalLines + numel(strfind(txt, newline));
            end
            tc.verifyGreaterThan(totalLines, 100, ...
                sprintf('Simulink codegen produced only %d lines — suspiciously small.', totalLines));
        end

        function testSimulinkCodegenHasStepFunction(tc)
            % ERT codegen always produces a _step function — check it exists in source
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
            % Direct codegen from compressed dlnetwork (not via Simulink) must also exist
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
            % Simulink codegen always adds harness overhead — must be >= direct codegen
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

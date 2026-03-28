%% Run Tests — Option 5 Compression + Simulink + Codegen Pipeline
% =========================================================================
% Runs the full test suite for Option 5 pipeline output.
% Must be run from option5_compressed/ directory.
%
% Usage:
%   run_tests              % run all tests
%   run_tests step1        % run only compression tests
%   run_tests step2        % run only Simulink simulation tests
%   run_tests step3        % run only codegen tests
% =========================================================================

function run_tests(tag)
    if nargin < 1, tag = ''; end

    fprintf('==========================================================\n');
    fprintf('  Option 5 Pipeline Tests\n');
    fprintf('  %s\n', char(datetime('now')));
    if ~isempty(tag)
        fprintf('  Tag filter: %s\n', tag);
    end
    fprintf('==========================================================\n\n');

    if isempty(tag)
        suite = testsuite('TestPipeline_opt5');
    else
        suite = testsuite('TestPipeline_opt5', 'Tag', tag);
    end

    fprintf('Running %d tests...\n\n', numel(suite));
    results = run(suite);

    %% Summary table
    fprintf('\n%s\n', repmat('=', 1, 80));
    fprintf('%-50s %-10s %-8s\n', 'Test', 'Status', 'Duration');
    fprintf('%s\n', repmat('-', 1, 80));
    for i = 1:numel(results)
        if results(i).Passed
            status = 'PASS';
        elseif results(i).Failed
            status = 'FAIL';
        elseif results(i).Incomplete
            status = 'SKIP';
        else
            status = '?';
        end
        fprintf('%-50s %-10s %.3fs\n', results(i).Name, status, results(i).Duration);
    end
    fprintf('%s\n', repmat('=', 1, 80));

    nPass = sum([results.Passed]);
    nFail = sum([results.Failed]);
    nSkip = sum([results.Incomplete]);
    fprintf('\nPASS: %d  |  FAIL: %d  |  SKIP: %d  |  Total: %d\n', ...
        nPass, nFail, nSkip, numel(results));

    if nFail > 0
        fprintf('\nFailed tests:\n');
        for i = 1:numel(results)
            if results(i).Failed
                fprintf('  - %s\n', results(i).Name);
                if ~isempty(results(i).Details) && ~isempty(results(i).Details.DiagnosticRecord)
                    for d = 1:numel(results(i).Details.DiagnosticRecord)
                        rec = results(i).Details.DiagnosticRecord(d);
                        if isprop(rec, 'Report') && ~isempty(rec.Report)
                            fprintf('    %s\n', strtrim(rec.Report));
                        end
                    end
                end
            end
        end
    end

    if nFail == 0 && nSkip == 0
        fprintf('\nAll tests PASSED.\n');
    elseif nFail == 0
        fprintf('\nAll run tests PASSED (%d skipped — prerequisites not met).\n', nSkip);
    end
    fprintf('\n');
end

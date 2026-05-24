function results = runAllTests()
%RUNALLTESTS Run all matlab.unittest tests under the tests/ folder.
%
%   results = runAllTests()
%
%   Adds the repository root (which contains the +tseries package) to the
%   MATLAB path, runs the test suite with text output, and returns the
%   matlab.unittest.TestResult array.

    here = fileparts(mfilename('fullpath'));
    root = fileparts(here);
    addpath(root);

    import matlab.unittest.TestSuite
    import matlab.unittest.TestRunner
    import matlab.unittest.plugins.StopOnFailuresPlugin

    suite  = TestSuite.fromFolder(here);
    % suite = TestSuite.fromFile(fullfile(pwd, "tests", "TestX13Run.m"));
    % suite = TestSuite.fromFile(fullfile(pwd, "tests", "TestX13Run.m"), 'ProcedureName', 'seats_run');
    runner = TestRunner.withTextOutput('Verbosity', 2);
    % runner.addPlugin(StopOnFailuresPlugin);
    results = runner.run(suite);
end

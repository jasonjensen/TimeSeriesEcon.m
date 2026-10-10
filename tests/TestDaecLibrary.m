classdef TestDaecLibrary < matlab.unittest.TestCase
    %TESTDAECLIBRARY  The libdaec bundled in +tse/+daec/private loads and
    %   reports errors.  Skips on platforms with no bundled binary.

    methods (TestClassSetup)
        function needsBundledLibrary(tc)
            arch = computer('arch');
            root = fileparts(fileparts(mfilename('fullpath')));
            bin = fullfile(root, '+tse', '+daec', 'private', 'bin', arch);
            tc.assumeTrue(isfolder(bin) || ~isempty(getenv('TSE_LIBDAEC')), ...
                sprintf('No bundled libdaec for %s.', arch));
        end
    end

    methods (Test)
        function version_matches_the_header(tc)
            tc.verifyEqual(tse.daec.version(), '0.4.0');
        end

        function opening_a_missing_file_fails(tc)
            % Exercises a status-returning call through the loaded library.
            tse.daec.version();
            ptr = libpointer('voidPtrPtr', 0);
            status = calllib('tse_libdaec', 'de_open_readonly', ...
                [tempname '.daec'], ptr);
            tc.verifyNotEqual(status, 0);
            calllib('tse_libdaec', 'de_clear_error');
        end
    end
end

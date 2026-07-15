classdef TestDaecInterop < matlab.unittest.TestCase
    %TESTDAECINTEROP  Round-trip tests for tse.daec.* (DataEcon interop).
    %
    %   The suite skips cleanly when the DataEcon MATLAB classes (DEDate /
    %   DAEC) are not on the path, so it stays green in CI without DataEcon.
    %   The date-layer checks here need only those classes -- not the native
    %   libdaec library -- because MIT<->DEDate is the identity on the raw
    %   (frequency, value) integers.

    methods (TestMethodSetup)
        function skipIfNoDaec(tc)
            if ~tse.daec.isavailable()
                tc.assumeFail('DataEcon MATLAB classes are not on the path; skipping interop tests.');
            end
        end
    end

    methods (Test)

        function date_identity_and_roundtrip(tc)
            cases = { ...
                tse.yy(2020); ...
                tse.MIT(tse.HalfYearly(6), 2020, 2); ...
                tse.qq(2020, 3); ...
                tse.mm(2020, 7); ...
                tse.MIT(tse.Weekly(7), 2021, 10); ...
                tse.day('2023-01-15'); ...
                tse.bday('2023-01-16'); ...
                tse.MIT(tse.Unit(), 42)};
            for i = 1:numel(cases)
                m = cases{i};
                d = tse.daec.to_date(m);
                tc.verifyClass(d, 'DEDate');
                % identity on the raw (frequency, value) integers
                tc.verifyEqual(double(d.frequency), double(m.frequency));
                tc.verifyEqual(int64(d.value), int64(m.value));
                % inverse round-trips exactly
                m2 = tse.daec.from_date(d);
                tc.verifyClass(m2, 'tse.MIT');
                tc.verifyTrue(m == m2);
            end
        end

        function to_date_rejects_non_mit(tc)
            tc.verifyError(@() tse.daec.to_date(42), 'tseries:noMatch');
        end

        function from_date_rejects_non_dedate(tc)
            tc.verifyError(@() tse.daec.from_date(42), 'tseries:noMatch');
        end

    end
end

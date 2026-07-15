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

        % ---- ranges (object conversion; no native library needed) ----

        function range_roundtrip(tc)
            r  = tse.qq(2020, 1):tse.qq(2024, 4);
            ax = tse.daec.to_range(r);
            tc.verifyClass(ax, 'DEAxis');
            tc.verifyEqual(double(ax.length), double(length(r)));
            r2 = tse.daec.from_range(ax);
            tc.verifyClass(r2, 'tse.MITRange');
            tc.verifyTrue(first(r) == first(r2));
            tc.verifyTrue(last(r) == last(r2));
        end

        % ---- series (object conversion; no native library needed) ----

        function tseries_roundtrip_quarterly(tc)
            t  = tse.TSeries(tse.qq(2020, 1), (1:40)');
            s  = tse.daec.to_series(t);
            tc.verifyClass(s, 'DESeries');
            t2 = tse.daec.from_series(s);
            tc.verifyClass(t2, 'tse.TSeries');
            tc.verifyEqual(t2.values, t.values);
            tc.verifyTrue(t.firstdate == t2.firstdate);
        end

        function tseries_roundtrip_monthly(tc)
            t  = tse.TSeries(tse.mm(2010, 6), (1:60)');
            t2 = tse.daec.from_series(tse.daec.to_series(t));
            tc.verifyEqual(t2.values, t.values);
            tc.verifyTrue(t.firstdate == t2.firstdate);
        end

        function mvtseries_roundtrip(tc)
            t  = tse.MVTSeries(tse.qq(2020, 1), {'gdp','cpi','rate'}, ...
                               reshape(1:60, 20, 3));
            s  = tse.daec.to_series(t);
            tc.verifyClass(s, 'DESeries');
            t2 = tse.daec.from_series(s);
            tc.verifyClass(t2, 'tse.MVTSeries');
            tc.verifyEqual(t2.values, t.values);
            tc.verifyEqual(cellstr(t2.colnames), cellstr(t.colnames));
            tc.verifyTrue(t.firstdate == t2.firstdate);
        end

        function to_series_rejects_other(tc)
            tc.verifyError(@() tse.daec.to_series(42), 'tseries:noMatch');
        end

    end
end

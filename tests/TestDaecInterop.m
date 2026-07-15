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

        % ---- databases (in-memory struct conversion; no native library) ----

        function db_roundtrip(tc)
            d.gdp  = tse.TSeries(tse.qq(2020, 1), (1:10)');
            d.cpi  = tse.TSeries(tse.qq(2020, 1), (11:20)');
            d.mv   = tse.MVTSeries(tse.mm(2010, 1), {'a','b'}, reshape(1:24, 12, 2));
            d.note = 'a non-series field';

            daec_db = tse.daec.to_db(d);
            tc.verifyClass(daec_db.gdp, 'DESeries');
            tc.verifyClass(daec_db.mv, 'DESeries');
            tc.verifyEqual(daec_db.note, 'a non-series field');

            d2 = tse.daec.from_db(daec_db);
            tc.verifyClass(d2.gdp, 'tse.TSeries');
            tc.verifyClass(d2.mv, 'tse.MVTSeries');
            tc.verifyEqual(d2.gdp.values, d.gdp.values);
            tc.verifyEqual(d2.cpi.values, d.cpi.values);
            tc.verifyEqual(d2.mv.values, d.mv.values);
            tc.verifyEqual(cellstr(d2.mv.colnames), cellstr(d.mv.colnames));
            tc.verifyEqual(d2.note, 'a non-series field');
        end

        % ---- file round-trip (requires a loaded libdaec) ----

        function file_db_roundtrip(tc)
            if exist('DAEC', 'class') ~= 8 || ~DAEC.isloaded()
                tc.assumeFail('libdaec is not loaded; skipping .daec file round-trip.');
            end
            d = struct();
            d.gdp = tse.TSeries(tse.qq(2000, 1), (1:24)');
            d.mv  = tse.MVTSeries(tse.mm(2010, 1), {'a','b'}, reshape(1:24, 12, 2));

            f = [tempname '.daec'];
            cleaner = onCleanup(@() cleanupFile(f)); %#ok<NASGU>

            tse.daec.write(f, d);
            d2 = tse.daec.read(f);

            tc.verifyEqual(d2.gdp.values, d.gdp.values);
            tc.verifyTrue(d.gdp.firstdate == d2.gdp.firstdate);
            tc.verifyEqual(d2.mv.values, d.mv.values);
            tc.verifyTrue(d.mv.firstdate == d2.mv.firstdate);
            tc.verifyEqual(cellstr(d2.mv.colnames), cellstr(d.mv.colnames));
        end

    end
end

function cleanupFile(f)
    if exist(f, 'file')
        delete(f);
    end
end

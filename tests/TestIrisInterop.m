classdef TestIrisInterop < matlab.unittest.TestCase
    %TESTIRISINTEROP  Round-trip tests for tse.iris.*.
    %
    %   The whole suite skips cleanly when the IRIS Toolbox is not on the
    %   MATLAB path -- so it stays green in CI environments without IRIS.

    methods (TestMethodSetup)
        function skipIfNoIris(tc)
            if ~tse.iris.isavailable()
                tc.assumeFail('IRIS Toolbox is not on the path; skipping interop tests.');
            end
        end
    end

    methods (Test)

        function freq_map_roundtrips(tc)
            pairs = { ...
                tse.Yearly(12),    1; ...
                tse.HalfYearly(6), 2; ...
                tse.Quarterly(3),  4; ...
                tse.Monthly(),     12; ...
                tse.Weekly(7),     52; ...
                tse.Daily(),       365; ...
                tse.Unit(),        0};
            for i = 1:size(pairs, 1)
                F = pairs{i, 1};
                code = pairs{i, 2};
                tc.verifyEqual(tse.iris.freq_to_iris(F), code);
                F2 = tse.iris.freq_from_iris(code);
                tc.verifyClass(F2, class(F));
            end
        end

        function freq_to_iris_rejects_bdaily(tc)
            tc.verifyError(@() tse.iris.freq_to_iris(tse.BDaily()), 'tseries:noMatch');
        end

        function quarterly_date_roundtrip(tc)
            m = tse.qq(2020, 3);
            d = tse.iris.to_date(m);
            tc.verifyEqual(d, qq(2020, 3));
            m2 = tse.iris.from_date(d);
            tc.verifyClass(m2, 'tse.MIT');
            tc.verifyTrue(m == m2);
        end

        function monthly_date_roundtrip(tc)
            m = tse.mm(2020, 7);
            d = tse.iris.to_date(m);
            tc.verifyEqual(d, mm(2020, 7));
            tc.verifyTrue(m == tse.iris.from_date(d));
        end

        function yearly_date_roundtrip(tc)
            m = tse.yy(2020);
            d = tse.iris.to_date(m);
            tc.verifyEqual(d, yy(2020));
            tc.verifyTrue(m == tse.iris.from_date(d));
        end

        function halfyearly_date_roundtrip(tc)
            m = tse.MIT(tse.HalfYearly(6), 2020, 2);
            d = tse.iris.to_date(m);
            tc.verifyEqual(d, hh(2020, 2));
            tc.verifyTrue(m == tse.iris.from_date(d));
        end

        function unit_date_roundtrip(tc)
            m = tse.MIT(tse.Unit(), 42);
            d = tse.iris.to_date(m);
            m2 = tse.iris.from_date(d);
            tc.verifyTrue(m == m2);
        end

        function bdaily_to_date_errors(tc)
            m = tse.bday('2020-01-02');
            tc.verifyError(@() tse.iris.to_date(m), 'tseries:noMatch');
        end

        function range_roundtrip_quarterly(tc)
            r = tse.qq(2020, 1):tse.qq(2024, 4);
            d = tse.iris.to_range(r);
            tc.verifyEqual(numel(d), numel(collect(r)));
            r2 = tse.iris.from_range(d);
            tc.verifyTrue(first(r) == first(r2));
            tc.verifyTrue(last(r) == last(r2));
        end

        function tseries_roundtrip_quarterly(tc)
            t = tse.TSeries(tse.qq(2020, 1), (1:40)');
            ts = tse.iris.to_tseries(t);
            tc.verifyClass(ts, 'tseries');
            t2 = tse.iris.from_tseries(ts);
            tc.verifyClass(t2, 'tse.TSeries');
            tc.verifyEqual(t2.values, t.values);
            tc.verifyTrue(tse.firstdate(t) == tse.firstdate(t2));
        end

        function tseries_roundtrip_monthly(tc)
            t = tse.TSeries(tse.mm(2010, 6), (1:60)');
            t2 = tse.iris.from_tseries(tse.iris.to_tseries(t));
            tc.verifyEqual(t2.values, t.values);
            tc.verifyTrue(tse.firstdate(t) == tse.firstdate(t2));
        end

        function tseries_roundtrip_yearly(tc)
            t = tse.TSeries(tse.yy(1990), (1:30)');
            t2 = tse.iris.from_tseries(tse.iris.to_tseries(t));
            tc.verifyEqual(t2.values, t.values);
        end

        function mvtseries_roundtrip(tc)
            t = tse.MVTSeries(tse.qq(2020, 1), {'gdp','cpi','rate'}, ...
                              reshape(1:60, 20, 3));
            ts = tse.iris.to_tseries(t);
            t2 = tse.iris.from_tseries(ts);
            tc.verifyClass(t2, 'tse.MVTSeries');
            tc.verifyEqual(t2.values, t.values);
            tc.verifyEqual(cellstr(t2.colnames), cellstr(t.colnames));
        end

        function bdaily_to_tseries_errors(tc)
            t = tse.TSeries(tse.bday('2020-01-02'), (1:5)');
            tc.verifyError(@() tse.iris.to_tseries(t), 'tseries:noMatch');
        end

        function db_roundtrip(tc)
            d.gdp = tse.TSeries(tse.qq(2020, 1), (1:10)');
            d.cpi = tse.TSeries(tse.qq(2020, 1), (11:20)');
            d.note = 'a non-series field';

            iris_db = tse.iris.to_db(d);
            tc.verifyClass(iris_db.gdp, 'tseries');
            tc.verifyEqual(iris_db.note, 'a non-series field');

            d2 = tse.iris.from_db(iris_db);
            tc.verifyClass(d2.gdp, 'tse.TSeries');
            tc.verifyEqual(d2.gdp.values, d.gdp.values);
            tc.verifyEqual(d2.cpi.values, d.cpi.values);
            tc.verifyEqual(d2.note, 'a non-series field');
        end

        function check_conflicts_runs_quietly(tc)
            info = tse.iris.check_conflicts('quiet', true);
            tc.verifyTrue(isstruct(info));
            tc.verifyTrue(isfield(info, 'shadowed'));
            % With IRIS on the path, all seven helpers exist in both packages.
            shadowedNames = cellfun(@(s) s.name, info.shadowed, 'UniformOutput', false);
            tc.verifyTrue(any(strcmp('qq', shadowedNames)));
            tc.verifyTrue(any(strcmp('mm', shadowedNames)));
            tc.verifyTrue(any(strcmp('yy', shadowedNames)));
        end

    end
end

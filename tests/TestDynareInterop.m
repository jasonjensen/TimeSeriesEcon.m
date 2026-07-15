classdef TestDynareInterop < matlab.unittest.TestCase
    %TESTDYNAREINTEROP  Round-trip tests for tse.dynare.*.
    %
    %   The whole suite skips cleanly when Dynare's dseries / dates classes
    %   are not on the MATLAB path -- so it stays green in CI environments
    %   without Dynare.

    methods (TestMethodSetup)
        function skipIfNoDynare(tc)
            if ~tse.dynare.isavailable()
                tc.assumeFail('Dynare is not on the path; skipping interop tests.');
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
                tse.Daily(),       365};
            for i = 1:size(pairs, 1)
                F = pairs{i, 1};
                code = pairs{i, 2};
                tc.verifyEqual(tse.dynare.freq_to_dynare(F), code);
                F2 = tse.dynare.freq_from_dynare(code);
                tc.verifyClass(F2, class(F));
            end
        end

        function freq_to_dynare_rejects_bdaily_and_unit(tc)
            tc.verifyError(@() tse.dynare.freq_to_dynare(tse.BDaily()), 'tseries:noMatch');
            tc.verifyError(@() tse.dynare.freq_to_dynare(tse.Unit()),   'tseries:noMatch');
        end

        function quarterly_date_roundtrip(tc)
            m = tse.qq(2020, 3);
            d = tse.dynare.to_date(m);
            tc.verifyClass(d, 'dates');
            m2 = tse.dynare.from_date(d);
            tc.verifyClass(m2, 'tse.MIT');
            tc.verifyTrue(m == m2);
        end

        function monthly_date_roundtrip(tc)
            m = tse.mm(2020, 7);
            d = tse.dynare.to_date(m);
            tc.verifyTrue(m == tse.dynare.from_date(d));
        end

        function yearly_date_roundtrip(tc)
            m = tse.yy(2020);
            d = tse.dynare.to_date(m);
            tc.verifyTrue(m == tse.dynare.from_date(d));
        end

        function bdaily_to_date_errors(tc)
            m = tse.bday('2020-01-02');
            tc.verifyError(@() tse.dynare.to_date(m), 'tseries:noMatch');
        end

        function range_roundtrip_quarterly(tc)
            r = tse.qq(2020, 1):tse.qq(2024, 4);
            d = tse.dynare.to_range(r);
            tc.verifyClass(d, 'dates');
            r2 = tse.dynare.from_range(d);
            tc.verifyTrue(first(r) == first(r2));
            tc.verifyTrue(last(r) == last(r2));
        end

        function dseries_roundtrip_quarterly(tc)
            t = tse.TSeries(tse.qq(2020, 1), (1:40)');
            ds = tse.dynare.to_dseries(t);
            tc.verifyClass(ds, 'dseries');
            t2 = tse.dynare.from_dseries(ds);
            tc.verifyClass(t2, 'tse.TSeries');
            tc.verifyEqual(t2.values, t.values);
            tc.verifyTrue(tse.firstdate(t) == tse.firstdate(t2));
        end

        function dseries_roundtrip_monthly(tc)
            t = tse.TSeries(tse.mm(2010, 6), (1:60)');
            t2 = tse.dynare.from_dseries(tse.dynare.to_dseries(t));
            tc.verifyEqual(t2.values, t.values);
            tc.verifyTrue(tse.firstdate(t) == tse.firstdate(t2));
        end

        function multivariate_dseries_roundtrip(tc)
            t = tse.MVTSeries(tse.qq(2020, 1), {'gdp','cpi','rate'}, ...
                              reshape(1:60, 20, 3));
            ds = tse.dynare.to_dseries(t);
            t2 = tse.dynare.from_dseries(ds);
            tc.verifyClass(t2, 'tse.MVTSeries');
            tc.verifyEqual(t2.values, t.values);
            tc.verifyEqual(cellstr(t2.colnames), cellstr(t.colnames));
        end

        function bdaily_to_dseries_errors(tc)
            t = tse.TSeries(tse.bday('2020-01-02'), (1:5)');
            tc.verifyError(@() tse.dynare.to_dseries(t), 'tseries:noMatch');
        end

        function db_roundtrip(tc)
            d.gdp = tse.TSeries(tse.qq(2020, 1), (1:10)');
            d.cpi = tse.TSeries(tse.qq(2020, 1), (11:20)');
            d.note = 'a non-series field';

            dynare_db = tse.dynare.to_db(d);
            tc.verifyClass(dynare_db.gdp, 'dseries');
            tc.verifyEqual(dynare_db.note, 'a non-series field');

            d2 = tse.dynare.from_db(dynare_db);
            tc.verifyClass(d2.gdp, 'tse.TSeries');
            tc.verifyEqual(d2.gdp.values, d.gdp.values);
            tc.verifyEqual(d2.cpi.values, d.cpi.values);
            tc.verifyEqual(d2.note, 'a non-series field');
        end

        function check_conflicts_runs(tc)
            info = tse.dynare.check_conflicts('quiet', true);
            tc.verifyTrue(isstruct(info));
            tc.verifyTrue(isfield(info, 'shadowed'));
        end

    end
end

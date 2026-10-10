classdef TestMVTSeriesStats < matlab.unittest.TestCase
    %TESTMVTSERIESSTATS  MVTSeries quantile/cov/cor, whole-table
    %   reductions, BDaily skip options on MVTSeries statistics, stdm/varm
    %   and bdvalues.  Mirrors TimeSeriesEcon.jl src/tsmath.jl (Statistics
    %   overloads) and the matching TimeSeriesEconPy functions.

    properties (Constant)
        V = [1 10; 2 30; 4 20; 8 50; 16 40]
    end

    methods (TestMethodTeardown)
        function clearMap(~)
            tse.clear_holidays_map();
        end
    end

    methods (Test)
        % ---- whole-table reductions use every value ----

        function reductions_without_dims_use_all_values(tc)
            x = tse.MVTSeries(tse.qq(2020, 1), {'a', 'b'}, tc.V);
            v = tc.V(:);
            tc.verifyEqual(mean(x), mean(v), 'AbsTol', 1e-12);
            tc.verifyEqual(median(x), median(v));
            tc.verifyEqual(std(x), std(v), 'AbsTol', 1e-12);
            tc.verifyEqual(var(x), var(v), 'AbsTol', 1e-12);
            tc.verifyEqual(sum(x), sum(v));
            tc.verifyEqual(min(x), 1);
            tc.verifyEqual(max(x), 50);
        end

        function min_max_along_dims(tc)
            x = tse.MVTSeries(tse.qq(2020, 1), {'a', 'b'}, tc.V);
            tc.verifyEqual(min(x, 'dims', 1), [1 10]);
            tc.verifyEqual(max(x, 'dims', 1), [16 50]);
            r = max(x, 'dims', 2);
            tc.verifyClass(r, 'tse.TSeries');
            tc.verifyEqual(rawdata(r), [10; 30; 20; 50; 40]);
        end

        % ---- quantile ----

        function quantile_over_all_values(tc)
            x = tse.MVTSeries(tse.qq(2020, 1), {'a', 'b'}, tc.V);
            tc.verifyEqual(quantile(x, 0.5), quantile(tc.V(:), 0.5));
        end

        function quantile_along_dims(tc)
            x = tse.MVTSeries(tse.qq(2020, 1), {'a', 'b'}, tc.V);
            tc.verifyEqual(quantile(x, 0.5, 'dims', 1), quantile(tc.V, 0.5, 1));
            r = quantile(x, 0.5, 'dims', 2);
            tc.verifyClass(r, 'tse.TSeries');
            tc.verifyEqual(rawdata(r), quantile(tc.V, 0.5, 2));
        end

        % ---- cov / cor ----

        function cov_cor_matrices(tc)
            x = tse.MVTSeries(tse.qq(2020, 1), {'a', 'b'}, tc.V);
            tc.verifyEqual(cov(x), cov(tc.V), 'AbsTol', 1e-12);
            tc.verifyEqual(cor(x), corrcoef(tc.V), 'AbsTol', 1e-12);
            tc.verifySize(cor(x), [2 2]);
            tc.verifyEqual(diag(cor(x)), [1; 1], 'AbsTol', 1e-12);
        end

        % ---- BDaily skip options on MVTSeries ----

        function bdaily_skip_all_nans(tc)
            x = bdailyTable();
            kept = [1 2; 4 8; 5 10];
            tc.verifyTrue(isnan(mean(x)));
            tc.verifyEqual(mean(x, 'skip_all_nans', true), mean(kept(:)), 'AbsTol', 1e-12);
            tc.verifyEqual(mean(x, 'skip_all_nans', true, 'dims', 1), mean(kept, 1), 'AbsTol', 1e-12);
            tc.verifyEqual(std(x, 'skip_all_nans', true), std(kept(:)), 'AbsTol', 1e-12);
            tc.verifyEqual(median(x, 'skip_all_nans', true), median(kept(:)));
            tc.verifyEqual(quantile(x, 0.25, 'skip_all_nans', true), quantile(kept(:), 0.25));
            tc.verifyEqual(cov(x, 'skip_all_nans', true), cov(kept), 'AbsTol', 1e-12);
            tc.verifyEqual(cor(x, 'skip_all_nans', true), corrcoef(kept), 'AbsTol', 1e-12);
        end

        function bdaily_dims2_after_skipping_is_plain(tc)
            x = bdailyTable();
            r = mean(x, 'skip_all_nans', true, 'dims', 2);
            tc.verifyTrue(isnumeric(r));
            tc.verifyEqual(r, [1.5; 6; 7.5]);
        end

        function bdaily_holidays_map(tc)
            x = bdailyTable();
            map = tse.TSeries(x.firstdate, logical([1 0 0 1 1]'));
            kept = [1 2; 4 8; 5 10];
            tc.verifyEqual(var(x, 'holidays_map', map), var(kept(:)), 'AbsTol', 1e-12);
        end

        % ---- stdm / varm ----

        function stdm_varm(tc)
            t = tse.TSeries(tse.qq(2020, 1), [1; 2; 3]);
            tc.verifyEqual(varm(t, 2), 1);
            tc.verifyEqual(stdm(t, 2), 1);
            tc.verifyEqual(varm(t, 0), 7, 'AbsTol', 1e-12);
            tc.verifyTrue(isnan(varm(tse.TSeries(tse.qq(2020, 1), 5), 5)));
        end

        function stdm_bdaily_skip(tc)
            t = tse.TSeries(tse.bday('2021-01-04'), [1; NaN; 2; 3]);
            tc.verifyTrue(isnan(stdm(t, 2)));
            tc.verifyEqual(stdm(t, 2, 'skip_all_nans', true), 1);
        end

        % ---- two-series cov / cor ----

        function cov_two_series_is_scalar(tc)
            a = tse.TSeries(tse.qq(2020, 1), [1; 2; 3; 4]);
            b = tse.TSeries(tse.qq(2020, 1), [2; 4; 5; 9]);
            c = cov([[1; 2; 3; 4], [2; 4; 5; 9]]);
            tc.verifyEqual(cov(a, b), c(1, 2), 'AbsTol', 1e-12);
            r = corrcoef([1; 2; 3; 4], [2; 4; 5; 9]);
            tc.verifyEqual(cor(a, b), r(1, 2), 'AbsTol', 1e-12);
        end

        function cov_cor_need_aligned_series(tc)
            a = tse.TSeries(tse.qq(2020, 1), [1; 2; 3; 4]);
            b = tse.TSeries(tse.qq(2020, 2), [2; 4; 5; 9]);
            tc.verifyError(@() cov(a, b), 'tseries:noMatch');
            tc.verifyError(@() cor(a, b), 'tseries:noMatch');
        end

        % ---- bdvalues ----

        function bdvalues_with_and_without_map(tc)
            x = bdailyTable();
            tc.verifyEqual(tse.bdvalues(x), rawdata(x));
            map = tse.TSeries(x.firstdate, logical([1 0 0 1 1]'));
            tc.verifyEqual(tse.bdvalues(x, 'holidays_map', map), [1 2; 4 8; 5 10]);
            t = x('a');
            tc.verifyEqual(tse.bdvalues(t, 'holidays_map', map), [1; 4; 5]);
        end

        function bdvalues_requires_bdaily(tc)
            t = tse.TSeries(tse.qq(2020, 1), [1; 2]);
            tc.verifyError(@() tse.bdvalues(t), 'tseries:noMatch');
        end
    end
end

function x = bdailyTable()
    % Monday 2021-01-04 .. Friday 2021-01-08; rows 2 and 3 hold NaNs.
    x = tse.MVTSeries(tse.bday('2021-01-04'), {'a', 'b'}, ...
        [1 2; NaN 4; 3 NaN; 4 8; 5 10]);
end

classdef TestBDailyStatistics < matlab.unittest.TestCase
    %TESTBDAILYSTATISTICS  Tests for BDaily statistics with skip_all_nans
    %   and skip_holidays, plus cleanedvalues.

    methods (TestMethodTeardown)
        function clearMap(~)
            tse.clear_holidays_map();
        end
    end

    properties (Constant)
        bonds_data = [NaN, 0.68, 0.7, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86, ...
            0.81, 0.8, 0.8, 0.83, 0.87, 0.84, 0.81, 0.82, 0.8, 0.82, ...
            0.84, 0.88, 0.91, 0.94, 0.96, 1, 1.01, 0.99, 0.99, 0.99, ...
            1.03, NaN, 1.12, 1.11, 1.14, 1.21, 1.23, 1.26, 1.31, 1.46, ...
            1.35, 1.35, 1.33, 1.4, 1.49, 1.5, 1.53, 1.45, 1.41, 1.43, ...
            1.58, 1.54, 1.56, 1.58, 1.61, 1.59, 1.55, 1.49, 1.47, 1.46, ...
            1.49, 1.53, 1.53, 1.55, 1.51, NaN, 1.56, 1.49, 1.5, 1.46, ...
            1.5, 1.51, 1.5, 1.53, 1.45, 1.53, 1.53, 1.5, 1.52, 1.52, ...
            1.51, 1.53, 1.56, 1.53, 1.56, 1.54, 1.52, 1.53, 1.51, 1.51, ...
            1.49, 1.51, 1.54, 1.59, 1.56, 1.55, 1.57, 1.56, 1.58, 1.54, ...
            1.54, NaN, 1.46, 1.45, 1.49, 1.49, 1.49, 1.5, 1.49, 1.52, ...
            1.46, 1.47, 1.45, 1.41, 1.38, 1.38, 1.39, 1.38, 1.44, 1.4, ...
            1.37, 1.41, 1.4, 1.42, 1.41, 1.45, 1.41, 1.42, 1.39, NaN, ...
            1.37, 1.4, 1.32, 1.29, 1.26, 1.32, 1.32, 1.34, 1.29, 1.26, ...
            1.24, 1.14, 1.17, 1.22, 1.19, 1.21, 1.22, 1.16, 1.17, 1.19, ...
            1.2, NaN, 1.12, 1.13, 1.16, 1.24, 1.25, 1.27, 1.26, 1.25, ...
            1.19, 1.16, 1.15, 1.16, 1.13, 1.14, 1.16, 1.18, 1.25, 1.23, ...
            1.2, 1.18, 1.22, 1.18, 1.15, 1.19, NaN, 1.23, 1.2, 1.17, ...
            1.23, 1.22, 1.17, 1.22, 1.23, 1.29, 1.22, 1.22, 1.21, 1.33, ...
            1.38, 1.41, 1.5, 1.51, NaN, 1.47, 1.49, 1.53, 1.5, 1.56, ...
            1.62, NaN, 1.62, 1.61, 1.53, 1.58, 1.58, 1.63, 1.63, 1.68, ...
            1.65, 1.65, 1.63, 1.6, 1.66, 1.72, 1.74, 1.72, 1.71, 1.64, ...
            1.59, 1.63, 1.59, 1.68, NaN, 1.67, 1.72, 1.77, 1.7, 1.69, ...
            1.66, 1.76, 1.81, 1.77, 1.77, 1.59, 1.61, 1.58, 1.5, 1.49, ...
            1.45, 1.51, 1.58, 1.56, 1.5, 1.47, 1.4, 1.43, 1.41, 1.35, ...
            1.32, 1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42]';
    end

    methods (Test)

        %% --- cleanedvalues ---

        function cleanedvalues_skip_all_nans(tc)
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            tc.verifyEqual(length(tsbd), 261);
            v = tse.cleanedvalues(tsbd, 'skip_all_nans', true);
            % Should have removed all NaN entries
            tc.verifyTrue(~any(isnan(v)));
            tc.verifyEqual(numel(v), sum(~isnan(tc.bonds_data)));
        end

        function cleanedvalues_skip_holidays(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            v = tse.cleanedvalues(tsbd, 'skip_holidays', true);
            % Holidays removed -> fewer values than original
            tc.verifyTrue(numel(v) < numel(tc.bonds_data));
        end

        function cleanedvalues_holidays_map(tc)
            tse.set_holidays_map('CA', 'ON');
            hmap = tse.getoption('bdaily_holidays_map');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            v1 = tse.cleanedvalues(tsbd, 'skip_holidays', true);
            v2 = tse.cleanedvalues(tsbd, 'holidays_map', hmap);
            tc.verifyEqual(v1, v2);
        end

        function cleanedvalues_no_map_errors(tc)
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            % Without a holidays map loaded, skip_holidays should error
            tc.verifyError(@() tse.cleanedvalues(tsbd, 'skip_holidays', true), ...
                'tse:cleanedvalues');
        end

        function cleanedvalues_default_returns_all(tc)
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            v = tse.cleanedvalues(tsbd);
            tc.verifyEqual(v, tc.bonds_data);
        end

        %% --- mean ---

        function mean_with_nans_is_nan(tc)
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            tc.verifyTrue(isnan(mean(tsbd)));
        end

        function mean_skip_all_nans(tc)
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            r = mean(tsbd, 'skip_all_nans', true);
            tc.verifyEqual(r, 1.363253012048193, 'AbsTol', 1e-10);
        end

        function mean_skip_holidays_full_is_nan(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            % Full series still has NaN on non-holiday business days
            tc.verifyTrue(isnan(mean(tsbd, 'skip_holidays', true)));
        end

        function mean_skip_holidays_subrange(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            r = mean(sub, 'skip_holidays', true);
            tc.verifyEqual(r, 1.39125, 'AbsTol', 1e-5);
        end

        function mean_skip_all_nans_subrange(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            r = mean(sub, 'skip_all_nans', true);
            tc.verifyEqual(r, 1.39125, 'AbsTol', 1e-5);
        end

        %% --- std ---

        function std_skip_holidays_subrange(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            r = std(sub, 'skip_holidays', true);
            tc.verifyEqual(r, 0.066174256762464, 'AbsTol', 1e-10);
        end

        function std_skip_all_nans_subrange(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            r = std(sub, 'skip_all_nans', true);
            tc.verifyEqual(r, 0.066174256762464, 'AbsTol', 1e-10);
        end

        %% --- var ---

        function var_skip_holidays_subrange(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            r = var(sub, 'skip_holidays', true);
            tc.verifyEqual(r, 0.0043790322580645, 'AbsTol', 1e-10);
        end

        function var_skip_all_nans_subrange(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            r = var(sub, 'skip_all_nans', true);
            tc.verifyEqual(r, 0.0043790322580645, 'AbsTol', 1e-10);
        end

        %% --- median ---

        function median_skip_holidays_subrange(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            r = median(sub, 'skip_holidays', true);
            tc.verifyEqual(r, 1.4, 'AbsTol', 1e-10);
        end

        function median_skip_all_nans_subrange(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            r = median(sub, 'skip_all_nans', true);
            tc.verifyEqual(r, 1.4, 'AbsTol', 1e-10);
        end

        %% --- quantile ---

        function quantile_skip_holidays_subrange(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            r = quantile(sub, [0.25, 0.5, 0.75], 'skip_holidays', true);
            tc.verifyEqual(r, [1.3625, 1.4, 1.425], 'AbsTol', 1e-3);
        end

        function quantile_skip_all_nans_subrange(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            r = quantile(sub, 0.98, 'skip_all_nans', true);
            tc.verifyEqual(r, 1.5076, 'AbsTol', 1e-3);
        end

        %% --- cov ---

        function cov_single_skip_holidays(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            tc.verifyTrue(isnan(cov(sub)));
            r = cov(sub, 'skip_holidays', true);
            tc.verifyEqual(r, 0.0043790322580645, 'AbsTol', 1e-6);
        end

        function cov_two_series_skip(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            rng2 = rand(size(sub.values));
            noisy = tse.TSeries(sub.firstdate, sub.values + rng2);
            r = cov(sub, noisy, 'skip_holidays', true);
            tc.verifyTrue(r < 1.0);
        end

        %% --- cor ---

        function cor_single_is_one(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            r = cor(sub, 'skip_holidays', true);
            tc.verifyEqual(r, 1.0, 'AbsTol', 1e-10);
        end

        function cor_skip_all_nans(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            r = cor(tsbd, 'skip_holidays', true);
            tc.verifyEqual(r, 1.0, 'AbsTol', 1e-10);
        end

        function cor_two_series_skip(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            rng = tse.bday('2021-06-01', '2021-07-15');
            sub = tsbd(rng);
            rng2 = rand(size(sub.values));
            noisy = tse.TSeries(sub.firstdate, sub.values + rng2);
            r = cor(sub, noisy, 'skip_holidays', true);
            tc.verifyTrue(r < 1.0);
        end

        %% --- cleanedvalues MVTSeries ---

        function cleanedvalues_mvts_skip_holidays(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            tsbd2 = tsbd * 2;
            mvts = tse.MVTSeries(tse.rangeof(tsbd), ["t1", "t2"], [tsbd.values, tsbd2.values]);
            lastRng = tse.bday('2021-12-20', '2021-12-31');
            v = tse.cleanedvalues(mvts(lastRng), 'skip_holidays', true);
            % Should return a matrix with 2 columns and fewer rows
            tc.verifyEqual(size(v, 2), 2);
            tc.verifyTrue(size(v, 1) < length(lastRng));
        end

        function cleanedvalues_mvts_skip_all_nans(tc)
            tse.set_holidays_map('CA', 'ON');
            tsbd = tse.TSeries(tse.bday('2021-01-01'), tc.bonds_data);
            tsbd2 = tsbd * 2;
            mvts = tse.MVTSeries(tse.rangeof(tsbd), ["t1", "t2"], [tsbd.values, tsbd2.values]);
            lastRng = tse.bday('2021-12-20', '2021-12-31');
            v = tse.cleanedvalues(mvts(lastRng), 'skip_all_nans', true);
            % No NaN in any row
            tc.verifyTrue(~any(isnan(v(:))));
        end
    end
end

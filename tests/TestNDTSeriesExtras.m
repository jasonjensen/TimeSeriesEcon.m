classdef TestNDTSeriesExtras < matlab.unittest.TestCase
    %TESTNDTSERIESEXTRAS  tse.NDTSeries step 5: element-wise arithmetic,
    %   cat, rename, strip_ts, overlay and fconvert.

    methods (Static)
        function x = sample()
            rng = tse.qq(2020,1):tse.qq(2020,4);
            x = tse.NDTSeries({rng, ["a" "b"], 3}, reshape(1:24, 4, 2, 3));
        end
    end

    methods (Test)

        % ---------- arithmetic ----------

        function with_scalars_and_arrays(tc)
            x = TestNDTSeriesExtras.sample();
            v = x.values;
            y = 2 * x + 1;
            tc.verifyClass(y, 'tse.NDTSeries');
            tc.verifyTrue(isequal(y.axes, x.axes));
            tc.verifyEqual(y.values, 2 * v + 1);
            tc.verifyEqual((x / 4).values, v / 4);
            tc.verifyEqual((10 - x).values, 10 - v);
            tc.verifyEqual((x .^ 2).values, v .^ 2);
            tc.verifyEqual((x + v).values, 2 * v);
            tc.verifyEqual((-x).values, -v);
            tc.verifyEqual(log(x).values, log(v));
            tc.verifyEqual(exp(x / 100).values, exp(v / 100), 'AbsTol', 1e-12);
            tc.verifyEqual(abs(-x).values, v);
            tc.verifyError(@() x + ones(2, 2), 'tseries:dimMismatch');
            tc.verifyError(@() x * ones(4, 2, 3), 'tseries:noMatch');
            tc.verifyError(@() x + "a", 'tseries:noMatch');
        end

        function comparisons_give_logical_series(tc)
            x = TestNDTSeriesExtras.sample();
            b = x > 12;
            tc.verifyClass(b, 'tse.NDTSeries');
            tc.verifyClass(b.values, 'logical');
            tc.verifyEqual(b.values, x.values > 12);
            tc.verifyEqual(((x > 5) & (x < 9)).values, x.values > 5 & x.values < 9);
            tc.verifyEqual((~(x == 3)).values, x.values ~= 3);
            tc.verifyEqual(sum(x >= 20), 5);
        end

        function aligned_series(tc)
            x = TestNDTSeriesExtras.sample();
            y = x - x;
            tc.verifyEqual(y.values, zeros(4, 2, 3));
            % different date ranges: cut to the common dates
            z = tse.NDTSeries({tse.qq(2020,3):tse.qq(2021,2), ["a" "b"], 3}, 1);
            s = x + z;
            tc.verifyTrue(isequal(rangeof(s), tse.qq(2020,3):tse.qq(2020,4)));
            tc.verifyEqual(s.values, x.values(3:4, :, :) + 1);
            % no common dates: empty
            w = tse.NDTSeries({tse.qq(2022,1):tse.qq(2022,2), ["a" "b"], 3}, 1);
            tc.verifyEqual(size(x + w), [0 2 3]);
        end

        function aligned_with_tseries_and_mvtseries(tc)
            m = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,3), {'a','b'}, [1 2; 3 4; 5 6]);
            x = tse.NDTSeries(m);
            r = x .* m;
            tc.verifyClass(r, 'tse.NDTSeries');
            tc.verifyEqual(r.values, m.values .^ 2);
            t = tse.TSeries(tse.qq(2020,2), [10; 20; 30]);
            u = tse.NDTSeries(t) + t;
            tc.verifyEqual(u.values, [20; 40; 60]);
        end

        function misaligned_series_are_errors(tc)
            x = TestNDTSeriesExtras.sample();
            tc.verifyError(@() x + permute(x, [1 3 2]), 'tseries:dimMismatch');
            y = rename(x, "b", "c");
            tc.verifyError(@() x + y, 'tseries:dimMismatch');
            z = tse.NDTSeries({tse.qq(2020,1):tse.qq(2020,4), ["a" "b"], 2}, 1);
            tc.verifyError(@() x + z, 'tseries:dimMismatch');
            q = tse.NDTSeries({tse.mm(2020,1):tse.mm(2020,4), ["a" "b"], 3}, 1);
            tc.verifyError(@() x + q, 'tseries:mixedFreq');
            % broadcasting a TSeries across the other axes is not supported
            t = tse.TSeries(tse.qq(2020,1), (1:4)');
            tc.verifyError(@() x + t, 'tseries:dimMismatch');
        end

        % ---------- combining ----------

        function cat_along_each_kind(tc)
            x = TestNDTSeriesExtras.sample();
            more = tse.NDTSeries({tse.qq(2020,1):tse.qq(2020,4), ["c"], 3}, 0);
            c = cat(2, x, more);
            tc.verifyEqual(names(c), ["a" "b" "c"]);
            tc.verifyEqual(c.values(:, 1:2, :), x.values);
            c3 = cat(3, x, x);
            tc.verifyEqual(size(c3), [4 2 6]);
            later = tse.NDTSeries({tse.qq(2021,1):tse.qq(2021,2), ["a" "b"], 3}, -1);
            ct = cat(1, x, later);
            tc.verifyTrue(isequal(rangeof(ct), tse.qq(2020,1):tse.qq(2021,2)));
            tc.verifyEqual(ct.values(5:6, :, :), -ones(2, 2, 3));
            tc.verifyError(@() cat(2, x, x), 'tseries:noMatch');          % repeated names
            gap = tse.NDTSeries({tse.qq(2021,2):tse.qq(2021,3), ["a" "b"], 3}, 0);
            tc.verifyError(@() cat(1, x, gap), 'tseries:noMatch');
            tc.verifyError(@() cat(2, x, c3), 'tseries:dimMismatch');
            tc.verifyError(@() [x, x], 'tseries:noMatch');
        end

        function rename_names(tc)
            x = TestNDTSeriesExtras.sample();
            y = rename(x, "a", "gdp");
            tc.verifyEqual(names(y), ["gdp" "b"]);
            tc.verifyEqual(y.values, x.values);
            z = rename(x, ["a" "b"], {'p', 'q'});
            tc.verifyEqual(names(z), ["p" "q"]);
            tc.verifyError(@() rename(x, "a", "b"), 'tseries:noMatch');
            tc.verifyError(@() rename(x, "zz", "y"), 'tseries:bounds');
        end

        function strip_missing_dates(tc)
            v = nan(5, 2);
            v(2, 1) = 1;
            v(4, 2) = 2;
            x = tse.NDTSeries({tse.qq(2020,1):tse.qq(2021,1), ["a" "b"]}, v);
            s = tse.strip_ts(x);
            tc.verifyTrue(isequal(rangeof(s), tse.qq(2020,2):tse.qq(2020,4)));
            tc.verifyEqual(s.values, v(2:4, :));
            tc.verifyTrue(isequaln(strip_ts(x), s));
            e = tse.strip_ts(tse.NDTSeries({tse.qq(2020,1):tse.qq(2020,2), 2}));
            tc.verifyEqual(size(e), [0 2]);
            one = tse.strip_ts(tse.NDTSeries(tse.qq(2020,1):tse.qq(2020,3), [NaN 1 NaN]));
            tc.verifyEqual(one.values, 1);
        end

        function overlay_first_valid_wins(tc)
            a = tse.NDTSeries({tse.qq(2020,1):tse.qq(2020,3), ["x" "y"]}, [1 NaN; NaN 2; 3 3]);
            b = tse.NDTSeries({tse.qq(2020,2):tse.qq(2020,4), ["x" "y"]}, 9);
            o = tse.overlay(a, b);
            tc.verifyTrue(isequal(rangeof(o), tse.qq(2020,1):tse.qq(2020,4)));
            tc.verifyEqual(o.values, [1 NaN; 9 2; 3 3; 9 9]);
            r = tse.overlay(tse.qq(2020,2):tse.qq(2020,3), a, b);
            tc.verifyEqual(r.values, [9 2; 3 3]);
            c = tse.NDTSeries({tse.qq(2020,1):tse.qq(2020,3), ["x" "z"]}, 0);
            tc.verifyError(@() tse.overlay(a, c), 'tseries:dimMismatch');
        end

        % ---------- fconvert ----------

        function fconvert_along_the_date_axis(tc)
            x = tse.NDTSeries({["a" "b"], tse.mm(2020,1):tse.mm(2020,12), 2}, ...
                reshape(1:48, 2, 12, 2));
            q = tse.fconvert(tse.Quarterly(), x, 'method', 'sum');
            tc.verifyClass(q, 'tse.NDTSeries');
            tc.verifyEqual(size(q), [2 4 2]);
            tc.verifyEqual([q.axes.kind], ["names" "range" "plain"]);
            tc.verifyTrue(eq(firstdate(q), tse.qq(2020,1)));
            for i = 1:2
                for k = 1:2
                    t = tse.TSeries(tse.mm(2020,1), squeeze(x.values(i, :, k))');
                    tq = tse.fconvert(tse.Quarterly(), t, 'method', 'sum');
                    tc.verifyEqual(squeeze(q.values(i, :, k))', tq.values);
                end
            end
            m = tse.fconvert(tse.Monthly(), q, 'method', 'even');
            tc.verifyEqual(size(m), [2 12 2]);
            tc.verifyTrue(isequal(tse.fconvert(tse.Quarterly(), q), q));
            v = tse.NDTSeries({tse.yy(2019):tse.yy(2020), tse.mm(2020,1):tse.mm(2020,6)}, 1);
            vq = tse.fconvert(tse.Quarterly(), v, 'dims', 2);
            tc.verifyEqual(size(vq), [2 2]);
            tc.verifyError(@() tse.fconvert(tse.Quarterly(), v), 'tseries:noMatch');
            one = tse.NDTSeries(tse.mm(2020,1):tse.mm(2020,6), (1:6)');
            o = tse.fconvert(tse.Quarterly(), one);
            tc.verifyEqual(o.values, [2; 5]);
        end
    end
end

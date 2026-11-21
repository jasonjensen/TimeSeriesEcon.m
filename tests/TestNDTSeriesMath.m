classdef TestNDTSeriesMath < matlab.unittest.TestCase
    %TESTNDTSERIESMATH  tse.NDTSeries step 3: time functions along the
    %   date axis, reductions with 'dims', and mapslices.  Each result is
    %   checked against the same operation on the values array (or on an
    %   equivalent TSeries).

    methods (Static)
        function x = sample()
            % 4 quarters x names a,b x 3 plain, all values positive
            rng = tse.qq(2020,1):tse.qq(2020,4);
            v = zeros(4, 2, 3);
            for i = 1:4, for j = 1:2, for k = 1:3
                v(i, j, k) = 100*k + 10*j + i^2;
            end, end, end
            x = tse.NDTSeries({rng, ["a" "b"], 3}, v);
        end
    end

    methods (Test)

        % ---------- shifting ----------

        function lag_lead_shift(tc)
            x = TestNDTSeriesMath.sample();
            l = lag(x);
            tc.verifyTrue(eq(firstdate(l), tse.qq(2020,2)));
            tc.verifyEqual(l.values, x.values);
            tc.verifyTrue(eq(firstdate(lag(x, 2)), tse.qq(2020,3)));
            tc.verifyTrue(eq(firstdate(lead(x)), tse.qq(2019,4)));
            tc.verifyTrue(eq(firstdate(shift(x, 1)), tse.qq(2019,4)));   % like TSeries shift
            t = tse.TSeries(tse.qq(2020,1), (1:4)');
            tc.verifyTrue(eq(firstdate(shift(x, 2)), shift(t, 2).firstdate));
        end

        function lag_on_a_chosen_date_axis(tc)
            v = tse.NDTSeries({tse.yy(2019):tse.yy(2020), tse.mm(2020,1):tse.mm(2020,3)}, 1);
            l = lag(v, 'dims', 2);
            tc.verifyTrue(eq(firstdate(l, 'dims', 2), tse.mm(2020,2)));
            tc.verifyTrue(eq(firstdate(l, 'dims', 1), tse.yy(2019)));
            tc.verifyError(@() lag(v), 'tseries:noMatch');
        end

        % ---------- differences and growth ----------

        function diff_matches_tseries(tc)
            x = TestNDTSeriesMath.sample();
            d = diff(x);
            tc.verifyTrue(eq(firstdate(d), tse.qq(2020,2)));
            tc.verifyEqual(size(d), [3 2 3]);
            tc.verifyEqual(d.values, diff(x.values, 1, 1));
            t = tse.TSeries(tse.qq(2020,1), x.values(:, 2, 3));
            dt = diff(t);
            tc.verifyEqual(squeeze(d.values(:, 2, 3)), dt.values);
            d2 = diff(x, -2);
            tc.verifyTrue(eq(firstdate(d2), tse.qq(2020,3)));
            tc.verifyEqual(d2.values, x.values(3:4, :, :) - x.values(1:2, :, :));
            df = diff(x, 1);      % forward difference, as for TSeries
            dtf = diff(t, 1);
            tc.verifyTrue(eq(firstdate(df), dtf.firstdate));
            tc.verifyEqual(squeeze(df.values(:, 2, 3)), dtf.values);
        end

        function pct_apct_match_tseries(tc)
            x = TestNDTSeriesMath.sample();
            t = tse.TSeries(tse.qq(2020,1), x.values(:, 1, 2));
            p = pct(x);
            pt = pct(t);
            tc.verifyTrue(eq(firstdate(p), pt.firstdate));
            tc.verifyEqual(squeeze(p.values(:, 1, 2)), pt.values, 'AbsTol', 1e-12);
            xl = tse.NDTSeries(x.axes, log(x.values));
            p2 = pct(xl, -1, 'islog', true);
            tc.verifyEqual(p2.values, p.values, 'AbsTol', 1e-9);
            a = apct(x);
            at = apct(t);
            tc.verifyEqual(squeeze(a.values(:, 1, 2)), at.values, 'AbsTol', 1e-9);
            tc.verifyTrue(eq(firstdate(a), at.firstdate));
        end

        function ytypct_matches_tseries(tc)
            v = reshape(1:24, 8, 3) + 10;
            x = tse.NDTSeries({tse.qq(2020,1):tse.qq(2021,4), 3}, v);
            y = ytypct(x);
            t = tse.TSeries(tse.qq(2020,1), v(:, 2));
            yt = ytypct(t);
            tc.verifyTrue(eq(firstdate(y), yt.firstdate));
            tc.verifyEqual(y.values(:, 2), yt.values, 'AbsTol', 1e-12);
            tc.verifyEqual(size(y), [4 3]);
        end

        function cumulative(tc)
            x = TestNDTSeriesMath.sample();
            c = cumsum(x);
            tc.verifyEqual(c.values, cumsum(x.values, 1));
            tc.verifyTrue(isequal(c.axes, x.axes));
            c3 = cumsum(x, 3);
            tc.verifyEqual(c3.values, cumsum(x.values, 3));
            cp = cumprod(x, 'dims', 2);
            tc.verifyEqual(cp.values, cumprod(x.values, 2));
        end

        function moving_windows(tc)
            x = TestNDTSeriesMath.sample();
            m = moving_sum(x, 2);
            tc.verifyTrue(eq(firstdate(m), tse.qq(2020,2)));
            tc.verifyEqual(m.values, x.values(1:3, :, :) + x.values(2:4, :, :));
            a = moving_average(x, 3);
            t = tse.TSeries(tse.qq(2020,1), x.values(:, 2, 1));
            at = moving_average(t, 3);
            tc.verifyTrue(eq(firstdate(a), at.firstdate));
            tc.verifyEqual(squeeze(a.values(:, 2, 1)), at.values, 'AbsTol', 1e-12);
            f = moving(x, -2);
            ft = moving(t, -2);
            tc.verifyTrue(eq(firstdate(f), ft.firstdate));
            tc.verifyEqual(squeeze(f.values(:, 2, 1)), ft.values, 'AbsTol', 1e-12);
            tc.verifyError(@() moving(x, 5), 'tseries:dimMismatch');
        end

        % ---------- reductions ----------

        function reduce_everything(tc)
            x = TestNDTSeriesMath.sample();
            v = x.values;
            tc.verifyEqual(sum(x), sum(v(:)));
            tc.verifyEqual(mean(x), mean(v(:)));
            tc.verifyEqual(max(x), max(v(:)));
            tc.verifyEqual(std(x), std(v(:)), 'AbsTol', 1e-12);
            tc.verifyEqual(std(x, 1), std(v(:), 1), 'AbsTol', 1e-12);
        end

        function reduce_one_axis(tc)
            x = TestNDTSeriesMath.sample();
            v = x.values;
            s1 = sum(x, 'dims', 1);              % names x plain
            tc.verifyClass(s1, 'tse.NDTSeries');
            tc.verifyEqual([s1.axes.kind], ["names" "plain"]);
            tc.verifyEqual(s1.values, squeeze(sum(v, 1)));
            s3 = mean(x, 'dims', 3);             % dates x names -> MVTSeries
            tc.verifyClass(s3, 'tse.MVTSeries');
            tc.verifyEqual(s3.values, mean(v, 3), 'AbsTol', 1e-12);
            st = std(x, 'dims', "time");
            tc.verifyEqual(st.values, squeeze(std(v, 0, 1)), 'AbsTol', 1e-12);
            mn = min(x, 'dims', 2);
            tc.verifyEqual(mn.values, squeeze(min(v, [], 2)));
            md = median(x, 'dims', 1);
            tc.verifyEqual(md.values, squeeze(median(v, 1)));
            q = quantile(x, 0.5, 'dims', 1);
            tc.verifyEqual(q.values, md.values, 'AbsTol', 1e-12);
            vv = var(x, 1, 'dims', 3);
            tc.verifyEqual(vv.values, var(v, 1, 3), 'AbsTol', 1e-9);
        end

        function reduce_several_axes(tc)
            x = TestNDTSeriesMath.sample();
            v = x.values;
            t = sum(x, 'dims', [2 3]);          % only dates left -> TSeries
            tc.verifyClass(t, 'tse.TSeries');
            tc.verifyEqual(t.values, sum(sum(v, 2), 3));
            tc.verifyEqual(sum(x, 'dims', [1 2 3]), sum(v(:)));
            tc.verifyError(@() sum(x, 'dims', 4), 'tseries:noMatch');
        end

        function reduce_logical(tc)
            x = tse.NDTSeries({tse.qq(2020,1):tse.qq(2020,2), ["a" "b"]}, logical([1 0; 1 1]));
            tc.verifyTrue(any(x));
            tc.verifyFalse(all(x));
            a = all(x, 'dims', 1);
            tc.verifyEqual(a.values, [true; false]);
            tc.verifyEqual(a.axes(1).names, ["a" "b"]);
        end

        function reduce_with_flags(tc)
            x = tse.NDTSeries({tse.qq(2020,1):tse.qq(2020,3), 2}, [1 NaN; 2 3; 3 5]);
            tc.verifyTrue(isnan(sum(x)));
            tc.verifyEqual(sum(x, 'omitnan'), 14);
            s = mean(x, 'dims', 1, 'omitnan');
            tc.verifyEqual(s.values, [2; 4]);
        end

        % ---------- mapslices ----------

        function mapslices_forms(tc)
            x = TestNDTSeriesMath.sample();
            dm = mapslices(x, @(v) v - mean(v));          % along the date axis
            tc.verifyClass(dm, 'tse.NDTSeries');
            tc.verifyEqual(dm.values, x.values - mean(x.values, 1), 'AbsTol', 1e-12);
            s = mapslices(x, @sum, 'dims', 1);            % one value per slice
            tc.verifyClass(s, 'tse.NDTSeries');
            tc.verifyEqual(s.values, squeeze(sum(x.values, 1)));
            m = mapslices(x, @(v) max(v(:)), 'dims', [1 2]);
            tc.verifyEqual(m.values, squeeze(max(max(x.values, [], 1), [], 2)));
            raw = mapslices(x, @(v) [v; v], 'dims', 1);   % other shapes: plain array
            tc.verifyEqual(size(raw), [8 2 3]);
        end

        % ---------- MVTSeries fix found along the way ----------

        function mvtseries_std_var_with_dims(tc)
            % std(m, 'dims', d) passed d as the weight
            v = [1 2 4; 3 5 9; 4 4 1; 8 2 0];
            m = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a','b','c'}, v);
            tc.verifyEqual(std(m, 'dims', 1), std(v, 0, 1), 'AbsTol', 1e-12);
            tc.verifyEqual(var(m, 'dims', 1), var(v, 0, 1), 'AbsTol', 1e-12);
            s2 = std(m, 'dims', 2);
            tc.verifyClass(s2, 'tse.TSeries');
            tc.verifyEqual(s2.values, std(v, 0, 2), 'AbsTol', 1e-12);
        end
    end
end

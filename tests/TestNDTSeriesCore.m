classdef TestNDTSeriesCore < matlab.unittest.TestCase
    %TESTNDTSERIESCORE  tse.NDTSeries step 1: construction, shape, axes,
    %   conversion, comparison and display.  NDTSeries is a MATLAB
    %   addition (no Julia or Python counterpart), so these are not mirrors.

    methods (Static)
        function x = sample()
            % 4 quarters x 2 names x 3 plain: value = 100*k + 10*j + i
            rng = tse.qq(2020,1):tse.qq(2020,4);
            v = zeros(4, 2, 3);
            for i = 1:4, for j = 1:2, for k = 1:3
                v(i, j, k) = 100*k + 10*j + i;
            end, end, end
            x = tse.NDTSeries({rng, ["a" "b"], 3}, v);
        end
    end

    methods (Test)

        % ---------- construction ----------

        function construct_from_cell_spec(tc)
            x = TestNDTSeriesCore.sample();
            tc.verifyEqual(size(x), [4 2 3]);
            tc.verifyEqual(naxes(x), 3);
            tc.verifyEqual([x.axes.kind], ["range" "names" "plain"]);
            tc.verifyEqual(x.values(2, 1, 3), 312);
        end

        function construct_from_axis_array(tc)
            ax = [tse.Axis(["a" "b" "c"]), tse.Axis(tse.mm(2021,1), 2)];
            x = tse.NDTSeries(ax, reshape(1:6, 3, 2));
            tc.verifyEqual(size(x), [3 2]);
            tc.verifyEqual([x.axes.kind], ["names" "range"]);
        end

        function construct_nan_filled(tc)
            x = tse.NDTSeries({tse.qq(2020,1):tse.qq(2020,2), {'a','b','c'}});
            tc.verifyEqual(size(x), [2 3]);
            tc.verifyTrue(all(isnan(x.values(:))));
            tc.verifyClass(x.values, 'double');
        end

        function construct_scalar_fill(tc)
            x = tse.NDTSeries({tse.qq(2020,1):tse.qq(2020,2), 2, 2}, 7);
            tc.verifyEqual(x.values, 7 * ones(2, 2, 2));
        end

        function construct_from_function(tc)
            x = tse.NDTSeries({3, 2}, @(sz) reshape(1:prod(sz), sz));
            tc.verifyEqual(x.values, [1 4; 2 5; 3 6]);
        end

        function construct_typed(tc)
            x = tse.NDTSeries('int64', {tse.qq(2020,1):tse.qq(2020,3), ["a" "b"]}, 0);
            tc.verifyClass(x.values, 'int64');
            tc.verifyEqual(size(x), [3 2]);
            y = tse.NDTSeries('logical', {2, 2});
            tc.verifyClass(y.values, 'logical');
            tc.verifyFalse(any(y.values(:)));
            z = tse.NDTSeries('single', {2, 2}, [1 2; 3 4]);
            tc.verifyClass(z.values, 'single');
        end

        function construct_one_axis_from_range(tc)
            x = tse.NDTSeries(tse.qq(2020,1):tse.qq(2020,4), (1:4));
            tc.verifyEqual(size(x), [4 1]);
            tc.verifyEqual(x.values, (1:4)');
        end

        function construct_trailing_singleton(tc)
            % a 3x2 matrix is a valid value for axes of lengths 3, 2, 1
            x = tse.NDTSeries({3, 2, 1}, ones(3, 2));
            tc.verifyEqual(size(x), [3 2 1]);
            tc.verifyEqual(ndims(x), 3);
        end

        function construct_errors(tc)
            rng = tse.qq(2020,1):tse.qq(2020,4);
            tc.verifyError(@() tse.NDTSeries({rng, 2}, ones(3, 2)), 'tseries:noMatch');
            tc.verifyError(@() tse.NDTSeries({rng}, ones(4, 2)), 'tseries:noMatch');
            tc.verifyError(@() tse.NDTSeries({}, 1), 'tseries:noMatch');
            tc.verifyError(@() tse.NDTSeries('nosuchtype', {2}), 'tseries:noMatch');
            tc.verifyError(@() tse.NDTSeries({2}, {1, 2}), 'tseries:noMatch');
            tc.verifyError(@() tse.NDTSeries(42), 'tseries:noMatch');
        end

        function construct_empty(tc)
            x = tse.NDTSeries();
            tc.verifyTrue(isempty(x));
            tc.verifyEqual(naxes(x), 0);
        end

        % ---------- shape ----------

        function size_forms(tc)
            x = TestNDTSeriesCore.sample();
            tc.verifyEqual(size(x, 1), 4);
            tc.verifyEqual(size(x, 3), 3);
            tc.verifyEqual(size(x, 4), 1);
            tc.verifyEqual(size(x, [1 3]), [4 3]);
            [m, n] = size(x);
            tc.verifyEqual([m n], [4 6]);
            [a, b, c] = size(x);
            tc.verifyEqual([a b c], [4 2 3]);
            tc.verifyEqual(numel(x), 24);
            tc.verifyEqual(length(x), 4);
            tc.verifyEqual(ndims(x), 3);
            tc.verifyFalse(isempty(x));
        end

        function property_access_returns_one_value(tc)
            x = TestNDTSeriesCore.sample();
            ax = x.axes;
            tc.verifyEqual(numel(ax), 3);
            v = x.values;
            tc.verifyEqual(size(v), [4 2 3]);
        end

        % ---------- axes and dates ----------

        function dates_of_the_date_axis(tc)
            x = TestNDTSeriesCore.sample();
            rng = tse.qq(2020,1):tse.qq(2020,4);
            tc.verifyTrue(isequal(rangeof(x), rng));
            tc.verifyTrue(isequal(tse.rangeof(x), rng));
            tc.verifyTrue(eq(firstdate(x), tse.qq(2020,1)));
            tc.verifyTrue(eq(tse.firstdate(x), tse.qq(2020,1)));
            tc.verifyTrue(eq(lastdate(x), tse.qq(2020,4)));
            tc.verifyTrue(eq(tse.lastdate(x), tse.qq(2020,4)));
            tc.verifyClass(tse.frequencyof(x), 'tse.Quarterly');
            tc.verifyEqual(timedim(x), 1);
            tc.verifyTrue(isequal(tse.rangeof(x, 'drop', 1), tse.qq(2020,2):tse.qq(2020,4)));
        end

        function date_axis_in_any_position(tc)
            x = tse.NDTSeries({["a" "b"], tse.mm(2020,1):tse.mm(2020,3)}, ones(2, 3));
            tc.verifyEqual(timedim(x), 2);
            tc.verifyTrue(eq(lastdate(x), tse.mm(2020,3)));
            tc.verifyClass(tse.frequencyof(x), 'tse.Monthly');
        end

        function several_date_axes_need_dims(tc)
            % vintage x date
            x = tse.NDTSeries({tse.qq(2019,1):tse.qq(2019,2), tse.mm(2020,1):tse.mm(2020,6)});
            tc.verifyError(@() rangeof(x), 'tseries:noMatch');
            tc.verifyError(@() timedim(x), 'tseries:noMatch');
            tc.verifyTrue(eq(firstdate(x, 'dims', 2), tse.mm(2020,1)));
            tc.verifyTrue(eq(tse.lastdate(x, 'dims', 1), tse.qq(2019,2)));
            tc.verifyTrue(isequal(tse.rangeof(x, 'dims', 2, 'drop', -1), ...
                tse.mm(2020,1):tse.mm(2020,5)));
            tc.verifyClass(tse.frequencyof(x, 'dims', 1), 'tse.Quarterly');
            tc.verifyEqual(timedim(x, 'dims', 2), 2);
        end

        function dims_errors(tc)
            x = TestNDTSeriesCore.sample();
            tc.verifyError(@() rangeof(x, 'dims', 2), 'tseries:noMatch');   % names axis
            tc.verifyError(@() rangeof(x, 'dims', 4), 'tseries:noMatch');
            y = tse.NDTSeries({2, ["a" "b"]});
            tc.verifyError(@() rangeof(y), 'tseries:noMatch');              % no date axis
        end

        function names_and_haskey(tc)
            x = TestNDTSeriesCore.sample();
            tc.verifyEqual(names(x), ["a" "b"]);
            tc.verifyEqual(names(x, 2), ["a" "b"]);
            tc.verifyError(@() names(x, 1), 'tseries:noMatch');
            tc.verifyTrue(haskey(x, 'a'));
            tc.verifyTrue(haskey(x, "b"));
            tc.verifyFalse(haskey(x, 'c'));
            y = tse.NDTSeries({["a" "b"], ["c" "d" "e"]});
            tc.verifyError(@() names(y), 'tseries:noMatch');
            tc.verifyTrue(haskey(y, 'e'));
        end

        function data_access(tc)
            x = TestNDTSeriesCore.sample();
            tc.verifyEqual(rawdata(x), x.values);
            tc.verifyEqual(double(x), x.values);
            tc.verifyTrue(isnumeric(x));
            tc.verifyFalse(islogical(x));
            tc.verifyTrue(isequal(copy(x), x));
        end

        % ---------- reshaping ----------

        function permute_axes(tc)
            x = TestNDTSeriesCore.sample();
            y = permute(x, [3 1 2]);
            tc.verifyEqual(size(y), [3 4 2]);
            tc.verifyEqual([y.axes.kind], ["plain" "range" "names"]);
            tc.verifyEqual(y.values(3, 2, 1), x.values(2, 1, 3));
            tc.verifyTrue(isequal(permute(y, [2 3 1]), x));
            tc.verifyError(@() permute(x, [1 2]), 'tseries:noMatch');
        end

        function squeeze_axes(tc)
            x = tse.NDTSeries({tse.qq(2020,1):tse.qq(2020,3), 1, ["a" "b"]}, ones(3, 1, 2));
            y = squeeze(x);
            tc.verifyEqual(size(y), [3 2]);
            tc.verifyEqual([y.axes.kind], ["range" "names"]);
            z = squeeze(tse.NDTSeries({1, 1}, 5));
            tc.verifyEqual(naxes(z), 1);
            tc.verifyEqual(z.values, 5);
        end

        % ---------- conversion ----------

        function from_and_to_tseries(tc)
            t = tse.TSeries(tse.qq(2020,1), (1:5)');
            x = tse.NDTSeries(t);
            tc.verifyEqual(size(x), [5 1]);
            tc.verifyEqual(x.axes(1).kind, "range");
            back = toseries(x);
            tc.verifyClass(back, 'tse.TSeries');
            tc.verifyTrue(isequal(back, t));
        end

        function from_and_to_mvtseries(tc)
            m = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,3), {'a','b'}, [1 4; 2 5; 3 6]);
            x = tse.NDTSeries(m);
            tc.verifyEqual(size(x), [3 2]);
            tc.verifyEqual(names(x), ["a" "b"]);
            back = toseries(x);
            tc.verifyClass(back, 'tse.MVTSeries');
            tc.verifyTrue(isequal(back, m));
            % names-by-dates also converts
            back2 = toseries(permute(x, [2 1]));
            tc.verifyTrue(isequal(back2, m));
        end

        function toseries_errors(tc)
            x = TestNDTSeriesCore.sample();
            tc.verifyError(@() toseries(x), 'tseries:noMatch');
            tc.verifyError(@() toseries(tse.NDTSeries({3, 2})), 'tseries:noMatch');
        end

        function from_and_to_daec_array(tc)
            x = TestNDTSeriesCore.sample();
            a = tse.daec.Array(x);
            tc.verifyClass(a, 'tse.daec.Array');
            tc.verifyTrue(isequal(a.axes, x.axes));
            tc.verifyEqual(a.values, x.values);
            tc.verifyTrue(isequal(tse.NDTSeries(a), x));
            % a one-axis Array stores a column
            a1 = tse.daec.Array(tse.Axis(["x" "y" "z"]), [1 2 3]);
            y = tse.NDTSeries(a1);
            tc.verifyEqual(size(y), [3 1]);
        end

        function daec_axis_alias(tc)
            ax = tse.daec.Axis(["a" "b"]);
            tc.verifyClass(ax, 'tse.Axis');
            tc.verifyTrue(isequal(ax, tse.Axis(["a" "b"])));
            r = tse.daec.Axis(tse.qq(2020,1), 4);
            tc.verifyEqual(r.kind, "range");
            tc.verifyEqual(r.length, 4);
        end

        % ---------- comparison ----------

        function equality(tc)
            x = TestNDTSeriesCore.sample();
            y = x;
            tc.verifyTrue(isequal(x, y));
            z = tse.NDTSeries({tse.qq(2020,1):tse.qq(2020,4), ["a" "c"], 3}, x.values);
            tc.verifyFalse(isequal(x, z));
            w = tse.NDTSeries({tse.qq(2020,2):tse.qq(2020,5), ["a" "b"], 3}, x.values);
            tc.verifyFalse(isequal(x, w));
            n1 = tse.NDTSeries({2}, [1 NaN]);
            tc.verifyFalse(isequal(n1, n1));
            tc.verifyTrue(isequaln(n1, n1));
            tc.verifyFalse(isequal(x, x.values));
        end

        function compare_tolerance(tc)
            x = TestNDTSeriesCore.sample();
            v = x.values + 1e-12;
            y = tse.NDTSeries(x.axes, v);
            tc.verifyTrue(tse.compare(x, y));
            tc.verifyTrue(compare(x, y));
            tc.verifyFalse(tse.compare(x, y, 'atol', 0, 'rtol', 0));
            n1 = tse.NDTSeries({2}, [1 NaN]);
            tc.verifyFalse(tse.compare(n1, n1));
            tc.verifyTrue(tse.compare(n1, n1, 'nans', true));
            tc.verifyFalse(tse.compare(x, permute(x, [1 3 2])));
            s1 = struct('x', x);
            s2 = struct('x', y);
            tc.verifyTrue(tse.compare(s1, s2));
        end

        % ---------- display ----------

        function display_3d(tc)
            x = TestNDTSeriesCore.sample();
            out = evalc('disp(x)');
            tc.verifySubstring(out, '4×2×3 NDTSeries of double');
            tc.verifySubstring(out, '2020Q1:2020Q4');
            tc.verifySubstring(out, '(:, :, 3)');
            tc.verifySubstring(out, '2020Q2');
            tc.verifySubstring(out, '312');
        end

        function display_slices_capped(tc)
            x = tse.NDTSeries({2, 2, 7}, 0);
            out = evalc('disp(x)');
            tc.verifySubstring(out, '2 more slices');
            full = evalc('showall(x)');
            tc.verifySubstring(full, '(:, :, 7)');
        end

        function display_1d_2d_and_empty(tc)
            t = tse.NDTSeries({["x" "y"]}, [1.5 true]);
            out = evalc('disp(t)');
            tc.verifySubstring(out, 'x');
            tc.verifySubstring(out, '1.5');
            m = tse.NDTSeries({tse.mm(2020,1):tse.mm(2020,2), ["a" "b"]}, [1 2; 3 4]);
            out = evalc('disp(m)');
            tc.verifySubstring(out, '2020M2');
            tc.verifySubstring(out, 'b');
            e = tse.NDTSeries({0, ["a" "b"]});
            evalc('disp(e)');
            evalc('disp(tse.NDTSeries())');
            s = evalc('summary(m)');
            tc.verifySubstring(s, 'axis 2: names');
        end

        function display_long_series_truncates(tc)
            x = tse.NDTSeries({tse.mm(2000,1):tse.mm(2009,12), ["a" "b"]}, 1);
            out = evalc('disp(x)');
            tc.verifySubstring(out, '⋮');
            tc.verifyFalse(contains(out, '2005M6'));
            tc.verifySubstring(evalc('showall(x)'), '2005M6');
        end

        % ---------- package fix found along the way ----------

        function lastdate_of_wide_mvtseries(tc)
            % tse.lastdate used length(values), which counts columns when an
            % MVTSeries has more columns than rows.
            m = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,2), {'a','b','c'}, 0);
            tc.verifyTrue(eq(tse.lastdate(m), tse.qq(2020,2)));
            tc.verifyTrue(isequal(tse.rangeof(m), tse.qq(2020,1):tse.qq(2020,2)));
            tc.verifyTrue(eq(tse.firstdate(m), tse.qq(2020,1)));
        end
    end
end

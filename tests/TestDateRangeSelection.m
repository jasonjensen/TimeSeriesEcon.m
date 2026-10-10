classdef TestDateRangeSelection < matlab.unittest.TestCase
    %TESTDATERANGESELECTION  Reading and assigning through strided, reversed
    %   and empty MITRanges agrees with enumerating the individual dates.
    %
    %   Mirrors tests/test_date_range_selection.py and
    %   tests/test_empty_range_equality.py in TimeSeriesEconPy (commits
    %   efaf64f and 69126db), which match TimeSeriesEcon.jl.

    properties (TestParameter)
        % [lo, hi, step] offsets from the first stored date (6 rows stored).
        bounds = {[0 5 1], [0 5 2], [5 0 -1], [4 0 -2], [5 0 -2], ...
                  [3 3 -1], [0 0 -3], [4 2 1], [2 4 -1], [9 8 1]};
        mode = {'series', 'table', 'column', 'columns'};
        badBounds = {[6 0 -1], [4 -1 -1], [-1 -2 -1], [7 8 1]};
        table = {false, true};
        step = {1, 2, -1, -2};
        landingStep = {2, -2};
    end

    methods (Test)
        function enumerated_read_and_write(tc, bounds, mode)
            obj = makeSeries(~strcmp(mode, 'series'));
            s = obj.firstdate;
            d = tse.MITRange(s + bounds(1), bounds(3), s + bounds(2));
            pos = (bounds(1):bounds(3):bounds(2)) + 1;
            V = rawdata(obj);
            switch mode
                case 'series',  expected = V(pos);         res = obj(d);
                case 'table',   expected = V(pos, :);      res = obj(d);
                case 'column',  expected = V(pos, 1);      res = obj(d, 'a');
                case 'columns', expected = V(pos, [2 1]);  res = obj(d, {'b', 'a'});
            end
            if bounds(3) == 1
                tc.verifyTrue(isa(res, 'tse.TSeries') || isa(res, 'tse.MVTSeries'));
                tc.verifyTrue(res.firstdate == d.startMIT);
                got = rawdata(res);
            else
                tc.verifyTrue(isnumeric(res));
                got = res;
            end
            tc.verifyEqual(reshape(got, size(expected)), expected);

            replacement = reshape((0:numel(expected) - 1) + 100, size(expected));
            baseline = V;
            switch mode
                case 'series',  obj(d) = replacement;              baseline(pos) = replacement;
                case 'table',   obj(d) = replacement;              baseline(pos, :) = replacement;
                case 'column',  obj(d, 'a') = replacement;         baseline(pos, 1) = replacement;
                case 'columns', obj(d, {'b', 'a'}) = replacement;  baseline(pos, [2 1]) = replacement;
            end
            tc.verifyEqual(rawdata(obj), baseline);
            tc.verifyTrue(obj.firstdate == s);
        end

        function invalid_read_bounds(tc, badBounds, table)
            obj = makeSeries(table);
            s = obj.firstdate;
            d = tse.MITRange(s + badBounds(1), badBounds(3), s + badBounds(2));
            tc.verifyError(@() obj(d), 'tseries:bounds');
        end

        function stride_stop_outside_storage_selected_dates_inside(tc, table)
            obj = makeSeries(table);
            s = obj.firstdate;
            V = rawdata(obj);
            got = obj(tse.MITRange(s + 4, -2, s - 1));
            tc.verifyEqual(got, V([5 3 1], :));
        end

        function empty_wrong_frequency_still_rejected(tc, table)
            obj = makeSeries(table);
            d = tse.MITRange(tse.mm(2020, 2), tse.mm(2020, 1));
            tc.verifyError(@() obj(d), 'tseries:mixedFreq');
            tc.verifyError(@() assignRange(obj, d, 0), 'tseries:mixedFreq');
        end

        function empty_storage_selection_and_scalar_assignment(tc)
            t = tse.TSeries(tse.qq(2020, 1), zeros(0, 1));
            d = tse.MITRange(t.firstdate + 3, t.firstdate + 2);
            tc.verifyEqual(length(t(d)), 0);
            t(d) = 7;
            tc.verifyEqual(length(t), 0);
            tc.verifyTrue(t.firstdate == tse.qq(2020, 1));
        end

        function table_aligned_rhs_single_column(tc)
            obj = makeSeries(true);
            rhs = makeSeries(true) + 20;
            d = tse.MITRange(obj.firstdate + 5, -1, obj.firstdate);
            obj(d, 'a') = rhs('a');
            V = rawdata(obj);
            R = rawdata(rhs);
            tc.verifyEqual(V(:, 1), R(:, 1));
            tc.verifyEqual(V(:, 2), (10:15)');
        end

        function table_aligned_rhs_columns(tc)
            obj = makeSeries(true);
            rhs = makeSeries(true) + 20;
            d = tse.MITRange(obj.firstdate + 5, -1, obj.firstdate);
            obj(d, {'b', 'a'}) = rhs;
            tc.verifyEqual(rawdata(obj), rawdata(rhs));
        end

        function series_aligned_rhs_with_stride(tc)
            obj = makeSeries(false);
            rhs = makeSeries(false) + 20;
            s = obj.firstdate;
            obj(tse.MITRange(s + 5, -2, s)) = rhs;
            tc.verifyEqual(rawdata(obj), [0; 21; 2; 23; 4; 25]);
        end

        function aligned_rhs_must_cover_the_dates(tc)
            obj = makeSeries(false);
            s = obj.firstdate;
            short = tse.TSeries(s, [1; 2]);
            tc.verifyError(@() assignRange(obj, tse.MITRange(s + 4, -2, s), short), ...
                'tseries:bounds');
        end

        function reverse_assignment_grows_and_preserves_gaps(tc)
            t = tse.TSeries(tse.qq(2020, 1), [1; 2]);
            s = t.firstdate;
            t(tse.MITRange(s + 4, -2, s - 2)) = [40 20 0 -20];
            tc.verifyTrue(t.firstdate == s - 2);
            tc.verifyEqual(rawdata(t), [-20; NaN; 0; 2; 20; NaN; 40]);
        end

        function invalid_assignment_is_rejected(tc)
            t = tse.TSeries(tse.qq(2020, 1), [1; 2]);
            s = t.firstdate;
            d = tse.MITRange(s + 4, -2, s);
            tc.verifyError(@() assignRange(t, d, [1 2]), 'tseries:dimMismatch');
            tc.verifyError(@() assignRange(t, d, 'bad'), 'tseries:invalidArith');
            tc.verifyError(@() assignRange(t, d, tse.TSeries(tse.mm(2020, 1), [1; 2; 3])), ...
                'tseries:mixedFreq');
        end

        function empty_owner_grows_at_its_anchor(tc)
            s = tse.qq(2020, 1);
            t = tse.TSeries(s, zeros(0, 1, 'int32'));
            t(s) = 7;
            tc.verifyEqual(rawdata(t), int32(7));

            t = tse.TSeries(s, zeros(0, 1, 'int32'));
            t(tse.MITRange(s, s + 2)) = [7 8 9];
            tc.verifyTrue(t.firstdate == s);
            tc.verifyEqual(rawdata(t), int32([7; 8; 9]));

            t = tse.TSeries(s, zeros(0, 1, 'int32'));
            t(tse.MITRange(s + 2, -1, s)) = [9 8 7];
            tc.verifyTrue(t.firstdate == s);
            tc.verifyEqual(rawdata(t), int32([7; 8; 9]));
        end

        function lookup_follows_the_selected_dates(tc)
            t = makeSeries(false);
            s = t.firstdate;
            tc.verifyEqual(tse.lookup(t, tse.MITRange(s + 4, -2, s - 1)), [4; 2; 0]);
            tc.verifyError(@() tse.lookup(t, tse.MITRange(s + 6, -1, s)), 'tseries:bounds');
        end

        % ---- MITRange equality (test_empty_range_equality.py) ----

        function empty_vs_nonempty_both_orders(tc, step)
            s = tse.qq(2020, 1);
            emptyRng = tse.MITRange(s, step, s - step);
            populated = tse.MITRange(s, step, s + 2 * step);
            tc.verifyFalse(emptyRng == populated);
            tc.verifyFalse(populated == emptyRng);
            tc.verifyTrue(emptyRng ~= populated);
            tc.verifyTrue(populated ~= emptyRng);
        end

        function empty_equality_ignores_anchor_and_step(tc)
            s = tse.qq(2020, 1);
            a = tse.MITRange(s, s - 1);
            b = tse.MITRange(s + 5, -2, s + 6);
            other = tse.MITRange(tse.mm(2020, 1), tse.mm(2019, 12));
            tc.verifyTrue(a == b);
            tc.verifyTrue(isequal(a, b));
            tc.verifyTrue(a ~= other);
            tc.verifyTrue(other ~= a);
        end

        function nonlanding_stop_keeps_equality(tc, landingStep)
            s = tse.qq(2020, 1);
            a = tse.MITRange(s, landingStep, s + 2 * landingStep);
            b = tse.MITRange(s, landingStep, s + 2 * landingStep + sign(landingStep));
            tc.verifyTrue(a == b);
            tc.verifyTrue(a ~= tse.MITRange(s, sign(landingStep), s + 2 * landingStep));
        end

        function range_minus_shifts_both_ends(tc)
            s = tse.qq(2020, 1);
            r = tse.MITRange(s, 2, s + 4) - 1;
            tc.verifyTrue(r == tse.MITRange(s - 1, 2, s + 3));
        end
    end
end

function obj = makeSeries(table)
    if table
        obj = tse.MVTSeries(tse.qq(2020, 1), {'a', 'b'}, [(0:5)', (10:15)']);
    else
        obj = tse.TSeries(tse.qq(2020, 1), (0:5)');
    end
end

function obj = assignRange(obj, d, val)
    obj(d) = val;
end

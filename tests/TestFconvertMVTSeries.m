classdef TestFconvertMVTSeries < FconvertTestUtils
    %TESTFCONVERTMVTSERIES  fconvert on an MVTSeries.
    %
    %   Neither TimeSeriesEcon.jl nor TimeSeriesEconPy converts an MVTSeries
    %   directly, so there is no upstream test to mirror.  Each case checks
    %   that converting an MVTSeries gives the same result as converting
    %   each of its columns as a TSeries with the same options.

    methods
        function checkColumnwise(tc, F_to, x, varargin)
            out = tse.fconvert(F_to, x, varargin{:});
            tc.verifyClass(out, 'tse.MVTSeries');
            tc.verifyEqual(out.colnames, x.colnames);
            for k = 1:numel(x.colnames)
                ts = tse.fconvert(F_to, tse.TSeries(x.firstdate, x.values(:, k)), varargin{:});
                tc.verifyTrue(eq(out.firstdate, ts.firstdate), ...
                    sprintf('first date, column %d', k));
                tc.verifyEqual(size(out.values, 1), numel(ts.values), ...
                    sprintf('length, column %d', k));
                tc.vApprox(out.values(:, k), ts.values, 1e-12);
            end
        end
    end

    methods (Test)

        function quarterly_to_monthly(tc)
            x = tse.MVTSeries(tc.Q(2020,1):tc.Q(2021,4), {'a','b'}, [(1:8)', (11:18)']);
            tc.checkColumnwise(tse.Monthly(), x);
            tc.checkColumnwise(tse.Monthly(), x, 'method', 'even');
            tc.checkColumnwise(tse.Monthly(), x, 'method', 'linear');
            tc.checkColumnwise(tse.Monthly(), x, 'method', 'linear', 'ref', 'begin');

            out = tse.fconvert(tse.Monthly(), x);
            tc.verifyTrue(eq(out.firstdate, tc.M(2020,1)));
            tc.verifyEqual(out.values(1:6, :), [1 11; 1 11; 1 11; 2 12; 2 12; 2 12]);
        end

        function monthly_to_quarterly(tc)
            x = tse.MVTSeries(tc.M(2020,1):tc.M(2021,12), {'a','b','c'}, ...
                [(1:24)', (24:-1:1)', mod((1:24)', 5)]);
            for m = {'mean', 'sum', 'min', 'max', 'point', 'begin', 'end'}
                tc.checkColumnwise(tse.Quarterly(), x, 'method', m{1});
            end
            out = tse.fconvert(tse.Quarterly(), x, 'method', 'sum');
            tc.verifyEqual(out.values(1, :), [6, 69, 6]);
        end

        function partial_periods_are_trimmed(tc)
            % starts mid-quarter: the first and last quarters are incomplete
            x = tse.MVTSeries(tc.M(2020,2):tc.M(2021,11), {'a','b'}, [(1:22)', (101:122)']);
            tc.checkColumnwise(tse.Quarterly(), x);
            tc.checkColumnwise(tse.Yearly(), x, 'method', 'end');
        end

        function custom_function(tc)
            x = tse.MVTSeries(tc.M(2022,1):tc.M(2022,12), {'a','b'}, [(1:12)', (12:-1:1)']);
            out = tse.fconvert(@(v) max(v) - min(v), tse.Quarterly(), x);
            tc.verifyEqual(out.values, 2 * ones(4, 2));
            tc.verifyEqual(out.colnames, x.colnames);
        end

        function daily_to_monthly(tc)
            rng = tse.day('2022-01-01'):tse.day('2022-03-31');
            n = double(length(rng));
            x = tse.MVTSeries(rng, {'a','b'}, [(1:n)', 2 * (1:n)']);
            tc.checkColumnwise(tse.Monthly(), x);
            tc.checkColumnwise(tse.Monthly(), x, 'method', 'sum');
        end

        function bdaily_to_daily(tc)
            rng = tse.bday('2022-01-03'):tse.bday('2022-01-28');
            n = double(length(rng));
            x = tse.MVTSeries(rng, {'a','b'}, [(1:n)', -(1:n)']);
            tc.checkColumnwise(tse.Daily(), x);
        end

        function same_frequency_is_unchanged(tc)
            x = tse.MVTSeries(tc.Q(2020,1):tc.Q(2020,4), {'a','b'}, [(1:4)', (5:8)']);
            tc.verifyTrue(isequal(tse.fconvert(tse.Quarterly(), x), x));
        end

        function frequency_by_name(tc)
            x = tse.MVTSeries(tc.Q(2020,1):tc.Q(2021,4), {'a','b'}, [(1:8)', (11:18)']);
            tc.verifyTrue(isequal(tse.fconvert('Yearly', x), tse.fconvert(tse.Yearly(), x)));
        end

        function no_columns(tc)
            x = tse.MVTSeries(tc.Q(2020,1):tc.Q(2021,4), strings(1, 0));
            out = tse.fconvert(tse.Monthly(), x);
            tc.verifyClass(out, 'tse.MVTSeries');
            tc.verifyEqual(size(out), [24 0]);
            tc.verifyTrue(eq(out.firstdate, tc.M(2020,1)));
        end
    end
end

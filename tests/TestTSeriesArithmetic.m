classdef TestTSeriesArithmetic < matlab.unittest.TestCase
    %TESTTSERIESARITHMETIC  Arithmetic and broadcasting tests from
    %    test_tseries.jl "Bcast", "math", "Addition", "Iris".

    methods (Test)

        function plus_with_scalar(tc)
            t = tse.TSeries(tse.MIT(tse.Unit(),5), (1:6)');
            r = t + 5;
            tc.verifyClass(r, 'tse.TSeries');
            tc.verifyEqual(r.values, (6:11)');
            tc.verifyTrue(r.firstdate == t.firstdate);
        end

        function scalar_plus(tc)
            t = tse.TSeries(tse.MIT(tse.Unit(),5), (1:6)');
            r = 5 + t;
            tc.verifyEqual(r.values, (6:11)');
        end

        function plus_with_vector(tc)
            t = tse.TSeries(tse.MIT(tse.Unit(),5), (1:6)');
            r = t + (1:6)';
            tc.verifyEqual(r.values, (2:2:12)');
        end

        function plus_wrong_length_throws(tc)
            t = tse.TSeries(tse.MIT(tse.Unit(),5), (1:6)');
            tc.verifyError(@() t + (1:4)', 'tseries:dimMismatch');
        end

        function plus_two_tseries_intersection(tc)
            x = tse.TSeries(tse.MIT(tse.Unit(),1), [7;7;7]);
            y = tse.TSeries(tse.MIT(tse.Unit(),3), [2;4;5]);
            r = x + y;
            tc.verifyTrue(r.firstdate == tse.MIT(tse.Unit(),3));
            tc.verifyEqual(r.values, 9);
        end

        function plus_partial_overlap(tc)
            x = tse.TSeries(tse.MIT(tse.Unit(),1), [7;7;7]);
            y = tse.TSeries(tse.MIT(tse.Unit(),2), [2;4;5]);
            r = x + y;
            tc.verifyTrue(r.firstdate == tse.MIT(tse.Unit(),2));
            tc.verifyEqual(r.values, [9;11]);
        end

        function mixed_freq_throws(tc)
            tq = tse.TSeries(tse.qq(2020,1), rand(12,1));
            tm = tse.TSeries(tse.mm(2020,1), rand(12,1));
            tc.verifyError(@() tq + tm, 'tseries:mixedFreq');
        end

        function scalar_times_tseries(tc)
            tq = tse.TSeries(tse.qq(2020,1), rand(12,1));
            r = 5 * tq;
            tc.verifyClass(r, 'tse.TSeries');
            tc.verifyEqual(r.values, 5 * tq.values);
        end

        function tseries_times_scalar(tc)
            tq = tse.TSeries(tse.qq(2020,1), rand(12,1));
            r = tq * 5;
            tc.verifyClass(r, 'tse.TSeries');
            tc.verifyEqual(r.values, tq.values * 5);
        end

        function uminus(tc)
            t = tse.TSeries(tse.MIT(tse.Unit(),1), (1:3)');
            r = -t;
            tc.verifyEqual(r.values, -(1:3)');
        end

        function rdivide_scalar(tc)
            t = tse.TSeries(tse.MIT(tse.Unit(),1), (2:2:6)');
            r = t / 2;
            tc.verifyEqual(r.values, (1:3)');
        end

        function power_element_wise(tc)
            s = tse.TSeries(tse.MIT(tse.Unit(),1), (1:5)');
            r = s .^ 2;
            tc.verifyClass(r, 'tse.TSeries');
            tc.verifyEqual(r.values, (1:5)' .^ 2);
        end

        function lt_returns_logical_tseries(tc)
            t = tse.TSeries(tse.MIT(tse.Unit(),1), (1:5)');
            mask = t < 3;
            tc.verifyClass(mask, 'tse.TSeries');
            tc.verifyTrue(islogical(mask.values));
            tc.verifyEqual(mask.values, [true; true; false; false; false]);
        end

        function reductions_match_underlying(tc)
            t = tse.TSeries(tse.qq(2020,1), (1:12)');
            tc.verifyEqual(sum(t), 78);
            tc.verifyEqual(min(t), 1);
            tc.verifyEqual(max(t), 12);
            tc.verifyEqual(mean(t), 6.5);
            tc.verifyEqual(prod(t), prod(1:12));
        end

        function cumsum_keeps_range(tc)
            x = tse.TSeries(tse.MIT(tse.Unit(),2000):tse.MIT(tse.Unit(),2010), 1);
            y = cumsum(x);
            tc.verifyClass(y, 'tse.TSeries');
            tc.verifyEqual(tse.rangeof(y), tse.rangeof(x));
            tc.verifyEqual(y.values, (1:11)');
        end

        function isequal_value_vs_handle(tc)
            t1 = tse.TSeries(tse.qq(2020,1), [1;2;3]);
            t2 = tse.TSeries(tse.qq(2020,1), [1;2;3]);
            tc.verifyTrue(isequal(t1, t2));
            t2.values(1) = 7;
            tc.verifyFalse(isequal(t1, t2));   % value-class: independent
        end
    end
end

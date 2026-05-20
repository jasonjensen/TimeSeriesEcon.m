classdef TestTSeriesIndex < matlab.unittest.TestCase
    %TESTTSERIESINDEX  Mirrors integer/MIT/range indexing tests from
    %    test_tseries.jl "Int indexing", "Bool indexing", "Setting".

    methods (Test)
        function int_indexing_scalar(tc)
            t = tseries.TSeries(tseries.MIT(tseries.Unit(),4):tseries.MIT(tseries.Unit(),8), rand(5,1));
            tc.verifyClass(t(1), 'double');
            tc.verifyEqual(t(1), t.values(1));
        end

        function int_range_returns_numeric_vec(tc)
            t = tseries.TSeries(tseries.MIT(tseries.Unit(),4):tseries.MIT(tseries.Unit(),8), rand(5,1));
            v = t(2:4);
            tc.verifyClass(v, 'double');
            tc.verifyEqual(v, t.values(2:4));
        end

        function int_vec_indexing(tc)
            t = tseries.TSeries(tseries.MIT(tseries.Unit(),4):tseries.MIT(tseries.Unit(),8), rand(5,1));
            v = t([1 3 4]);
            tc.verifyEqual(v, t.values([1 3 4]));
        end

        function int_assignment(tc)
            t = tseries.TSeries(tseries.MIT(tseries.Unit(),4):tseries.MIT(tseries.Unit(),8), rand(5,1));
            t(3) = 5;
            tc.verifyEqual(t.values(3), 5);
        end

        function colon_returns_self(tc)
            t = tseries.TSeries(tseries.MIT(tseries.Unit(),4):tseries.MIT(tseries.Unit(),8), rand(5,1));
            tc.verifyTrue(isequal(t(:), t));
        end

        function mit_indexing(tc)
            s = tseries.TSeries(tseries.qq(2020,1), (11:22)');
            tc.verifyEqual(s(tseries.qq(2020,1)), 11);
            tc.verifyEqual(s(tseries.qq(2022,4)), 22);
        end

        function mit_range_indexing_returns_tseries(tc)
            s = tseries.TSeries(tseries.qq(2020,1), (11:22)');
            sub = s(tseries.qq(2020,1):tseries.qq(2020,4));
            tc.verifyClass(sub, 'tseries.TSeries');
            tc.verifyEqual(sub.values, (11:14)');
            tc.verifyTrue(sub.firstdate == tseries.qq(2020,1));
        end

        function bounds_check_mit(tc)
            s = tseries.TSeries(tseries.qq(2020,1), (11:22)');
            tc.verifyError(@() s(tseries.qq(2019,1)), 'tseries:bounds');
            tc.verifyError(@() s(tseries.qq(2017,1):tseries.qq(2019,12)), 'tseries:bounds');
        end

        function bounds_check_int(tc)
            s = tseries.TSeries(tseries.qq(2020,1), (11:22)');
            tc.verifyError(@() s(0), 'tseries:bounds');
            tc.verifyError(@() s(13), 'tseries:bounds');
        end

        function wrong_freq_index_throws(tc)
            s = tseries.TSeries(tseries.qq(2020,1), (11:22)');
            tc.verifyError(@() s(tseries.MIT(tseries.Unit(),1)), 'tseries:mixedFreq');
            tc.verifyError(@() s(tseries.yy(2020):tseries.yy(2021)), 'tseries:mixedFreq');
        end

        function assign_grows_at_left(tc)
            t = tseries.TSeries(tseries.mm(2018,1):tseries.mm(2018,12), (1:12)');
            t(tseries.mm(2017,10)) = -1;
            tc.verifyTrue(t.firstdate == tseries.mm(2017,10));
            % padded with NaN between 2017M10 and 2018M1
            tc.verifyEqual(t.values(1), -1);
            tc.verifyTrue(isnan(t.values(2)) && isnan(t.values(3)));
            tc.verifyEqual(t.values(4:end), (1:12)');
        end

        function assign_grows_at_right(tc)
            t = tseries.TSeries(tseries.mm(2018,1):tseries.mm(2018,12), (1:12)');
            t(tseries.mm(2019,2)) = -1;
            tc.verifyTrue(tseries.lastdate(t) == tseries.mm(2019,2));
            tc.verifyEqual(t.values(1:12), (1:12)');
            tc.verifyTrue(isnan(t.values(13)));      % 2019M1 padding
            tc.verifyEqual(t.values(14), -1);        % 2019M2
        end

        function assign_range_to_vector(tc)
            t = tseries.TSeries(tseries.mm(2018,1):tseries.mm(2018,12), (1:12)');
            t(tseries.mm(2019,2) : tseries.mm(2019,4)) = [9 10 11];
            tc.verifyEqual(t.values(14:16), [9 10 11]');
        end

        function assign_range_to_scalar(tc)
            t = tseries.TSeries(tseries.qq(2020,1):tseries.qq(2020,4), (1:4)');
            t(tseries.qq(2020,2):tseries.qq(2020,3)) = 7;
            tc.verifyEqual(t.values, [1 7 7 4]');
        end

        function logical_indexing(tc)
            t = tseries.TSeries(tseries.qq(2020,1), (1:5)');
            v = t(t.values > 2);
            tc.verifyEqual(v, [3 4 5]');
        end

        function logical_assign(tc)
            t = tseries.TSeries(tseries.qq(2020,1), (1:5)');
            t(t.values > 3) = 0;
            tc.verifyEqual(t.values, [1 2 3 0 0]');
        end

        function lastdate_for_empty(tc)
            t = tseries.TSeries(tseries.qq(2020,1));
            tc.verifyEqual(length(t), 0);
            % lastdate < firstdate when empty
            tc.verifyTrue(tseries.lastdate(t) < t.firstdate);
        end

        function resize_keeps_old_data(tc)
            t = tseries.TSeries(tseries.qq(2020,1):tseries.qq(2020,4), (1:4)');
            t2 = resize(t, tseries.qq(2020,2):tseries.qq(2021,1));
            tc.verifyTrue(t2.firstdate == tseries.qq(2020,2));
            tc.verifyEqual(length(t2), 4);
            tc.verifyEqual(t2.values(1:3), (2:4)');
            tc.verifyTrue(isnan(t2.values(4)));
        end
    end
end

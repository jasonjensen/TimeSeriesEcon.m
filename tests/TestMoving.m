classdef TestMoving < matlab.unittest.TestCase
    %TESTMOVING  Moving-window operations.

    methods (Test)

        function moving_backward(tc)
            x = tseries.TSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),10), (1:10)');
            r = moving(x, 4);
            tc.verifyTrue(r.firstdate == tseries.MIT(tseries.Unit(),4));
            tc.verifyEqual(r.values, (4:10)' - 1.5);
        end

        function moving_forward(tc)
            x = tseries.TSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),10), (1:10)');
            r = moving(x, -4);
            tc.verifyTrue(r.firstdate == tseries.MIT(tseries.Unit(),1));
            tc.verifyEqual(r.values, (1:7)' + 1.5);
        end

        function moving_sum_vs_average(tc)
            x = tseries.TSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),10), (1:10)');
            ma = moving_average(x, 2);
            ms = moving_sum(x, 2);
            tc.verifyEqual(ms.values, 2 * ma.values);
        end

        function moving_window_one_is_identity(tc)
            x = tseries.TSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),5), (10:14)');
            r = moving(x, 1);
            tc.verifyEqual(r.values, x.values);
        end
    end
end

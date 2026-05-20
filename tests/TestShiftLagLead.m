classdef TestShiftLagLead < matlab.unittest.TestCase
    %TESTSHIFTLAGLEAD  Mirrors the shift/lag/lead/diff_ts tests from
    %    test_tseries.jl "Iris" and "TS.math" testsets.

    methods (Test)

        function shift_left(tc)
            x = tseries.TSeries(tseries.qq(2020,1), zeros(3,1));
            y = shift(x, 1);
            tc.verifyTrue(y.firstdate == tseries.qq(2019,4));
            tc.verifyEqual(y.values, zeros(3,1));
            % Original unchanged (value-class)
            tc.verifyTrue(x.firstdate == tseries.qq(2020,1));
        end

        function shift_right(tc)
            x = tseries.TSeries(tseries.qq(2020,1), (1:4)');
            y = shift(x, -2);
            tc.verifyTrue(y.firstdate == tseries.qq(2020,3));
        end

        function lag_default(tc)
            y = tseries.TSeries(tseries.MIT(tseries.Unit(),2000):tseries.MIT(tseries.Unit(),2010), 1);
            y = cumsum(y);
            y1 = lag(y);
            tc.verifyEqual(double(y1.firstdate.value - y.firstdate.value), 1);
            tc.verifyEqual(y1.values, y.values);
        end

        function lead_two(tc)
            y = tseries.TSeries(tseries.MIT(tseries.Unit(),2000):tseries.MIT(tseries.Unit(),2010), 1);
            y2 = lead(y, 2);
            tc.verifyEqual(double(y2.firstdate.value - y.firstdate.value), -2);
        end

        function diff_default(tc)
            t1 = tseries.TSeries(tseries.yy(2000), [1;2;4;8]);
            d = diff_ts(t1);
            tc.verifyEqual(d.values, [1;2;4]);
            tc.verifyTrue(d.firstdate == tseries.yy(2001));
        end

        function diff_lead(tc)
            % diff_ts(x, k) = x - lag(x, -k); for k=-1 (default) -> x - x[t-1]
            % for k=1 -> x - x[t+1]
            x = tseries.TSeries(tseries.qq(2020,1), (1:5)');
            d = diff_ts(x, 1);
            tc.verifyEqual(d.values, -ones(4,1));
        end
    end
end

classdef TestDuration < matlab.unittest.TestCase
    %TESTDURATION  Mirrors the custom-frequency div/rem block of test_mit.jl.

    methods (Test)
        function div_rem_basic(tc)
            % Using Quarterly for the divisor/dividend (parallels Julia's custom YPFrequency{5})
            d1 = tseries.Duration(tseries.Quarterly(), 10);
            d2 = tseries.Duration(tseries.Quarterly(), 4);
            tc.verifyTrue(d1 - d2 == 6);
            q = div(d1, d2);
            tc.verifyTrue(q == 2);
            r = rem(d1, d2);
            tc.verifyTrue(r == 2);
            % d2 / d1 truncates to 0
            tc.verifyTrue(div(d2, d1) == 0);
        end

        function mixed_freq_div_rem_throws(tc)
            d2 = tseries.Duration(tseries.Quarterly(), 4);
            d3 = tseries.Duration(tseries.Monthly(), 4);
            tc.verifyError(@() div(d2, d3), 'tseries:mixedFreq');
            tc.verifyError(@() rem(d2, d3), 'tseries:mixedFreq');
        end

        function duration_times_int(tc)
            d = tseries.Duration(tseries.Quarterly(), 3);
            r = 4 * d;
            tc.verifyClass(r, 'tseries.Duration');
            tc.verifyTrue(r == 12);
            r2 = d * 4;
            tc.verifyTrue(r2 == 12);
        end

        function negate_duration(tc)
            d = tseries.Duration(tseries.Quarterly(), 3);
            tc.verifyTrue(-d == -3);
        end
    end
end

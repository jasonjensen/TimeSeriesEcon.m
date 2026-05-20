classdef TestStripAndReindex < matlab.unittest.TestCase
    %TESTSTRIPANDREINDEX  Mirrors @testset "strip" and the reindex tests.

    methods (Test)

        function strip_trims_leading_and_trailing_nans(tc)
            rng_x = tseries.yy(2000):tseries.yy(2010);
            x = tseries.TSeries(rng_x, 1);
            x(tseries.yy(2011):tseries.yy(2015)) = NaN;
            x(tseries.yy(1995):tseries.yy(1999)) = NaN;
            stripped = tseries.strip_ts(x);
            tc.verifyTrue(tseries.rangeof(stripped).startMIT == rng_x.startMIT);
            tc.verifyTrue(tseries.rangeof(stripped).stopMIT  == rng_x.stopMIT);
        end

        function reindex_tseries(tc)
            ts = tseries.TSeries(tseries.qq(2020,1), randn(10,1));
            ts2 = tseries.reindex(ts, tseries.qq(2021,1), tseries.MIT(tseries.Unit(),1), 'copy', true);
            tc.verifyEqual(ts2(tseries.MIT(tseries.Unit(),3)), ts(tseries.qq(2021,3)));
            tc.verifyEqual(length(ts2), 10);
            tc.verifyEqual(ts2(tseries.MIT(tseries.Unit(),-3)), ts(tseries.qq(2020,1)));
        end

        function reindex_single_mit(tc)
            r = tseries.reindex(tseries.qq(2022,4), tseries.qq(2022,1), tseries.MIT(tseries.Unit(),1));
            tc.verifyClass(r, 'tseries.MIT');
            tc.verifyTrue(r == tseries.MIT(tseries.Unit(),4));
        end
    end
end

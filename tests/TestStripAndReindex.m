classdef TestStripAndReindex < matlab.unittest.TestCase
    %TESTSTRIPANDREINDEX  Mirrors @testset "strip" and the reindex tests.

    methods (Test)

        function strip_trims_leading_and_trailing_nans(tc)
            rng_x = tse.yy(2000):tse.yy(2010);
            x = tse.TSeries(rng_x, 1);
            x(tse.yy(2011):tse.yy(2015)) = NaN;
            x(tse.yy(1995):tse.yy(1999)) = NaN;
            stripped = tse.strip_ts(x);
            tc.verifyTrue(tse.rangeof(stripped).startMIT == rng_x.startMIT);
            tc.verifyTrue(tse.rangeof(stripped).stopMIT  == rng_x.stopMIT);
        end

        function reindex_tseries(tc)
            ts = tse.TSeries(tse.qq(2020,1), randn(10,1));
            ts2 = tse.reindex(ts, tse.qq(2021,1), tse.MIT(tse.Unit(),1), 'copy', true);
            tc.verifyEqual(ts2(tse.MIT(tse.Unit(),3)), ts(tse.qq(2021,3)));
            tc.verifyEqual(length(ts2), 10);
            tc.verifyEqual(ts2(tse.MIT(tse.Unit(),-3)), ts(tse.qq(2020,1)));
        end

        function reindex_single_mit(tc)
            r = tse.reindex(tse.qq(2022,4), tse.qq(2022,1), tse.MIT(tse.Unit(),1));
            tc.verifyClass(r, 'tse.MIT');
            tc.verifyTrue(r == tse.MIT(tse.Unit(),4));
        end
    end
end

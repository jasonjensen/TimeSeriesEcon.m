classdef TestRec < matlab.unittest.TestCase
    %TESTREC  Mirrors the @testset "recursive" block of test_tseries.jl.

    methods (Test)

        function fibonacci(tc)
            U = tseries.Unit();
            t = tseries.TSeries(tseries.MIT(U,1));
            t(tseries.MIT(U,1)) = 1;
            t(tseries.MIT(U,2)) = 1;
            rng = tseries.MIT(U,3) : tseries.MIT(U,10);
            t = tseries.rec(rng, t, @(s, k) s(k-1) + s(k-2));
            tc.verifyEqual(t.values, [1;1;2;3;5;8;13;21;34;55]);
        end

        function quarterly_series(tc)
            s = tseries.TSeries(tseries.qq(2020,1):tseries.qq(2021,4));
            s(tseries.qq(2020,1)) = 0;
            rng = tseries.qq(2020,2) : tseries.qq(2023,3);
            s = tseries.rec(rng, s, @(x, k) x(k-1) + 1);
            tc.verifyTrue(tseries.rangeof(s).startMIT == tseries.qq(2020,1));
            tc.verifyTrue(tseries.rangeof(s).stopMIT  == tseries.qq(2023,3));
            tc.verifyEqual(s.values, (0:14)');
        end
    end
end

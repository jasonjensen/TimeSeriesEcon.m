classdef TestRec < matlab.unittest.TestCase
    %TESTREC  Mirrors the @testset "recursive" block of test_tseries.jl.

    methods (Test)

        function fibonacci(tc)
            U = tse.Unit();
            t = tse.TSeries(tse.MIT(U,1));
            t(tse.MIT(U,1)) = 1;
            t(tse.MIT(U,2)) = 1;
            rng = tse.MIT(U,3) : tse.MIT(U,10);
            t = tse.rec(rng, t, @(s, k) s(k-1) + s(k-2));
            tc.verifyEqual(t.values, [1;1;2;3;5;8;13;21;34;55]);
        end

        function quarterly_series(tc)
            s = tse.TSeries(tse.qq(2020,1):tse.qq(2021,4));
            s(tse.qq(2020,1)) = 0;
            rng = tse.qq(2020,2) : tse.qq(2023,3);
            s = tse.rec(rng, s, @(x, k) x(k-1) + 1);
            tc.verifyTrue(tse.rangeof(s).startMIT == tse.qq(2020,1));
            tc.verifyTrue(tse.rangeof(s).stopMIT  == tse.qq(2023,3));
            tc.verifyEqual(s.values, (0:14)');
        end
    end
end

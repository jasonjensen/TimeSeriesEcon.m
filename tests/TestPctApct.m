classdef TestPctApct < matlab.unittest.TestCase
    %TESTPCTAPCT  Mirrors the @testset "pct" block of test_tseries.jl.

    methods (Test)

        function pct_basic(tc)
            t1 = tse.TSeries(tse.yy(2000), [1;2;4;8]);
            r = pct(t1);
            tc.verifyEqual(r.values, [100;100;100]);
            tc.verifyTrue(r.firstdate == tse.yy(2001));
        end

        function diff_range(tc)
            t1 = tse.TSeries(tse.yy(2000), [1;2;4;8]);
            d = diff(t1);
            tc.verifyTrue(tse.rangeof(d).startMIT == tse.yy(2001));
            tc.verifyTrue(tse.rangeof(d).stopMIT  == tse.yy(2003));
        end

        function pct_with_shift_minus_2(tc)
            t1 = tse.TSeries(tse.yy(2000), [1;2;4;8]);
            r = pct(t1, -2);
            tc.verifyEqual(r.values, [300;300]);
            tc.verifyTrue(r.firstdate == tse.yy(2002));
        end

        function pct_islog(tc)
            t2 = tse.TSeries(tse.yy(2000), log([1;2;4;8]));
            r = pct(t2, -1, 'islog', true);
            tc.verifyEqual(r.values, [100;100;100], 'AbsTol', 1e-9);
        end

        function apct_quarterly(tc)
            t3 = tse.TSeries(tse.qq(2000,1), 2 .^ (1:20)');
            r = apct(t3);
            tc.verifyEqual(r.values(1:3), [1500;1500;1500], 'AbsTol', 1e-9);
            tc.verifyTrue(tse.rangeof(r).startMIT == tse.qq(2000,2));
            tc.verifyTrue(tse.rangeof(r).stopMIT  == tse.qq(2004,4));
        end

        function apct_monthly(tc)
            t4 = tse.TSeries(tse.mm(2000,1), 2 .^ (1:20)');
            r = apct(t4);
            tc.verifyEqual(r.values(1:3), [409500;409500;409500], 'AbsTol', 1e-6);
        end

        function ytypct_yearly(tc)
            t1 = tse.TSeries(tse.yy(2000), [1;2;4;8]);
            r = tse.TSeries(tse.yy(2001), [100;100;100]);
            yt = ytypct(t1);
            tc.verifyEqual(yt.values, r.values);
        end

        function ytypct_quarterly(tc)
            t3 = tse.TSeries(tse.qq(2000,1), 2 .^ (1:20)');
            yt = ytypct(t3);
            tc.verifyEqual(yt.values(1:3), [1500;1500;1500], 'AbsTol', 1e-9);
            tc.verifyTrue(tse.rangeof(yt).startMIT == tse.qq(2001,1));
        end
    end
end

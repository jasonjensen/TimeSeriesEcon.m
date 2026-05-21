classdef TestIsassigned < matlab.unittest.TestCase
    %TESTISASSIGNED  Ports @testset "isassigned" of test_tseries.jl and
    %test_mvtseries.jl.

    methods (Test)

        function tseries_int_indexing(tc)
            x = tse.TSeries(tse.qq(2000,1):tse.qq(2002,1));
            for i = 1:length(x)
                tc.verifyTrue(isassigned(x, i));
            end
            tc.verifyFalse(isassigned(x, 0));
            tc.verifyFalse(isassigned(x, length(x) + 1));
        end

        function tseries_mit_indexing(tc)
            x = tse.TSeries(tse.qq(2000,1):tse.qq(2002,1));
            for d = collect(tse.rangeof(x))
                tc.verifyTrue(isassigned(x, d));
            end
            tc.verifyFalse(isassigned(x, x.firstdate - 1));
            tc.verifyFalse(isassigned(x, tse.lastdate(x) + 1));
        end

        function tseries_wrong_freq_throws(tc)
            x = tse.TSeries(tse.qq(2000,1):tse.qq(2002,1));
            tc.verifyError(@() isassigned(x, tse.mm(2000,1)), 'tseries:mixedFreq');
            tc.verifyError(@() isassigned(x, tse.yy(2000)),    'tseries:mixedFreq');
        end

        function mvts_int_pair(tc)
            a = rand(4, 2);
            b = tse.MVTSeries(tse.qq(2020,1), {'A','B'}, a);
            for i = -1:6
                for j = -1:4
                    matches = (i >= 1) && (i <= 4) && (j >= 1) && (j <= 2);
                    tc.verifyEqual(isassigned(b, i, j), matches);
                end
            end
        end

        function mvts_mit_name(tc)
            a = rand(4, 2);
            b = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'A','B'}, a);
            for i = -1:6
                mit = tse.qq(2020,1) + (i - 1);
                inRange = (i >= 1) && (i <= 4);
                tc.verifyEqual(isassigned(b, mit, 'A'), inRange);
                tc.verifyEqual(isassigned(b, mit, 'B'), inRange);
                tc.verifyFalse(isassigned(b, mit, 'C'));
            end
        end

        function mvts_wrong_freq_throws(tc)
            b = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'A','B'}, rand(4,2));
            tc.verifyError(@() isassigned(b, tse.mm(2020,2), 'A'), 'tseries:mixedFreq');
        end
    end
end

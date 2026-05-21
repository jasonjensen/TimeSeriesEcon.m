classdef TestFindAll < matlab.unittest.TestCase
    %TESTFINDALL  Mirrors @testset "findall" of test_various.jl.

    methods (Test)

        function find_tseries_returns_mits(tc)
            tt = tse.TSeries(tse.qq(2000,1), rand(10,1));
            tb = tt > 0.5;
            res = find(tb);
            tc.verifyClass(res, 'tse.MIT');
            tc.verifyEqual(numel(res), sum(tb.values));
        end

        function getindex_with_logical_tseries(tc)
            tt = tse.TSeries(tse.qq(2000,1), rand(10,1));
            tb = tt > 0.5;
            % Indexing with a logical TSeries returns a numeric vector
            tc.verifyEqual(tt(tb), tt.values(tb.values));
        end

        function setindex_with_logical_tseries(tc)
            tt = tse.TSeries(tse.qq(2000,1), rand(10,1));
            tb = tt > 0.5;
            tt(tb) = -1.0;
            tc.verifyTrue(all(tt.values(tb.values) == -1));
        end

        function find_mvts_logical(tc)
            tv = tse.MVTSeries(tse.qq(2000,1), {'a','b','c'}, rand(10,3));
            tm = tv > 0.5;
            r = find(tm);
            % Each row is [rowIdx, colIdx]
            tc.verifyEqual(size(r, 2), 2);
            tc.verifyEqual(size(r, 1), sum(tm.values(:)));
        end
    end
end

classdef TestMisc < matlab.unittest.TestCase
    %TESTMISC  Mirrors @testset "misc" of test_various.jl.
    %
    %   Note: Julia uses === (object identity) for `parent` and
    %   `transpose`.  In MATLAB value semantics we don't have a notion
    %   of object identity equivalent to that, so we test "equal-by-
    %   value" instead of "is-the-same-object".

    methods (Test)

        function parent_mvts_returns_values(tc)
            o = ones(20, 3);
            X = tse.MVTSeries(tse.yy(2000), {'x','y','z'}, o);
            tc.verifyEqual(parent(X), o);
        end

        function parent_tseries_returns_values(tc)
            v = (1:10)';
            t = tse.TSeries(tse.qq(2020,1), v);
            tc.verifyEqual(parent(t), v);
        end

        function transpose_mvts(tc)
            o = ones(20, 3);
            X = tse.MVTSeries(tse.yy(2000), {'x','y','z'}, o);
            tc.verifyEqual(transpose(X), transpose(o));
        end

        function transpose_tseries(tc)
            v = (1:10)';
            t = tse.TSeries(tse.qq(2020,1), v);
            tc.verifyEqual(transpose(t), transpose(v));
        end

        function compare_mvts_different_ranges(tc)
            X = tse.MVTSeries(tse.yy(2000), {'x','y','z'}, ones(20, 3));
            Z = tse.MVTSeries(tse.yy(2000), {'x','y','z'}, ones(15, 3));
            tc.verifyFalse(tse.compare(X.values, Z.values));
            tc.verifyFalse(tse.compare(X, Z, 'ignoreMissing', false));
            tc.verifyTrue(tse.compare(X, Z, 'ignoreMissing', true));
        end

        function axes1_returns_range(tc)
            X = tse.MVTSeries(tse.yy(2000), {'x','y','z'}, ones(15, 3));
            tc.verifyTrue(isequal(axes1(X), tse.rangeof(X)));
        end

        function linearindices_matches_values(tc)
            X = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, rand(10, 2));
            tc.verifyEqual(LinearIndices(X), tse.LinearIndices(X.values));
        end
    end
end

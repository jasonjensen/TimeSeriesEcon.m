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
            X = tseries.MVTSeries(tseries.yy(2000), {'x','y','z'}, o);
            tc.verifyEqual(parent(X), o);
        end

        function parent_tseries_returns_values(tc)
            v = (1:10)';
            t = tseries.TSeries(tseries.qq(2020,1), v);
            tc.verifyEqual(parent(t), v);
        end

        function transpose_mvts(tc)
            o = ones(20, 3);
            X = tseries.MVTSeries(tseries.yy(2000), {'x','y','z'}, o);
            tc.verifyEqual(transpose(X), transpose(o));
        end

        function transpose_tseries(tc)
            v = (1:10)';
            t = tseries.TSeries(tseries.qq(2020,1), v);
            tc.verifyEqual(transpose(t), transpose(v));
        end

        function compare_mvts_different_ranges(tc)
            X = tseries.MVTSeries(tseries.yy(2000), {'x','y','z'}, ones(20, 3));
            Z = tseries.MVTSeries(tseries.yy(2000), {'x','y','z'}, ones(15, 3));
            tc.verifyFalse(tseries.compare_ts(X.values, Z.values));
            tc.verifyFalse(tseries.compare_ts(X, Z, 'ignoreMissing', false));
            tc.verifyTrue(tseries.compare_ts(X, Z, 'ignoreMissing', true));
        end

        function axes1_returns_range(tc)
            X = tseries.MVTSeries(tseries.yy(2000), {'x','y','z'}, ones(15, 3));
            tc.verifyTrue(isequal(axes1(X), tseries.rangeof(X)));
        end

        function linearindices_matches_values(tc)
            X = tseries.MVTSeries(tseries.qq(2020,1), {'a','b'}, rand(10, 2));
            tc.verifyEqual(LinearIndices(X), tseries.LinearIndices(X.values));
        end
    end
end

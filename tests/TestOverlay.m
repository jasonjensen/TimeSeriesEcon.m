classdef TestOverlay < matlab.unittest.TestCase
    %TESTOVERLAY  Mirrors the @testset "overlay" block of test_tseries.jl.

    methods (Test)

        function overlay_two_series(tc)
            A = tseries.TSeries(tseries.yy(87), [1; 2; NaN; 4]);
            B = tseries.TSeries(tseries.yy(87), [NaN; 6; 7; 8]);
            tc.verifyEqual(tseries.overlay(A, B).values, [1;2;7;4]);
            tc.verifyEqual(tseries.overlay(B, A).values, [1;6;7;8]);
        end

        function overlay_with_explicit_range(tc)
            A = tseries.TSeries(tseries.yy(87), [1; 2; NaN; 4]);
            B = tseries.TSeries(tseries.yy(87), [NaN; 6; 7; 8]);
            rng = tseries.yy(86):tseries.yy(92);
            r = tseries.overlay(rng, A, B);
            tc.verifyClass(r, 'tseries.TSeries');
            tc.verifyTrue(r.firstdate == tseries.yy(86));
            tc.verifyEqual(length(r.values), 7);
            tc.verifyTrue(isnan(r.values(1)));   % 86Y not provided
            tc.verifyEqual(r.values(2:5), [1;2;7;4]);
            tc.verifyTrue(isnan(r.values(6)));
            tc.verifyTrue(isnan(r.values(7)));
        end

        function overlay_short_circuits_when_full(tc)
            A = tseries.TSeries(tseries.yy(87), [1; 2; 3; 4]);
            B = tseries.TSeries(tseries.yy(87), [5; 6; 7; 8]);
            r = tseries.overlay(A, B);
            tc.verifyEqual(r.values, [1;2;3;4]);
        end

        function overlay_scalar_passthrough(tc)
            tc.verifyEqual(tseries.overlay(1, 2), 1);
            tc.verifyEqual(tseries.overlay(NaN, 5), 5);
        end
    end
end

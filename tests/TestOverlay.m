classdef TestOverlay < matlab.unittest.TestCase
    %TESTOVERLAY  Mirrors the @testset "overlay" block of test_tseries.jl.

    methods (Test)

        function overlay_two_series(tc)
            A = tse.TSeries(tse.yy(87), [1; 2; NaN; 4]);
            B = tse.TSeries(tse.yy(87), [NaN; 6; 7; 8]);
            tc.verifyEqual(tse.overlay(A, B).values, [1;2;7;4]);
            tc.verifyEqual(tse.overlay(B, A).values, [1;6;7;8]);
        end

        function overlay_with_explicit_range(tc)
            A = tse.TSeries(tse.yy(87), [1; 2; NaN; 4]);
            B = tse.TSeries(tse.yy(87), [NaN; 6; 7; 8]);
            rng = tse.yy(86):tse.yy(92);
            r = tse.overlay(rng, A, B);
            tc.verifyClass(r, 'tse.TSeries');
            tc.verifyTrue(r.firstdate == tse.yy(86));
            tc.verifyEqual(length(r.values), 7);
            tc.verifyTrue(isnan(r.values(1)));   % 86Y not provided
            tc.verifyEqual(r.values(2:5), [1;2;7;4]);
            tc.verifyTrue(isnan(r.values(6)));
            tc.verifyTrue(isnan(r.values(7)));
        end

        function overlay_short_circuits_when_full(tc)
            A = tse.TSeries(tse.yy(87), [1; 2; 3; 4]);
            B = tse.TSeries(tse.yy(87), [5; 6; 7; 8]);
            r = tse.overlay(A, B);
            tc.verifyEqual(r.values, [1;2;3;4]);
        end

        function overlay_scalar_passthrough(tc)
            tc.verifyEqual(tse.overlay(1, 2), 1);
            tc.verifyEqual(tse.overlay(NaN, 5), 5);
        end
    end
end

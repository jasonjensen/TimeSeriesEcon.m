classdef TestMVTSeriesOverlay < matlab.unittest.TestCase
    %TESTMVTSERIESOVERLAY  Mirrors @testset "overlay2" of test_various.jl.

    methods (Test)

        function overlay_two_mvts(tc)
            a = tseries.MVTSeries(tseries.qq(2020,1), {'a','b','c'}, ones(7,3));
            b = tseries.MVTSeries(tseries.qq(2021,1), {'q','b','c','f'}, 10 + 0.1 * ones(10,4));
            c = tseries.overlay(a, b);
            tc.verifyClass(c, 'tseries.MVTSeries');
            tc.verifyTrue(eq(tseries.frequencyof(c), tseries.frequencyof(a)));
            tc.verifyTrue(isequal(tseries.rangeof(c), tseries.qq(2020,1):tseries.qq(2023,2)));
            tc.verifyEqual(c.colnames, ["a","b","c","q","f"]);

            mat1 = [
                1.0 1.0 1.0 NaN NaN
                1.0 1.0 1.0 NaN NaN
                1.0 1.0 1.0 NaN NaN
                1.0 1.0 1.0 NaN NaN
                1.0 1.0 1.0 10.1 10.1
                1.0 1.0 1.0 10.1 10.1
                1.0 1.0 1.0 10.1 10.1
                NaN 10.1 10.1 10.1 10.1
                NaN 10.1 10.1 10.1 10.1
                NaN 10.1 10.1 10.1 10.1
                NaN 10.1 10.1 10.1 10.1
                NaN 10.1 10.1 10.1 10.1
                NaN 10.1 10.1 10.1 10.1
                NaN 10.1 10.1 10.1 10.1];
            tc.verifyEqual(c.values, mat1, 'AbsTol', 1e-9);
        end

        function overlay_reversed_takes_first(tc)
            a = tseries.MVTSeries(tseries.qq(2020,1), {'a','b','c'}, ones(7,3));
            b = tseries.MVTSeries(tseries.qq(2021,1), {'q','b','c','f'}, 10 + 0.1 * ones(10,4));
            d = tseries.overlay(b, a);
            tc.verifyEqual(d.colnames, ["q","b","c","f","a"]);
        end
    end
end

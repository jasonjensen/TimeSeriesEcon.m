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
        function other_series_indexed_by_date(tc)
            % A second series that starts on a different date must be read
            % by date, not by position (regression: the old auto fast path
            % passed integer positions and misaligned x silently).
            x = tse.TSeries(tse.qq(2019,1), (1:20)');       % starts earlier
            y = tse.TSeries(tse.qq(2020,1), zeros(8, 1));
            y = tse.rec(tse.qq(2020,2):tse.qq(2021,4), y, @(s, t) s(t-1) + x(t));
            expected = zeros(8, 1);
            for k = 2:8
                expected(k) = expected(k-1) + (4 + k);      % x(2020Q1) = 5
            end
            tc.verifyEqual(y.values, expected);
        end

        function mit_comparison_in_body(tc)
            y = tse.TSeries(tse.qq(2020,1), zeros(8, 1));
            y = tse.rec(tse.qq(2020,2):tse.qq(2021,4), y, ...
                @(s, t) s(t-1) + double(t >= tse.qq(2021,1)));
            tc.verifyEqual(y.values, [0;0;0;0;1;2;3;4]);
        end

        function fast_option_matches_default(tc)
            U = tse.Unit();
            t = tse.TSeries(tse.MIT(U,1), [1; 1; zeros(8,1)]);
            rng = tse.MIT(U,3) : tse.MIT(U,10);
            a = tse.rec(rng, t, @(v, i) v(i-1) + v(i-2), 'fast', true);
            b = tse.rec(rng, t, @(v, i) v(i-1) + v(i-2));
            tc.verifyEqual(a.values, [1;1;2;3;5;8;13;21;34;55]);
            tc.verifyEqual(a.values, b.values);
        end

        function fast_option_grows_target(tc)
            s = tse.TSeries(tse.qq(2020,1):tse.qq(2021,4));
            s(tse.qq(2020,1)) = 0;
            s = tse.rec(tse.qq(2020,2):tse.qq(2023,3), s, @(v, i) v(i-1) + 1, 'fast', true);
            tc.verifyTrue(tse.rangeof(s).stopMIT == tse.qq(2023,3));
            tc.verifyEqual(s.values, (0:14)');
        end

        function fast_option_backward(tc)
            b = tse.TSeries(tse.qq(2020,1), zeros(4, 1));
            b(tse.qq(2020,4)) = 1;
            b = tse.rec(tse.qq(2020,3):-1:tse.qq(2019,3), b, @(v, i) v(i+1) - 0.25, 'fast', true);
            tc.verifyTrue(b.firstdate == tse.qq(2019,3));
            tc.verifyEqual(b.values, (-0.25:0.25:1)', 'AbsTol', 1e-12);
        end

        function bad_option_errors(tc)
            t = tse.TSeries(tse.qq(2020,1), zeros(4, 1));
            rng = tse.qq(2020,2):tse.qq(2020,4);
            tc.verifyError(@() tse.rec(rng, t, @(s, k) s(k-1), 'speed', true), 'tseries:noMatch');
        end
    end
end

classdef TestFconvert < matlab.unittest.TestCase
    %TESTFCONVERT  Mirrors test/test_fconvert.jl (frequency conversion).
    %   Covers the general, YP->higher, YP->lower, YP->similar sections in
    %   full, plus a representative Daily->Monthly and Weekly chained case.

    methods (Static)
        function m = Y(y), m = tse.MIT(tse.Yearly(), int64(y)); end
        function m = Yn(y, ep), m = tse.MIT(tse.Yearly(ep), int64(y)); end
        function m = H(y, p), m = tse.MIT(tse.HalfYearly(), int64(y), int64(p)); end
        function m = Q(y, p), m = tse.qq(y, p); end
        function m = Qn(y, p, ep), m = tse.MIT(tse.Quarterly(ep), int64(y), int64(p)); end
        function m = M(y, p), m = tse.mm(y, p); end
        function m = D(v), m = tse.MIT(tse.Daily(), int64(v)); end
        function m = W(v, ep), m = tse.MIT(tse.Weekly(ep), int64(v)); end
        function r = R(a, b), r = tse.MITRange(a, b); end
    end

    methods (Test)

        % ---------------- general ----------------
        function general(tc)
            import tse.*
            t = tse.TSeries(tse.MIT(tse.Unit(), 5), (1:10)');
            tc.verifyTrue(isequal(tse.fconvert(tse.Unit(), t), t));
            tc.verifyError(@() tse.fconvert(tse.Quarterly(), t), 'tseries:noMatch');

            q = tse.TSeries(tc.Q(5,1), (1:10)');
            tc.verifyError(@() tse.fconvert(tse.Unit(), q), 'tseries:noMatch');
            mq = tse.fconvert(tse.Monthly(), q, 'method', 'const');
            tc.verifyEqual(mq.values, repelem((1:10)', 3), 'AbsTol', 1e-12);

            tc.verifyEqual(tse.fconvert(tse.Yearly(), q, 'method','mean').values, [2.5;6.5], 'AbsTol',1e-12);
            tc.verifyEqual(tse.fconvert(tse.Yearly(), q, 'method','point','ref','end').values, [4;8], 'AbsTol',1e-12);
            tc.verifyEqual(tse.fconvert(tse.Yearly(), q, 'method','end').values, [4;8], 'AbsTol',1e-12);
            tc.verifyEqual(tse.fconvert(tse.Yearly(), q, 'method','point','ref','begin').values, [1;5;9], 'AbsTol',1e-12);
            tc.verifyEqual(tse.fconvert(tse.Yearly(), q, 'method','begin').values, [1;5;9], 'AbsTol',1e-12);
            tc.verifyEqual(tse.fconvert(tse.Yearly(), q, 'method','sum').values, [10;26], 'AbsTol',1e-12);

            h = tse.TSeries(tc.H(5,1), (1:10)');
            tc.verifyEqual(tse.fconvert(tse.Yearly(), h, 'method','mean').values, [1.5;3.5;5.5;7.5;9.5], 'AbsTol',1e-12);
            tc.verifyEqual(tse.fconvert(tse.Yearly(), h, 'method','point','ref','end').values, [2;4;6;8;10], 'AbsTol',1e-12);
            tc.verifyEqual(tse.fconvert(tse.Yearly(), h, 'method','point','ref','begin').values, [1;3;5;7;9], 'AbsTol',1e-12);
            tc.verifyEqual(tse.fconvert(tse.Yearly(), h, 'method','sum').values, [3;7;11;15;19], 'AbsTol',1e-12);

            % wrong method for direction
            tc.verifyError(@() tse.fconvert(tse.Monthly(), q, 'method','mean'), 'tseries:noMatch');
            tc.verifyError(@() tse.fconvert(tse.Yearly(),  q, 'method','const'), 'tseries:noMatch');

            % no-op conversions
            tc.verifyTrue(eq(tse.fconvert(tse.Monthly(), tc.R(tc.M(1,1), tc.M(1,5))), tc.R(tc.M(1,1), tc.M(1,5))));
            tc.verifyTrue(eq(tse.fconvert(tse.Monthly(), tc.M(1,1)), tc.M(1,1)));
        end

        % ---------------- YP -> higher ----------------
        function yp_to_higher(tc)
            y1 = tse.TSeries(tc.Y(22), [1;2]);
            q1 = tse.fconvert(tse.Quarterly(), y1);
            tc.verifyTrue(eq(rangeof(q1), tc.R(tc.Q(22,1), tc.Q(23,4))));
            tc.verifyEqual(q1.values, [1;1;1;1;2;2;2;2], 'AbsTol',1e-12);

            q1b = tse.fconvert(tse.Quarterly(), y1, 'ref','begin');
            tc.verifyTrue(eq(rangeof(q1b), tc.R(tc.Q(22,1), tc.Q(23,4))));

            r1 = tse.fconvert(tse.Quarterly(), rangeof(y1), 'trim','end');
            tc.verifyTrue(eq(r1, tc.R(tc.Q(22,1), tc.Q(23,4))));

            y2 = tse.TSeries(tc.Yn(22,7), [1;2]);
            q2 = tse.fconvert(tse.Quarterly(), y2);
            tc.verifyEqual(q2.values, [1;1;1;1;2;2;2;2], 'AbsTol',1e-12);
            tc.verifyTrue(eq(rangeof(q2), tc.R(tc.Q(21,3), tc.Q(23,2))));
            q2b = tse.fconvert(tse.Quarterly(), y2, 'ref','begin');
            tc.verifyTrue(eq(rangeof(q2b), tc.R(tc.Q(21,4), tc.Q(23,3))));

            % Yearly -> Monthly
            y4 = tse.TSeries(tc.Y(22), [1;2]);
            m1 = tse.fconvert(tse.Monthly(), y4);
            tc.verifyTrue(eq(rangeof(m1), tc.R(tc.M(22,1), tc.M(23,12))));
            tc.verifyEqual(m1.values, [repmat(1,12,1); repmat(2,12,1)], 'AbsTol',1e-12);

            y5 = tse.TSeries(tc.Yn(22,7), [1;2]);
            m2 = tse.fconvert(tse.Monthly(), y5);
            tc.verifyTrue(eq(rangeof(m2), tc.R(tc.M(21,8), tc.M(23,7))));

            % linear (Quarterly -> Monthly)
            q7 = tse.TSeries(tc.Q(2022,1), (1:12)');
            m7b = tse.fconvert(tse.Monthly(), q7, 'method','linear','ref','begin');
            tc.verifyTrue(eq(rangeof(m7b), tc.R(tc.M(2022,1), tc.M(2024,12))));
            tc.verifyEqual(m7b.values(1:4), [1;1+1/3;1+2/3;2], 'AbsTol',1e-9);

            % even (HalfYearly -> Monthly)
            h8 = tse.TSeries(tc.H(2022,1), (1:5)');
            m8e = tse.fconvert(tse.Monthly(), h8, 'method','even');
            tc.verifyEqual(m8e.values, repelem((1:5)',6)/6, 'AbsTol',1e-12);
        end

        % ---------------- YP -> lower ----------------
        function yp_to_lower(tc)
            q1 = tse.TSeries(tc.Q(1,2), [1;1;2;2;3;3;4;4;5;5;6;6;7;7;8;8]);
            y1 = tse.fconvert(tse.Yearly(), q1, 'method','mean');
            tc.verifyTrue(eq(rangeof(y1), tc.R(tc.Y(2), tc.Y(4))));
            tc.verifyEqual(y1.values, [3;5;7], 'AbsTol',1e-12);

            q2 = tse.TSeries(tc.Qn(2,1,2), [1;1;2;2;3;3;4;4;5;5;6;6;7;7;8;8]);
            y2 = tse.fconvert(tse.Yearly(), q2, 'method','mean');
            tc.verifyTrue(eq(rangeof(y2), tc.R(tc.Y(3), tc.Y(5))));
            tc.verifyEqual(y2.values, [3;5;7], 'AbsTol',1e-12);

            m5 = tse.TSeries(tc.M(20,1), (1:36)');
            y5 = tse.fconvert(tse.Yearly(), m5, 'method','mean');
            tc.verifyTrue(eq(rangeof(y5), tc.R(tc.Y(20), tc.Y(22))));
            tc.verifyEqual(y5.values, [6.5;18.5;30.5], 'AbsTol',1e-12);

            q7 = tse.fconvert(tse.Quarterly(), m5, 'method','mean');
            tc.verifyTrue(eq(rangeof(q7), tc.R(tc.Q(20,1), tc.Q(22,4))));
            tc.verifyEqual(q7.values, (2:3:35)', 'AbsTol',1e-12);

            % point method
            q9 = tse.TSeries(tc.Q(2022,1), (1:10)');
            y9b = tse.fconvert(tse.Yearly(), q9, 'method','point','ref','begin');
            tc.verifyTrue(eq(rangeof(y9b), tc.R(tc.Y(2022), tc.Y(2024))));
            tc.verifyEqual(y9b.values, [1;5;9], 'AbsTol',1e-12);
            y9e = tse.fconvert(tse.Yearly(), q9, 'method','point','ref','end');
            tc.verifyTrue(eq(rangeof(y9e), tc.R(tc.Y(2022), tc.Y(2023))));
            tc.verifyEqual(y9e.values, [4;8], 'AbsTol',1e-12);
        end

        % ---------------- YP -> similar ----------------
        function yp_to_similar(tc)
            qs1 = tse.TSeries(tc.Qn(2022,2,2), (2:4)');
            qs2 = tse.fconvert(tse.Quarterly(), qs1, 'method','point','ref','end');
            tc.verifyTrue(eq(rangeof(qs2), tc.R(tc.Q(2022,2), tc.Q(2022,4))));
            tc.verifyEqual(qs2.values, [2;3;4], 'AbsTol',1e-12);
            qs3 = tse.fconvert(tse.Quarterly(), qs1, 'method','point','ref','begin');
            tc.verifyTrue(eq(rangeof(qs3), tc.R(tc.Q(2022,2), tc.Q(2022,4))));
            tc.verifyEqual(qs3.values, [2;3;4], 'AbsTol',1e-12);
        end

        % ---------------- Daily -> Monthly ----------------
        function daily_to_monthly(tc)
            t1 = tse.TSeries(tc.D(1), (1:100)');   % starts 0001-01-01
            r1 = tse.fconvert(tse.Monthly(), t1, 'method','mean');
            tc.verifyEqual(r1.values, [16; 45.5; 75], 'AbsTol',1e-9);
            tc.verifyTrue(eq(rangeof(r1), tc.R(tc.M(1,1), tc.M(1,3))));

            r2 = tse.fconvert(tse.Monthly(), t1, 'method','point','ref','end');
            tc.verifyEqual(r2.values, [31; 31+28; 31+28+31], 'AbsTol',1e-9);
            tc.verifyTrue(eq(rangeof(r2), tc.R(tc.M(1,1), tc.M(1,3))));

            r3 = tse.fconvert(tse.Monthly(), t1, 'method','point','ref','begin');
            tc.verifyEqual(r3.values, [1; 1+31; 1+31+28; 1+31+28+31], 'AbsTol',1e-9);
            tc.verifyTrue(eq(rangeof(r3), tc.R(tc.M(1,1), tc.M(1,4))));

            r4 = tse.fconvert(tse.Monthly(), t1, 'method','sum');
            tc.verifyEqual(r4.values, [sum(1:31); sum(32:59); sum(60:90)], 'AbsTol',1e-9);
            tc.verifyTrue(eq(rangeof(r4), tc.R(tc.M(1,1), tc.M(1,3))));
        end

        % ---------------- range conversions ----------------
        function range_conversions(tc)
            tc.verifyTrue(eq(tse.fconvert(tse.Yearly(), tc.R(tc.Q(2022,1), tc.Q(2024,4))), ...
                             tc.R(tc.Y(2022), tc.Y(2024))));
            tc.verifyTrue(eq(tse.fconvert(tse.Monthly(), tc.R(tc.D(1), tc.D(100)), 'trim','both'), ...
                             tc.R(tc.M(1,1), tc.M(1,3))));
        end

        % ---------------- Weekly chained (linear day interp) ----------------
        function weekly_to_monthly_chained(tc)
            t1 = tse.TSeries(tc.W(1,7), (1:20)');
            r1 = tse.fconvert(tse.Monthly(), tse.fconvert(tse.Daily(), t1, 'method','linear'), 'method','mean');
            tc.verifyEqual(r1.values, [2.286; 6.5; 10.714; 15.071], 'AbsTol', 1e-2);
            tc.verifyTrue(eq(rangeof(r1), tc.R(tc.M(1,1), tc.M(1,4))));
        end

        % ---------------- custom function ----------------
        function custom_function(tc)
            % lower: aggregator over each group
            m = tse.TSeries(tc.M(20,1), (1:36)');
            y = tse.fconvert(@(v) sum(v), tse.Yearly(), m);
            tc.verifyEqual(y.values, [sum(1:12); sum(13:24); sum(25:36)], 'AbsTol',1e-9);
        end
    end
end

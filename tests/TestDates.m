classdef TestDates < matlab.unittest.TestCase
    %TESTDATES  Mirrors @testset "daily, business_daily", "Weekly", "Dates"
    %           of test_mit.jl.

    methods (Test)
        function daily_basic(tc)
            % Julia: MIT{Daily}(738156) corresponds to Date("2022-01-01")
            d1 = tse.MIT(tse.Daily(), 738156);
            tc.verifyEqual(datetime(2022,1,1), tse.toDate(d1));

            d2 = tse.day('2022-01-01');
            tc.verifyClass(d2, 'tse.MIT');
            tc.verifyTrue(d1 == d2);

            d3 = tse.MIT(tse.Daily(), 2022, 1);
            tc.verifyTrue(d1 == d3);
        end

        function daily_range(tc)
            rng = tse.day('2022-01-01', '2022-01-20');
            tc.verifyClass(rng, 'tse.MITRange');
            tc.verifyTrue(isa(tse.frequencyof(rng.startMIT), 'tse.Daily'));
            tc.verifyEqual(datetime(2022,1,1),  tse.toDate(rng.startMIT));
            tc.verifyEqual(datetime(2022,1,20), tse.toDate(rng.stopMIT));
        end

        function mit2yp_daily(tc)
            tc.verifyEqual(double(tse.mit2yp(tse.day('2022-01-01'))), [2022, 1]);
            tc.verifyEqual(double(tse.mit2yp(tse.day('2022-01-03'))), [2022, 3]);
        end

        function mit2yp_bdaily(tc)
            tc.verifyEqual(double(tse.mit2yp(tse.bday('2022-01-03'))), [2022, 1]);
            tc.verifyEqual(double(tse.mit2yp(tse.bday('2022-01-04'))), [2022, 2]);
        end

        function bdaily_basic(tc)
            bd1 = tse.MIT(tse.BDaily(), 527256);
            tc.verifyEqual(datetime(2022,1,3), tse.toDate(bd1));
            bd2 = tse.bday('2022-01-03');
            tc.verifyTrue(bd1 == bd2);

            bd3 = tse.MIT(tse.BDaily(), 2022, 1);
            tc.verifyTrue(bd1 == bd3);
        end

        function bdaily_strict_default_on_weekend_throws(tc)
            tc.verifyError(@() tse.bday('2022-01-02'), 'tseries:noMatch');
        end

        function bdaily_previous_next(tc)
            tc.verifyEqual(datetime(2021,12,31), ...
                tse.toDate(tse.bday('2022-01-02', 'bias', 'previous')));
            tc.verifyEqual(datetime(2022,1,3), ...
                tse.toDate(tse.bday('2022-01-02', 'bias', 'next')));
        end

        function bdaily_nearest(tc)
            % Saturday rounds to Friday
            tc.verifyTrue(tse.bday('2022-01-01','bias','nearest') == tse.bday('2021-12-31'));
            % Sunday rounds to Monday
            tc.verifyTrue(tse.bday('2022-01-02','bias','nearest') == tse.bday('2022-01-03'));
        end

        function bdaily_range(tc)
            r = tse.bday('2022-01-01', '2022-01-22');
            tc.verifyClass(r, 'tse.MITRange');
            tc.verifyTrue(isa(tse.frequencyof(r.startMIT), 'tse.BDaily'));
            tc.verifyEqual(datetime(2022,1,3),  tse.toDate(r.startMIT));
            tc.verifyEqual(datetime(2022,1,21), tse.toDate(r.stopMIT));
        end

        function weekly_basic(tc)
            w1 = tse.MIT(tse.Weekly(7), 105451);
            tc.verifyTrue(isa(tse.frequencyof(w1), 'tse.Weekly'));
            tc.verifyTrue(tse.week('2022-01-01') == w1);
            tc.verifyTrue(tse.week('2022-01-01', 7) == w1);

            w2 = tse.MIT(tse.Weekly(6), 105451);
            tc.verifyTrue(tse.week('2022-01-01', 6) == w2);
        end

        function weekly_from_iso_examples(tc)
            tc.verifyEqual(datetime(2022,1,2), tse.toDate(tse.weekly_from_iso(2021,52)));
            tc.verifyEqual(datetime(2022,1,9), tse.toDate(tse.weekly_from_iso(2022,1)));
            tc.verifyEqual(datetime(2022,1,16), tse.toDate(tse.weekly_from_iso(2022,2)));
            tc.verifyError(@() tse.weekly_from_iso(2021,53), 'tseries:noMatch');
            tc.verifyEqual(datetime(2021,1,3), tse.toDate(tse.weekly_from_iso(2020,53)));
        end

        function date_round_trip(tc)
            tc.verifyEqual(datetime(2022,12,31), tse.toDate(tse.yy(2022)));
            tc.verifyEqual(datetime(2022,1,1),   tse.toDate(tse.yy(2022), 'begin'));
            tc.verifyEqual(datetime(2022,3,31),  tse.toDate(tse.qq(2022,1)));
            tc.verifyEqual(datetime(2022,1,1),   tse.toDate(tse.qq(2022,1), 'begin'));
            tc.verifyEqual(datetime(2022,6,30),  tse.toDate(tse.MIT(tse.HalfYearly(),2022,1)));
            tc.verifyEqual(datetime(2022,1,31),  tse.toDate(tse.mm(2022,1)));
            tc.verifyEqual(datetime(2022,1,1),   tse.toDate(tse.mm(2022,1), 'begin'));
            tc.verifyEqual(datetime(2022,1,2),   tse.toDate(tse.week('2022-01-01')));
            tc.verifyEqual(datetime(2021,12,27), tse.toDate(tse.week('2022-01-01'), 'begin'));
            tc.verifyEqual(datetime(2022,1,1),   tse.toDate(tse.week('2022-01-01', 6)));
        end
    end
end

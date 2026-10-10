classdef TestIrisIsoWeek < matlab.unittest.TestCase
    %TESTIRISISOWEEK  tse.iris.iso_week, the week numbering tse.iris.to_date
    %   passes to IRIS's ww(y, w).  Does not need IRIS, so it runs in CI.

    methods (Test)

        function known_iso_weeks(tc)
            % Sunday-ending weeks around new year, where ISO and
            % ceil(day-of-year / 7) numbering disagree.
            cases = { ...
                '2020-01-05', [2020 1]; ...
                '2021-01-03', [2020 53]; ...
                '2021-01-10', [2021 1]; ...
                '2023-01-01', [2022 52]; ...
                '2023-01-08', [2023 1]; ...
                '2026-01-04', [2026 1]; ...
                '2026-12-27', [2026 52]};
            for i = 1:size(cases, 1)
                tc.verifyEqual(tse.iris.iso_week(tse.week(cases{i, 1})), cases{i, 2}, cases{i, 1});
            end
        end

        function matches_matlab_iso_week_and_inverts(tc)
            d = datetime(2015, 1, 4);              % a Sunday
            while d <= datetime(2028, 12, 31)
                m = tse.week(d);
                yw = tse.iris.iso_week(m);
                tc.verifyEqual(yw(2), week(d, 'iso-weekofyear'), char(d));
                tc.verifyTrue(tse.weekly_from_iso(yw(1), yw(2)) == m, char(d));
                d = d + days(7);
            end
        end

        function non_sunday_week_uses_its_last_day(tc)
            % Thursday 2020-12-31 to Wednesday 2021-01-06: the last day
            % falls in ISO week 1 of 2021.
            tc.verifyEqual(tse.iris.iso_week(tse.week('2021-01-06', 3)), [2021 1]);
        end

        function rejects_other_frequencies(tc)
            tc.verifyError(@() tse.iris.iso_week(tse.qq(2020, 1)), 'tseries:noMatch');
        end

    end
end

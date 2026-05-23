classdef TestFconvertHolidays < matlab.unittest.TestCase
    %TESTFCONVERTHOLIDAYS  Smoke tests for the bundled holidays calendar
    %   (data/holidays.bin from TimeSeriesEcon.jl) and the skip_holidays
    %   path of fconvert.

    methods (TestMethodTeardown)
        function clearMap(~)
            tse.clear_holidays_map();
        end
    end

    methods (Test)
        function options_listing(tc)
            countries = tse.get_holidays_options();
            tc.verifyTrue(any(countries == "CA"));
            subs = tse.get_holidays_options('CA');
            tc.verifyTrue(any(subs == "ON"));
        end

        function load_map(tc)
            tse.set_holidays_map('CA', 'ON');
            map = tse.getoption('bdaily_holidays_map');
            tc.verifyClass(map, 'tse.TSeries');
            tc.verifyEqual(numel(map.values), 20872);   % business days 1970..2049
            % New Year's Day 2021 (Fri) is a holiday -> false (not a workday)
            tc.verifyFalse(logical(map(tse.bdaily('2021-01-01'))));
            % A regular Monday is a working day -> true
            tc.verifyTrue(logical(map(tse.bdaily('2021-01-04'))));
        end

        function default_subdivision(tc)
            % CA has subdivisions; calling without one defaults to ON.
            tse.set_holidays_map('CA');
            map = tse.getoption('bdaily_holidays_map');
            tc.verifyClass(map, 'tse.TSeries');
        end

        function clear_map(tc)
            tse.set_holidays_map('CA', 'ON');
            tse.clear_holidays_map();
            tc.verifyEmpty(tse.getoption('bdaily_holidays_map'));
        end

        function skip_holidays_runs(tc)
            % BDaily -> Monthly with skip_holidays should run end to end.
            tse.set_holidays_map('CA', 'ON');
            rng = tse.bdaily('2021-01-01', '2021-03-31');
            t = tse.TSeries(rng.startMIT, (1:length(rng))');
            r = tse.fconvert(tse.Monthly(), t, 'method', 'mean', 'skip_holidays', true);
            tc.verifyClass(r, 'tse.TSeries');
            tc.verifyGreaterThanOrEqual(numel(r.values), 1);
        end
    end
end

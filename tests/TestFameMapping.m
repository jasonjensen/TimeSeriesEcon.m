classdef TestFameMapping < matlab.unittest.TestCase
    %TESTFAMEMAPPING  Frequency and type mapping tests for tse.fame.*.
    %
    %   These are pure MATLAB (no FAME CHLI required), so the suite always
    %   runs -- it locks the tse <-> FAME frequency and type encoding that
    %   the later CHLI-backed read/write layers build on.

    methods (Test)

        function freq_roundtrips(tc)
            % name, tse.Frequency, expected FAME code
            cases = { ...
                'daily',           tse.Daily(),        8; ...
                'business',        tse.BDaily(),       9; ...
                'weekly_sunday',   tse.Weekly(7),      16; ...
                'weekly_monday',   tse.Weekly(1),      17; ...
                'weekly_saturday', tse.Weekly(6),      22; ...
                'monthly',         tse.Monthly(),      129; ...
                'quarterly_oct',   tse.Quarterly(1),   160; ...
                'quarterly_dec',   tse.Quarterly(3),   162; ...
                'semiannual_jul',  tse.HalfYearly(1),  204; ...
                'semiannual_dec',  tse.HalfYearly(6),  209; ...
                'annual_january',  tse.Yearly(1),      192; ...
                'annual_december', tse.Yearly(12),     203; ...
                'case',            tse.Unit(),         232};
            for i = 1:size(cases, 1)
                F    = cases{i, 2};
                code = cases{i, 3};
                tc.verifyEqual(tse.fame.freq_to_fame(F), code, ...
                    sprintf('freq_to_fame mismatch for %s', cases{i, 1}));
                F2 = tse.fame.freq_from_fame(code);
                tc.verifyClass(F2, class(F));
                if isprop(F, 'endPeriod')
                    tc.verifyEqual(F2.endPeriod, F.endPeriod, ...
                        sprintf('endPeriod round-trip for %s', cases{i, 1}));
                end
            end
        end

        function every_weekly_endday_roundtrips(tc)
            for ep = 1:7
                code = tse.fame.freq_to_fame(tse.Weekly(ep));
                F2   = tse.fame.freq_from_fame(code);
                tc.verifyClass(F2, 'tse.Weekly');
                tc.verifyEqual(F2.endPeriod, ep);
            end
            % Sunday is the wrap-around case (code 16, not 23).
            tc.verifyEqual(tse.fame.freq_to_fame(tse.Weekly(7)), 16);
        end

        function every_yearly_endmonth_roundtrips(tc)
            for ep = 1:12
                code = tse.fame.freq_to_fame(tse.Yearly(ep));
                tc.verifyEqual(code, 191 + ep);
                tc.verifyEqual(tse.fame.freq_from_fame(code).endPeriod, ep);
            end
        end

        function unsupported_fame_frequencies_error(tc)
            for code = [0, 32, 64, 77, 128, 144, 145, 224, 225, 226, 228, 233]
                tc.verifyError(@() tse.fame.freq_from_fame(code), 'tseries:noMatch', ...
                    sprintf('expected rejection of FAME code %d', code));
            end
        end

        function freq_to_fame_rejects_non_frequency(tc)
            tc.verifyError(@() tse.fame.freq_to_fame(42), 'tseries:noMatch');
        end

        function type_mapping(tc)
            tc.verifyEqual(tse.fame.type_to_fame(double(1)),  5);   % precision
            tc.verifyEqual(tse.fame.type_to_fame(single(1)),  1);   % numeric
            tc.verifyEqual(tse.fame.type_to_fame(true),       3);   % boolean
            tc.verifyEqual(tse.fame.type_to_fame("hi"),       4);   % string
            tc.verifyEqual(tse.fame.type_to_fame(int32(3)),   5);   % promoted to precision

            tc.verifyEqual(tse.fame.type_from_fame(5), 'double');
            tc.verifyEqual(tse.fame.type_from_fame(1), 'single');
            tc.verifyEqual(tse.fame.type_from_fame(3), 'logical');
            tc.verifyEqual(tse.fame.type_from_fame(4), 'string');
            tc.verifyEqual(tse.fame.type_from_fame(6), 'tse.MIT');
        end

        function type_to_fame_for_dates_carries_frequency(tc)
            m = tse.qq(2020, 1);
            [code, datefreq] = tse.fame.type_to_fame(m);
            tc.verifyEqual(code, 6);          % date
            tc.verifyEqual(datefreq, 162);    % Quarterly(3) -> quarterly_december
        end

        function type_from_fame_rejects_namelist(tc)
            tc.verifyError(@() tse.fame.type_from_fame(2), 'tseries:noMatch');
        end

    end
end

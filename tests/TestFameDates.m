classdef TestFameDates < matlab.unittest.TestCase
    %TESTFAMEDATES  Date / range round-trip tests for tse.fame.* (CHLI-backed).
    %
    %   These need the FAME CHLI loaded (tse.fame.startup), so the whole suite
    %   skips cleanly when it is not -- keeping CI green without FAME.  Unlike
    %   the mapping tests (TestFameMapping), these exercise the C library.

    methods (TestMethodSetup)
        function skipIfNoFame(tc)
            if ~tse.fame.isavailable()
                tc.assumeFail('FAME CHLI is not loaded; run tse.fame.startup first.');
            end
        end
    end

    methods (Test)

        function date_roundtrips(tc)
            cases = { ...
                tse.yy(2020); ...
                tse.qq(2020, 3); ...
                tse.mm(2020, 7); ...
                tse.MIT(tse.HalfYearly(6), 2020, 2); ...
                tse.MIT(tse.Weekly(7), 2021, 10); ...
                tse.day('2023-01-15'); ...
                tse.bday('2023-01-16')};
            for i = 1:numel(cases)
                m   = cases{i};
                F   = tse.frequencyof(m);
                idx = tse.fame.to_date(m);
                tc.verifyClass(idx, 'double');
                m2  = tse.fame.from_date(tse.fame.freq_to_fame(F), idx);
                tc.verifyClass(m2, 'tse.MIT');
                tc.verifyTrue(m == m2, sprintf('round-trip failed for %s', char(m)));
            end
        end

        function unit_roundtrip(tc)
            m   = tse.MIT(tse.Unit(), 42);
            idx = tse.fame.to_date(m);
            tc.verifyEqual(idx, 42);                       % case index == value
            tc.verifyTrue(tse.fame.from_date(232, idx) == m);
        end

        function offset_is_consistent_across_years(tc)
            % Same frequency, far-apart dates: identical offset => a clean
            % linear mapping (this is what fame_offset asserts internally).
            a = tse.mm(1990, 1);
            b = tse.mm(2050, 12);
            oa = tse.fame.to_date(a) - double(int64(a.value));
            ob = tse.fame.to_date(b) - double(int64(b.value));
            tc.verifyEqual(oa, ob);
        end

        function range_roundtrip(tc)
            r  = tse.qq(2020, 1):tse.qq(2024, 4);
            fr = tse.fame.to_range(r);
            tc.verifyEqual(fr.freq, 162);                  % Quarterly(3)
            tc.verifyTrue(fr.last > fr.first);
            r2 = tse.fame.from_range(fr);
            tc.verifyClass(r2, 'tse.MITRange');
            tc.verifyTrue(first(r) == first(r2));
            tc.verifyTrue(last(r)  == last(r2));
        end

        function from_date_rejects_bad_freq(tc)
            tc.verifyError(@() tse.fame.from_date('nope', 5), 'tseries:noMatch');
        end

    end
end

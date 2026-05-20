classdef TestRange < matlab.unittest.TestCase
    %TESTRANGE  Mirrors the @testset "Range" block of test_mit.jl.

    methods (Test)
        function basic_range(tc)
            rng = tseries.qq(2020,1) : tseries.qq(2020,4);
            tc.verifyClass(rng, 'tseries.MITRange');
            tc.verifyEqual(length(rng), 4);
            tc.verifyTrue(rng.startMIT == tseries.qq(2020,1));
            tc.verifyTrue(rng.stopMIT  == tseries.qq(2020,4));
        end

        function empty_range_is_empty(tc)
            rng = tseries.qq(2020,1) : tseries.qq(2019,1);
            tc.verifyTrue(isempty(rng));
            tc.verifyEqual(length(rng), 0);
        end

        function step_one(tc)
            rng = tseries.qq(2020,1) : tseries.qq(2020,4);
            % tc.verifyEqual(tseries.step, 1); %TODO: maybe implement
            tc.verifyEqual(rng.step, 1);
            for i = 1:length(rng)
                m = rng(i);
                tc.verifyClass(m, 'tseries.MIT');
                tc.verifyTrue(rng.startMIT <= m);
                tc.verifyTrue(m <= rng.stopMIT);
            end
        end

        function indexing_first_last(tc)
            rng = tseries.qq(2020,1) : tseries.qq(2020,4);
            tc.verifyTrue(rng(1)         == rng.startMIT);
            tc.verifyTrue(rng(end)       == rng.stopMIT);
        end

        function mixed_freq_range_throws(tc)
            tc.verifyError(@() tseries.qq(2020,1) : tseries.mm(2020,12), 'tseries:mixedFreq');
        end

        function rangeof_span_unit(tc)
            U = tseries.Unit();
            r1 = tseries.MITRange(tseries.MIT(U,3), tseries.MIT(U,5));
            r2 = tseries.MITRange(tseries.MIT(U,4), tseries.MIT(U,6));
            r  = tseries.rangeof_span(r1, r2);
            tc.verifyTrue(r.startMIT == tseries.MIT(U,3));
            tc.verifyTrue(r.stopMIT  == tseries.MIT(U,6));
        end

        function rangeof_span_mixed_freq_throws(tc)
            U = tseries.Unit();
            r1 = tseries.MITRange(tseries.MIT(U,3), tseries.MIT(U,5));
            r2 = tseries.qq(4,1) : tseries.qq(6,1);
            tc.verifyError(@() tseries.rangeof_span(r1, r2), 'tseries:mixedFreq');
        end

        function step_range_with_duration(tc)
            sr = tseries.MITRange(tseries.qq(1,1), tseries.qq(1,3) - tseries.qq(1,1), tseries.qq(4,4));
            tc.verifyEqual(length(sr), 8);
            % tc.verifyEqual(tseries.step(sr), 2); % TODO: maybe implement
            tc.verifyEqual(sr.step, 2);
            tc.verifyTrue(sr.startMIT == tseries.qq(1,1));
            tc.verifyTrue(sr(end)     == tseries.qq(4,3));
        end

        function step_range_with_int(tc)
            sr = tseries.MITRange(tseries.qq(1,1), 2, tseries.qq(4,4));
            tc.verifyEqual(length(sr), 8);
            % tc.verifyEqual(tseries.step(sr), 2); % TODO: maybe implement
            tc.verifyEqual(sr.step, 2);
        end

        function step_range_mixed_freq_throws(tc)
            tc.verifyError(@() tseries.MITRange(tseries.qq(1,2), 2, tseries.MIT(tseries.Unit(),5)), ...
                'tseries:mixedFreq');
            tc.verifyError(@() tseries.MITRange(tseries.qq(1,2), tseries.qq(1,1)-tseries.qq(1,2), tseries.MIT(tseries.Unit(),5)), ...
                'tseries:mixedFreq');
        end

        function intersect_ranges(tc)
            r1 = tseries.qq(2020,1) : tseries.qq(2020,4);
            r2 = tseries.qq(2020,3) : tseries.qq(2021,2);
            r  = intersect(r1, r2);
            tc.verifyTrue(r.startMIT == tseries.qq(2020,3));
            tc.verifyTrue(r.stopMIT  == tseries.qq(2020,4));
        end

        function union_ranges(tc)
            r1 = tseries.qq(2020,1) : tseries.qq(2020,4);
            r2 = tseries.qq(2020,3) : tseries.qq(2021,2);
            r  = union(r1, r2);
            tc.verifyTrue(r.startMIT == tseries.qq(2020,1));
            tc.verifyTrue(r.stopMIT  == tseries.qq(2021,2));
        end

        function ismember_membership(tc)
            rng = tseries.qq(2020,1) : tseries.qq(2020,4);
            tc.verifyTrue(ismember(rng, tseries.qq(2020,2)));
            tc.verifyFalse(ismember(rng, tseries.qq(2019,4)));
        end

        function plus_shifts_range(tc)
            rng = tseries.qq(2020,1) : tseries.qq(2020,4);
            r2  = rng + 4;
            tc.verifyTrue(r2.startMIT == tseries.qq(2021,1));
            tc.verifyTrue(r2.stopMIT  == tseries.qq(2021,4));
        end
    end
end

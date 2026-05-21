classdef TestRange < matlab.unittest.TestCase
    %TESTRANGE  Mirrors the @testset "Range" block of test_mit.jl.

    methods (Test)
        function basic_range(tc)
            rng = tse.qq(2020,1) : tse.qq(2020,4);
            tc.verifyClass(rng, 'tse.MITRange');
            tc.verifyEqual(length(rng), 4);
            tc.verifyTrue(rng.startMIT == tse.qq(2020,1));
            tc.verifyTrue(rng.stopMIT  == tse.qq(2020,4));
        end

        function empty_range_is_empty(tc)
            rng = tse.qq(2020,1) : tse.qq(2019,1);
            tc.verifyTrue(isempty(rng));
            tc.verifyEqual(length(rng), 0);
        end

        function step_one(tc)
            rng = tse.qq(2020,1) : tse.qq(2020,4);
            % tc.verifyEqual(tse.step, 1); %TODO: maybe implement
            tc.verifyEqual(rng.step, 1);
            for i = 1:length(rng)
                m = rng(i);
                tc.verifyClass(m, 'tse.MIT');
                tc.verifyTrue(rng.startMIT <= m);
                tc.verifyTrue(m <= rng.stopMIT);
            end
        end

        function indexing_first_last(tc)
            rng = tse.qq(2020,1) : tse.qq(2020,4);
            tc.verifyTrue(rng(1)         == rng.startMIT);
            tc.verifyTrue(rng(end)       == rng.stopMIT);
        end

        function mixed_freq_range_throws(tc)
            tc.verifyError(@() tse.qq(2020,1) : tse.mm(2020,12), 'tseries:mixedFreq');
        end

        function rangeof_span_unit(tc)
            U = tse.Unit();
            r1 = tse.MITRange(tse.MIT(U,3), tse.MIT(U,5));
            r2 = tse.MITRange(tse.MIT(U,4), tse.MIT(U,6));
            r  = tse.rangeof_span(r1, r2);
            tc.verifyTrue(r.startMIT == tse.MIT(U,3));
            tc.verifyTrue(r.stopMIT  == tse.MIT(U,6));
        end

        function rangeof_span_mixed_freq_throws(tc)
            U = tse.Unit();
            r1 = tse.MITRange(tse.MIT(U,3), tse.MIT(U,5));
            r2 = tse.qq(4,1) : tse.qq(6,1);
            tc.verifyError(@() tse.rangeof_span(r1, r2), 'tseries:mixedFreq');
        end

        function step_range_with_duration(tc)
            sr = tse.MITRange(tse.qq(1,1), tse.qq(1,3) - tse.qq(1,1), tse.qq(4,4));
            tc.verifyEqual(length(sr), 8);
            % tc.verifyEqual(tse.step(sr), 2); % TODO: maybe implement
            tc.verifyEqual(sr.step, 2);
            tc.verifyTrue(sr.startMIT == tse.qq(1,1));
            tc.verifyTrue(sr(end)     == tse.qq(4,3));
        end

        function step_range_with_int(tc)
            sr = tse.MITRange(tse.qq(1,1), 2, tse.qq(4,4));
            tc.verifyEqual(length(sr), 8);
            % tc.verifyEqual(tse.step(sr), 2); % TODO: maybe implement
            tc.verifyEqual(sr.step, 2);
        end

        function step_range_mixed_freq_throws(tc)
            tc.verifyError(@() tse.MITRange(tse.qq(1,2), 2, tse.MIT(tse.Unit(),5)), ...
                'tseries:mixedFreq');
            tc.verifyError(@() tse.MITRange(tse.qq(1,2), tse.qq(1,1)-tse.qq(1,2), tse.MIT(tse.Unit(),5)), ...
                'tseries:mixedFreq');
        end

        function intersect_ranges(tc)
            r1 = tse.qq(2020,1) : tse.qq(2020,4);
            r2 = tse.qq(2020,3) : tse.qq(2021,2);
            r  = intersect(r1, r2);
            tc.verifyTrue(r.startMIT == tse.qq(2020,3));
            tc.verifyTrue(r.stopMIT  == tse.qq(2020,4));
        end

        function union_ranges(tc)
            r1 = tse.qq(2020,1) : tse.qq(2020,4);
            r2 = tse.qq(2020,3) : tse.qq(2021,2);
            r  = union(r1, r2);
            tc.verifyTrue(r.startMIT == tse.qq(2020,1));
            tc.verifyTrue(r.stopMIT  == tse.qq(2021,2));
        end

        function ismember_membership(tc)
            rng = tse.qq(2020,1) : tse.qq(2020,4);
            tc.verifyTrue(ismember(rng, tse.qq(2020,2)));
            tc.verifyFalse(ismember(rng, tse.qq(2019,4)));
        end

        function plus_shifts_range(tc)
            rng = tse.qq(2020,1) : tse.qq(2020,4);
            r2  = rng + 4;
            tc.verifyTrue(r2.startMIT == tse.qq(2021,1));
            tc.verifyTrue(r2.stopMIT  == tse.qq(2021,4));
        end
    end
end

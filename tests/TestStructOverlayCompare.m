classdef TestStructOverlayCompare < matlab.unittest.TestCase
    %TESTSTRUCTOVERLAYCOMPARE  Tests for struct (workspace-like) overlay
    %   and compare_ts, ported from Julia test_workspace.jl.

    methods (Test)

        %% --- overlay on structs ---

        function overlay_basic(tc)
            work1.A = tse.TSeries(tse.yy(87), [1; 2; NaN; 4]);
            work2.A = tse.TSeries(tse.yy(87), [NaN; 6; 7; 8]);

            r = tse.overlay(work1, work2);
            tc.verifyTrue(isstruct(r));
            tc.verifyTrue(isfield(r, 'A'));
            expected = tse.TSeries(tse.yy(87), [1; 2; 7; 4]);
            tc.verifyTrue(tse.compare_ts(r.A, expected, 'nans', true));
        end

        function overlay_reverse_priority(tc)
            work1.A = tse.TSeries(tse.yy(87), [1; 2; NaN; 4]);
            work2.A = tse.TSeries(tse.yy(87), [NaN; 6; 7; 8]);

            r = tse.overlay(work2, work1);
            expected = tse.TSeries(tse.yy(87), [1; 6; 7; 8]);
            tc.verifyTrue(tse.compare_ts(r.A, expected, 'nans', true));
        end

        function overlay_three_structs(tc)
            work1.A = tse.TSeries(tse.yy(87), [1; 2; NaN; 4]);
            work2.A = tse.TSeries(tse.yy(87), [NaN; 6; 7; 8]);
            work3.A = tse.TSeries(tse.yy(86), NaN(7, 1));

            r = tse.overlay(work3, work1, work2);
            expected = tse.TSeries(tse.yy(86), [NaN; 1; 2; 7; 4; NaN; NaN]);
            tc.verifyTrue(tse.compare_ts(r.A, expected, 'nans', true));
        end

        function overlay_idempotent(tc)
            work1.A = tse.TSeries(tse.yy(87), [1; 2; NaN; 4]);
            work2.A = tse.TSeries(tse.yy(87), [NaN; 6; 7; 8]);

            C = tse.overlay(work1, work2);
            D = tse.overlay(C, work1);
            tc.verifyEqual(D.A.values, C.A.values);
        end

        function overlay_union_fields(tc)
            work1.A = tse.TSeries(tse.yy(87), [1; 2; 3]);
            work2.B = tse.TSeries(tse.yy(90), [10; 20]);

            r = tse.overlay(work1, work2);
            tc.verifyTrue(isfield(r, 'A'));
            tc.verifyTrue(isfield(r, 'B'));
            tc.verifyEqual(r.A.values, [1; 2; 3]);
            tc.verifyEqual(r.B.values, [10; 20]);
        end

        function overlay_mixed_field_types(tc)
            % Struct with a scalar and a TSeries
            work1.x = 5;
            work1.ts = tse.TSeries(tse.qq(2020, 1), [1; NaN; 3; 4]);
            work2.x = NaN;
            work2.ts = tse.TSeries(tse.qq(2020, 1), [NaN; 20; NaN; NaN]);

            r = tse.overlay(work1, work2);
            tc.verifyEqual(r.x, 5);
            expected_ts = tse.TSeries(tse.qq(2020, 1), [1; 20; 3; 4]);
            tc.verifyTrue(tse.compare_ts(r.ts, expected_ts));
        end

        %% --- compare_ts on structs ---

        function compare_equal_structs(tc)
            work1.A = tse.TSeries(tse.yy(87), ones(4, 1));
            work2.A = tse.TSeries(tse.yy(87), ones(4, 1));
            tc.verifyTrue(tse.compare_ts(work1, work2, 'quiet', true));
        end

        function compare_unequal_structs(tc)
            work1.A = tse.TSeries(tse.yy(87), ones(4, 1));
            work3.A = tse.TSeries(tse.yy(86), zeros(4, 1));
            tc.verifyFalse(tse.compare_ts(work1, work3, 'quiet', true));
        end

        function compare_large_equal_structs(tc)
            work4.A = tse.TSeries(tse.yy(86), zeros(300, 1));
            work5.A = tse.TSeries(tse.yy(86), zeros(300, 1));
            tc.verifyTrue(tse.compare_ts(work4, work5, 'quiet', true));
        end

        function compare_ignoreMissing_fields(tc)
            work1.A = tse.TSeries(tse.yy(87), [1; 2; 3]);
            work1.B = tse.TSeries(tse.yy(90), [10; 20]);
            work2.A = tse.TSeries(tse.yy(87), [1; 2; 3]);
            % work2 is missing field B
            tc.verifyTrue(tse.compare_ts(work1, work2, 'ignoreMissing', true, 'quiet', true));
        end

        function compare_different_fields_fails(tc)
            work1.A = tse.TSeries(tse.yy(87), [1; 2; 3]);
            work1.B = tse.TSeries(tse.yy(90), [10; 20]);
            work2.A = tse.TSeries(tse.yy(87), [1; 2; 3]);
            % Without ignoreMissing, different fields should fail
            tc.verifyFalse(tse.compare_ts(work1, work2, 'quiet', true));
        end

        function compare_with_tolerance(tc)
            work1.A = tse.TSeries(tse.yy(87), [1; 2; 3]);
            work2.A = tse.TSeries(tse.yy(87), [1.001; 2.001; 3.001]);
            tc.verifyFalse(tse.compare_ts(work1, work2, 'atol', 0, 'quiet', true));
            tc.verifyTrue(tse.compare_ts(work1, work2, 'atol', 0.01, 'quiet', true));
        end

        function compare_nested_struct(tc)
            % Struct within struct - compare recursively via isequal fallback
            inner1.val = 42;
            work1.x = tse.TSeries(tse.yy(2000), [1; 2; 3]);
            work1.meta = inner1;
            inner2.val = 42;
            work2.x = tse.TSeries(tse.yy(2000), [1; 2; 3]);
            work2.meta = inner2;
            tc.verifyTrue(tse.compare_ts(work1, work2, 'quiet', true));
        end

        function compare_nans_option(tc)
            work1.A = tse.TSeries(tse.yy(87), [1; NaN; 3]);
            work2.A = tse.TSeries(tse.yy(87), [1; NaN; 3]);
            % Without nans=true, NaN ~= NaN
            tc.verifyFalse(tse.compare_ts(work1, work2, 'quiet', true));
            % With nans=true, NaN == NaN
            tc.verifyTrue(tse.compare_ts(work1, work2, 'nans', true, 'quiet', true));
        end

        function compare_ignoreMissing_range(tc)
            work1.A = tse.TSeries(tse.yy(87), [1; 2; 3; 4]);
            work2.A = tse.TSeries(tse.yy(88), [2; 3; 4; 5]);
            % Different ranges without ignoreMissing -> false
            tc.verifyFalse(tse.compare_ts(work1, work2, 'quiet', true));
            % With ignoreMissing -> compare intersection
            tc.verifyTrue(tse.compare_ts(work1, work2, 'ignoreMissing', true, 'quiet', true));
        end
    end
end

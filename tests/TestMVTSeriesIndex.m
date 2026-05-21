classdef TestMVTSeriesIndex < matlab.unittest.TestCase
    %TESTMVTSERIESINDEX  Mirrors @testset "MV Int Ind", "MV dot", "MV"
    %    of test_mvtseries.jl.

    methods (Test)

        function int_indexing(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, rand(5, 2));
            % Fill via linear index, then read it back
            for i = 1:10
                a(i) = i;
            end
            tc.verifyEqual(a(1:10), (1:10)); %TODO: should this be transposed?
        end

        function colon_returns_self(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, rand(5, 2));
            r = a(:,:);
            tc.verifyEqual(r, a);
        end

        function row_by_int(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, [1 6; 2 7; 3 8; 4 9; 5 10]);
            tc.verifyEqual(a(1, :), [1 6]);
        end

        function dot_returns_tseries(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, rand(10, 2));
            tc.verifyClass(a.a, 'tse.TSeries');
            tc.verifyEqual(a.a.values, a.values(:,1));
        end

        function dot_assign_tseries(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, rand(10, 2));
            a.a = tse.TSeries(tse.qq(2020,1), (1:10)');
            tc.verifyEqual(a.values(:,1), (1:10)');
        end

        function dot_assign_scalar(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, rand(10, 2));
            a.a = 1;
            tc.verifyEqual(a.values(:,1), ones(10,1));
        end

        function unknown_column_throws_on_dot(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, rand(10, 2));
            tc.verifyError(@() a.c, 'tseries:bounds');
        end

        function mit_indexing_returns_row(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, rand(10, 2));
            row = a(tse.qq(2020,1));
            tc.verifyEqual(row, a.values(1,:)');
        end

        function range_indexing_returns_mvts(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, rand(10, 2));
            sub = a(tse.qq(2020,2):tse.qq(2020,4));
            tc.verifyClass(sub, 'tse.MVTSeries');
            tc.verifyEqual(size(sub), [3 2]);
            tc.verifyTrue(sub.firstdate == tse.qq(2020,2));
        end

        function pair_indexing_scalar(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, [1 6; 2 7; 3 8; 4 9; 5 10]);
            tc.verifyEqual(a(tse.qq(2020,2), 'a'), 2);
        end

        function pair_indexing_tseries(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, [1 6; 2 7; 3 8; 4 9; 5 10]);
            sub = a(tse.qq(2020,1):tse.qq(2020,3), 'a');
            tc.verifyClass(sub, 'tse.TSeries');
            tc.verifyEqual(sub.values, [1;2;3]);
        end

        function pair_indexing_multi(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b','c'}, ones(5,3) .* [1 2 3]);
            sub = a(tse.qq(2020,2):tse.qq(2020,4), {'a','c'});
            tc.verifyClass(sub, 'tse.MVTSeries');
            tc.verifyEqual(sub.values, [1 3; 1 3; 1 3]);
        end

        function out_of_range_mit_throws(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, rand(5, 2));
            tc.verifyError(@() a(tse.qq(2019,4)), 'tseries:bounds');
        end

        function wrong_freq_throws(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, rand(5, 2));
            tc.verifyError(@() a(tse.yy(2020)), 'tseries:mixedFreq');
        end

        function composite_dot_assign(tc)
            a = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a','b'}, [1 6; 2 7; 3 8; 4 9]);
            a.a(tse.qq(2020,2)) = 99;
            tc.verifyEqual(a.values(2,1), 99);
            % Other cells untouched
            tc.verifyEqual(a.values(2,2), 7);
            tc.verifyEqual(a.values(1,1), 1);
        end

        function range_assign(tc)
            a = tse.MVTSeries(tse.qq(2020,1), {'a','b'}, zeros(5,2));
            a(tse.qq(2020,1):tse.qq(2020,2)) = [1 2; 3 4];
            tc.verifyEqual(a.values(1:2,:), [1 2; 3 4]);
        end
    end
end

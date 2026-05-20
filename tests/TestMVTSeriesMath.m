classdef TestMVTSeriesMath < matlab.unittest.TestCase
    %TESTMVTSERIESMATH  Mirrors @testset "MVTSeries math" of test_mvtseries.jl.

    methods (Test)

        function plus_two_mvts(tc)
            x = tseries.MVTSeries(tseries.MIT(tseries.Unit(),1), {'a','b'}, [1 4; 2 5; 3 6]);
            y = tseries.MVTSeries(tseries.MIT(tseries.Unit(),1), {'a','b'}, [7 10; 8 11; 9 12]);
            r = x + y;
            tc.verifyClass(r, 'tseries.MVTSeries');
            tc.verifyEqual(r.values(:,1), [8;10;12]);
            tc.verifyEqual(r.values(:,2), [14;16;18]);
        end

        function plus_with_offset_range(tc)
            U = tseries.Unit();
            x = tseries.MVTSeries(tseries.MIT(U,1):tseries.MIT(U,3), {'a','b'}, [1 4; 2 5; 3 6]);
            y = tseries.MVTSeries(tseries.MIT(U,2):tseries.MIT(U,4), {'a','b'}, [7 10; 8 11; 9 12]);
            r = x + y;
            tc.verifyTrue(tseries.rangeof(r).startMIT == tseries.MIT(U,2));
            tc.verifyTrue(tseries.rangeof(r).stopMIT  == tseries.MIT(U,3));
            tc.verifyEqual(r.values(:,1), [9;11]);
        end

        function minus(tc)
            U = tseries.Unit();
            x = tseries.MVTSeries(tseries.MIT(U,1):tseries.MIT(U,3), {'a','b'}, [1 4; 2 5; 3 6]);
            y = tseries.MVTSeries(tseries.MIT(U,1):tseries.MIT(U,3), {'a','b'}, [7 10; 8 11; 9 12]);
            r = y - x;
            tc.verifyEqual(r.values(:,1), [6;6;6]);
        end

        function scalar_times(tc)
            x = tseries.MVTSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),3), {'a','b'}, [1 4; 2 5; 3 6]);
            r = 2 * x;
            tc.verifyEqual(r.values, 2 * x.values);
            r2 = x * 2;
            tc.verifyEqual(r2.values, 2 * x.values);
        end

        function scalar_div(tc)
            x = tseries.MVTSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),3), {'a','b'}, [2 4; 6 8; 10 12]);
            r = x / 2;
            tc.verifyEqual(r.values, [1 2; 3 4; 5 6]);
        end

        function plus_with_tseries(tc)
            x = tseries.MVTSeries(tseries.qq(2020,1), {'a','b'}, [1 11; 2 12; 3 13; 4 14]);
            t = tseries.TSeries(tseries.qq(2020,1), ones(4,1));
            r = x + t;
            tc.verifyEqual(r.values, x.values + 1);
        end

        function sum_no_dims(tc)
            x = tseries.MVTSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),3), {'a','b'}, [1 4; 2 5; 3 6]);
            tc.verifyEqual(sum(x), 21);
        end

        function sum_dim1(tc)
            x = tseries.MVTSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),3), {'a','b'}, [1 4; 2 5; 3 6]);
            tc.verifyEqual(size(sum(x, 'dims', 1)), [1 2]);
            tc.verifyEqual(sum(x, 'dims', 1), [6 15]);
        end

        function sum_dim2_returns_tseries(tc)
            x = tseries.MVTSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),3), {'a','b'}, [1 4; 2 5; 3 6]);
            r = sum(x, 'dims', 2);
            tc.verifyClass(r, 'tseries.TSeries');
            tc.verifyTrue(isequal(tseries.rangeof(r), tseries.rangeof(x)));
            tc.verifyEqual(r.values, [5;7;9]);
        end

        function shift_lead_lag(tc)
            U = tseries.Unit();
            x = tseries.MVTSeries(tseries.MIT(U,1):tseries.MIT(U,3), {'a','b'}, [1 4; 2 5; 3 6]);
            sx = shift(x, 1);
            tc.verifyTrue(tseries.rangeof(sx).startMIT == tseries.MIT(U,0));
            tc.verifyEqual(sx.values, x.values);
            tc.verifyTrue(isequal(lead(x), shift(x, 1)));
            tc.verifyTrue(isequal(lag(x), shift(x, -1)));
        end

        function diff_keeps_columns(tc)
            x = tseries.MVTSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),3), {'a','b'}, [1 4; 2 5; 3 6]);
            d = diff_ts(x);
            tc.verifyClass(d, 'tseries.MVTSeries');
            tc.verifyEqual(d.values, ones(2,2));
        end

        function cumsum_default(tc)
            x = tseries.MVTSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),3), {'a','b'}, [1 4; 2 5; 3 6]);
            c = cumsum(x, 1);
            tc.verifyEqual(c.values(:,1), [1;3;6]);
            tc.verifyEqual(c.values(:,2), [4;9;15]);
        end

        function pct_mvts(tc)
            x = tseries.MVTSeries(tseries.qq(2020,1), {'a','b'}, [1 10; 2 20; 4 40; 8 80]);
            r = pct(x);
            tc.verifyEqual(r.values, [100 100; 100 100; 100 100]);
        end

        function moving(tc)
            x = tseries.MVTSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),10), {'a','b'}, ...
                [(1:10)', (11:20)']);
            r = moving(x, 4);
            tc.verifyTrue(tseries.rangeof(r).startMIT == tseries.MIT(tseries.Unit(),4));
            tc.verifyEqual(r.values(:,1), (4:10)' - 1.5);
            tc.verifyEqual(r.values(:,2), (14:20)' - 1.5);
        end
    end
end

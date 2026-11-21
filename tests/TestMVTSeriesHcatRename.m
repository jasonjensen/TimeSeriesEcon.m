classdef TestMVTSeriesHcatRename < matlab.unittest.TestCase
    %TESTMVTSERIESHCATRENAME  hcat / vcat / rename_columns tests.

    methods (Test)

        function hcat_single(tc)
            xx = tse.MVTSeries(tse.MIT(tse.Unit(),1), {'a','b'}, rand(15, 2));
            r = horzcat(xx);
            tc.verifyClass(r, 'tse.MVTSeries');
            tc.verifyEqual(r.values, xx.values);
        end

        function hcat_two(tc)
            U = tse.Unit();
            xx = tse.MVTSeries(tse.MIT(U,1):tse.MIT(U,15), {'a','b'}, rand(15, 2));
            yy = tse.MVTSeries(tse.MIT(U,3):tse.MIT(U,10), {'c'},     rand(8, 1));
            r = [xx, yy];
            tc.verifyClass(r, 'tse.MVTSeries');
            tc.verifyEqual(r.colnames, ["a","b","c"]);
            tc.verifyEqual(size(r,1), 15);
            % aligned to union range = [1, 15]; xx values preserved at rows 1..15
            tc.verifyEqual(r.values(1:15, 1:2), xx.values);
        end

        function vcat_appends_rows(tc)
            x = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a','b'}, [1 5; 2 6; 3 7; 4 8]);
            y = tse.MVTSeries(tse.qq(2021,1):tse.qq(2021,2), {'a','b'}, [9 13; 10 14]);
            r = [x; y];
            tc.verifyClass(r, 'tse.MVTSeries');
            tc.verifyEqual(size(r,1), 6);
            tc.verifyEqual(r.values(5:6,:), y.values);
        end

        function rename_with_vector(tc)
            x = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a','b','c'}, rand(4,3));
            x = rename_columns(x, {'X','Y','Z'});
            tc.verifyEqual(x.colnames, ["X","Y","Z"]);
        end

        function rename_with_struct(tc)
            x = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a','b'}, rand(4,2));
            x = rename_columns(x, struct('a', 'foo'));
            tc.verifyEqual(x.colnames, ["foo","b"]);
        end

        function rename_with_prefix_suffix(tc)
            x = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a','b'}, rand(4,2));
            x = rename_columns(x, 'prefix', 'X_', 'suffix', '_Y');
            tc.verifyEqual(x.colnames, ["X_a_Y","X_b_Y"]);
        end
        function hcat_name_value_tseries(tc)
            x  = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a','b'}, [1 5; 2 6; 3 7; 4 8]);
            ts = tse.TSeries(tse.qq(2020,3), [10; 20; 30]);    % runs past x
            r = hcat(x, 'c', ts);
            tc.verifyClass(r, 'tse.MVTSeries');
            tc.verifyEqual(r.colnames, ["a","b","c"]);
            tc.verifyTrue(tse.rangeof(r).stopMIT == tse.qq(2021,1));
            tc.verifyEqual(r.c.values, [NaN; NaN; 10; 20; 30]);
            tc.verifyEqual(r.a.values, [1; 2; 3; 4; NaN]);
        end

        function hcat_scalar_vector_and_mvts(tc)
            x = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a'}, (1:4)');
            y = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'d'}, (5:8)');
            r = hcat(x, "b", 0, 'c', [9 8 7 6], y);
            tc.verifyEqual(r.colnames, ["a","b","c","d"]);
            tc.verifyEqual(r.values, [(1:4)', zeros(4,1), (9:-1:6)', (5:8)']);
        end

        function hcat_errors(tc)
            x  = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a'}, (1:4)');
            tc.verifyError(@() hcat(x, 'a', 1), 'tseries:noMatch');           % duplicate
            tc.verifyError(@() hcat(x, 'b'), 'tseries:noMatch');              % no value
            tc.verifyError(@() hcat(x, 'b', [1 2]), 'tseries:dimMismatch');
            tc.verifyError(@() hcat(x, 'b', tse.TSeries(tse.mm(2020,1), (1:3)')), ...
                'tseries:mixedFreq');
        end

        function dot_assign_new_column_points_to_hcat(tc)
            x = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a'}, (1:4)');
            try
                x.b = 1;
                tc.verifyFail('expected an error');
            catch ME
                tc.verifyEqual(ME.identifier, 'tseries:bounds');
                tc.verifySubstring(ME.message, 'hcat(x, ''b'', val)');
            end
        end

        function shadowed_column_warns(tc)
            x = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'values','b'}, [1 5; 2 6; 3 7; 4 8]);
            v = tc.verifyWarning(@() x.values, 'tseries:shadowedColumn');
            tc.verifyEqual(v, [1 5; 2 6; 3 7; 4 8]);       % still the field
            col = x('values');
            tc.verifyEqual(col.values, (1:4)');
            y = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a','b'}, [1 5; 2 6; 3 7; 4 8]);
            tc.verifyWarningFree(@() y.values);
        end
    end
end

classdef TestNDTSeriesIndex < matlab.unittest.TestCase
    %TESTNDTSERIESINDEX  tse.NDTSeries step 2: indexing, assignment,
    %   end, resize, find/isassigned, and the 'slicing_keeps_type' option
    %   (for NDTSeries and MVTSeries).

    methods (TestMethodSetup)
        function resetOption(tc)
            tse.setoption('slicing_keeps_type', false);
            tc.addTeardown(@() tse.setoption('slicing_keeps_type', false));
        end
    end

    methods (Static)
        function x = sample()
            % 4 quarters x names a,b x 3 plain: value = 100*k + 10*j + i
            rng = tse.qq(2020,1):tse.qq(2020,4);
            v = zeros(4, 2, 3);
            for i = 1:4, for j = 1:2, for k = 1:3
                v(i, j, k) = 100*k + 10*j + i;
            end, end, end
            x = tse.NDTSeries({rng, ["a" "b"], 3}, v);
        end

        function m = mv()
            m = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a','b','c'}, ...
                reshape(1:12, 4, 3));
        end
    end

    methods (Test)

        % ---------- reading ----------

        function scalar_element(tc)
            x = TestNDTSeriesIndex.sample();
            tc.verifyEqual(x(tse.qq(2020,2), "a", 3), 312);
            tc.verifyEqual(x(tse.qq(2020,4), 'b', 1), 124);
            tc.verifyEqual(x(tse.qq(2020,1), 2, 2), 221);   % names axis by position
        end

        function slice_to_tseries(tc)
            x = TestNDTSeriesIndex.sample();
            t = x(:, "a", 2);
            tc.verifyClass(t, 'tse.TSeries');
            tc.verifyTrue(eq(t.firstdate, tse.qq(2020,1)));
            tc.verifyEqual(t.values, [211; 212; 213; 214]);
            t2 = x(tse.qq(2020,2):tse.qq(2020,3), "b", 1);
            tc.verifyClass(t2, 'tse.TSeries');
            tc.verifyTrue(eq(t2.firstdate, tse.qq(2020,2)));
            tc.verifyEqual(t2.values, [122; 123]);
        end

        function slice_to_mvtseries(tc)
            x = TestNDTSeriesIndex.sample();
            m = x(:, :, 3);
            tc.verifyClass(m, 'tse.MVTSeries');
            tc.verifyEqual(m.colnames, ["a" "b"]);
            tc.verifyEqual(m.values, x.values(:, :, 3));
            m1 = x(:, {'b'}, 1);      % a cell keeps the names axis
            tc.verifyClass(m1, 'tse.MVTSeries');
            tc.verifyEqual(m1.colnames, "b");
        end

        function slice_stays_ndtseries(tc)
            x = TestNDTSeriesIndex.sample();
            y = x(tse.qq(2020,2):tse.qq(2020,3), :, :);
            tc.verifyClass(y, 'tse.NDTSeries');
            tc.verifyEqual(size(y), [2 2 3]);
            tc.verifyTrue(eq(firstdate(y), tse.qq(2020,2)));
            tc.verifyEqual(y.values, x.values(2:3, :, :));

            z = x(tse.qq(2020,1), :, :);     % names x plain
            tc.verifyClass(z, 'tse.NDTSeries');
            tc.verifyEqual([z.axes.kind], ["names" "plain"]);
            tc.verifyEqual(z.values, squeeze(x.values(1, :, :)));

            w = x(:, "b", [1 3]);            % range x plain
            tc.verifyClass(w, 'tse.NDTSeries');
            tc.verifyEqual(size(w), [4 2]);
            tc.verifyEqual(w.values, squeeze(x.values(:, 2, [1 3])));

            u = x(:, ["b" "a"], logical([1 0 1]));
            tc.verifyEqual(size(u), [4 2 2]);
            tc.verifyEqual(names(u), ["b" "a"]);
            tc.verifyEqual(u.values, x.values(:, [2 1], [1 3]));
        end

        function dot_name_drops_the_names_axis(tc)
            x = TestNDTSeriesIndex.sample();
            a = x.a;
            tc.verifyClass(a, 'tse.NDTSeries');
            tc.verifyEqual(size(a), [4 3]);
            tc.verifyEqual(a.values, squeeze(x.values(:, 1, :)));
            % with a date axis and a names axis only, x.name is a TSeries
            m = tse.NDTSeries(TestNDTSeriesIndex.mv());
            tc.verifyClass(m.c, 'tse.TSeries');
            tc.verifyEqual(m.c.values, (9:12)');
            % methods and properties still work through dot syntax
            tc.verifyEqual(x.naxes(), 3);
            tc.verifyEqual(size(x.values), [4 2 3]);
            tc.verifyEqual(x.axes(2).names, ["a" "b"]);
            tc.verifyEqual([x.axes.kind], ["range" "names" "plain"]);
        end

        function end_keyword(tc)
            x = TestNDTSeriesIndex.sample();
            tc.verifyEqual(x(end, "a", end), 314);
            t = x(end-1:end, "b", 1);
            tc.verifyEqual(t.values, [123; 124]);
            tc.verifyEqual(x.values(end), 324);
        end

        function read_errors(tc)
            x = TestNDTSeriesIndex.sample();
            tc.verifyError(@() x(tse.qq(2020,1), "a"), 'tseries:bounds');
            tc.verifyError(@() x(tse.qq(2021,1), "a", 1), 'tseries:bounds');
            tc.verifyError(@() x(:, "zz", 1), 'tseries:bounds');
            tc.verifyError(@() x(1, "a", 1), 'tseries:bounds');           % number on a date axis
            tc.verifyError(@() x(:, "a", 4), 'tseries:bounds');
            tc.verifyError(@() x(:, "a", "x"), 'tseries:bounds');         % name on a plain axis
            tc.verifyError(@() x(tse.MITRange(tse.qq(2020,1), 2, tse.qq(2020,3)), "a", 1), ...
                'tseries:bounds');                                         % strided
            tc.verifyError(@() x(tse.mm(2020,1), "a", 1), 'tseries:mixedFreq');
            tc.verifyError(@() x.nosuchthing, 'tseries:bounds');
            dup = tse.NDTSeries({["a" "b"], ["a" "c"]});
            tc.verifyError(@() dup.a, 'tseries:bounds');
        end

        % ---------- assignment ----------

        function assign_scalar_and_slices(tc)
            x = TestNDTSeriesIndex.sample();
            x(tse.qq(2020,2), "a", 3) = -1;
            tc.verifyEqual(x.values(2, 1, 3), -1);
            x(:, "b", 2) = 0;
            tc.verifyEqual(x.values(:, 2, 2), zeros(4, 1));
            x(:, :, 1) = [1 2; 3 4; 5 6; 7 8];
            tc.verifyEqual(x.values(:, :, 1), [1 2; 3 4; 5 6; 7 8]);
            x(tse.qq(2020,1), :, :) = 1:6;   % any shape with the right count
            tc.verifyEqual(squeeze(x.values(1, :, :)), reshape(1:6, 2, 3));
            tc.verifyError(@() subsasgn(x, substruct('()', {':', "a", 1}), [1 2 3]), ...
                'tseries:dimMismatch');
        end

        function assign_tseries_aligns_dates(tc)
            x = TestNDTSeriesIndex.sample();
            t = tse.TSeries(tse.qq(2019,1), (1:12)');      % 2019Q1..2021Q4
            x(tse.qq(2020,2):tse.qq(2020,3), "a", 1) = t;
            tc.verifyEqual(x.values(2:3, 1, 1), [6; 7]);
            tc.verifyEqual(x.values(1, 1, 1), 111);
        end

        function assign_grows_date_axis(tc)
            x = TestNDTSeriesIndex.sample();
            x(tse.qq(2021,2), "a", 1) = 5;
            tc.verifyTrue(isequal(rangeof(x), tse.qq(2020,1):tse.qq(2021,2)));
            tc.verifyEqual(size(x), [6 2 3]);
            tc.verifyEqual(x.values(6, 1, 1), 5);
            tc.verifyTrue(isnan(x.values(5, 1, 1)));
            tc.verifyTrue(all(isnan(x.values(5:6, 2, 3))));
            x(tse.qq(2019,3):tse.qq(2019,4), "b", 2) = [1 2];
            tc.verifyTrue(eq(firstdate(x), tse.qq(2019,3)));
            tc.verifyEqual(x.values(1:2, 2, 2), [1; 2]);
            tc.verifyEqual(x.values(3, 1, 3), 311);   % old 2020Q1 moved down two rows
        end

        function assign_by_dot_name(tc)
            x = TestNDTSeriesIndex.sample();
            x.b = 0;
            tc.verifyEqual(x.values(:, 2, :), zeros(4, 1, 3));
            x.a(tse.qq(2020,3), 2) = 99;     % composite: read x.a, change, write back
            tc.verifyEqual(x.values(3, 1, 2), 99);
            tc.verifyError(@() subsasgn(x, substruct('.', 'zz'), 1), 'tseries:bounds');
        end

        function assign_values_and_axes(tc)
            x = TestNDTSeriesIndex.sample();
            x.values(1, 1, 1) = 0;
            tc.verifyEqual(x.values(1, 1, 1), 0);
            x.values = ones(4, 2, 3);
            tc.verifyEqual(x.values, ones(4, 2, 3));
            tc.verifyError(@() subsasgn(x, substruct('.', 'values'), ones(2, 2)), 'tseries:noMatch');
            tc.verifyError(@() subsasgn(x, substruct('.', 'axes'), tse.Axis(2)), 'tseries:noMatch');
        end

        function assign_keeps_integer_type(tc)
            x = tse.NDTSeries('int32', {tse.qq(2020,1):tse.qq(2020,2), 2}, 0);
            x(tse.qq(2020,3), 1) = 7;
            tc.verifyClass(x.values, 'int32');
            tc.verifyEqual(x.values(3, :), int32([7 intmax('int32')]));
        end

        % ---------- other step-2 functions ----------

        function resize_date_axis(tc)
            x = TestNDTSeriesIndex.sample();
            y = resize(x, tse.qq(2020,3):tse.qq(2021,1));
            tc.verifyEqual(size(y), [3 2 3]);
            tc.verifyEqual(y.values(1:2, :, :), x.values(3:4, :, :));
            tc.verifyTrue(all(isnan(y.values(3, :))));
            v = tse.NDTSeries({tse.yy(2019):tse.yy(2020), tse.mm(2020,1):tse.mm(2020,3)}, 1);
            w = resize(v, tse.mm(2020,2):tse.mm(2020,5), 'dims', 2);
            tc.verifyEqual(size(w), [2 4]);
            tc.verifyError(@() resize(v, tse.mm(2020,2):tse.mm(2020,5)), 'tseries:noMatch');
        end

        function find_isassigned_linear(tc)
            x = tse.NDTSeries({tse.qq(2020,1):tse.qq(2020,2), ["a" "b"]}, [0 1; 1 0]);
            tc.verifyEqual(find(x), [2; 3]);
            [r, c] = find(x);
            tc.verifyEqual([r c], [2 1; 1 2]);
            tc.verifyEqual(LinearIndices(x), 1:4);
            tc.verifyTrue(isassigned(x, tse.qq(2020,2), "b"));
            tc.verifyFalse(isassigned(x, tse.qq(2020,3), "b"));
            tc.verifyFalse(isassigned(x, tse.qq(2020,1), "z"));
            tc.verifyFalse(isassigned(x, tse.qq(2020,1)));
        end

        % ---------- the slicing_keeps_type option ----------

        function option_validation(tc)
            tc.verifyFalse(tse.getoption('slicing_keeps_type'));
            tc.verifyError(@() tse.setoption('slicing_keeps_type', 'yes'), 'tseries:noMatch');
            tse.setoption('slicing_keeps_type', 1);
            tc.verifyTrue(tse.getoption('slicing_keeps_type'));
        end

        function keep_type_ndtseries(tc)
            x = TestNDTSeriesIndex.sample();
            tse.setoption('slicing_keeps_type', true);
            t = x(:, "a", 2);
            tc.verifyClass(t, 'tse.NDTSeries');
            tc.verifyEqual(size(t), [4 1 1]);
            tc.verifyEqual(t.axes(2).names, "a");
            tc.verifyEqual(t.values(:), [211; 212; 213; 214]);
            m = x(:, :, 3);
            tc.verifyClass(m, 'tse.NDTSeries');
            tc.verifyEqual(size(m), [4 2 1]);
            r = x(tse.qq(2020,2), :, :);
            tc.verifyEqual(size(r), [1 2 3]);
            tc.verifyTrue(eq(firstdate(r), tse.qq(2020,2)));
            % a single element and dot access behave as usual
            tc.verifyEqual(x(tse.qq(2020,2), "a", 3), 312);
            tc.verifyClass(x.a, 'tse.NDTSeries');
            tc.verifyEqual(size(x.a), [4 3]);
            % explicit conversion still works
            tc.verifyClass(toseries(squeeze(t)), 'tse.TSeries');
        end

        function keep_type_mvtseries(tc)
            m = TestNDTSeriesIndex.mv();
            q2 = tse.qq(2020,2);
            % default: today's behaviour
            tc.verifyClass(m(q2:tse.qq(2020,3), 'a'), 'tse.TSeries');
            tc.verifyClass(m('b'), 'tse.TSeries');
            tc.verifyEqual(m(q2), [2; 6; 10]);
            tse.setoption('slicing_keeps_type', true);
            r = m(q2);
            tc.verifyClass(r, 'tse.MVTSeries');
            tc.verifyEqual(size(r), [1 3]);
            tc.verifyEqual(r.values, [2 6 10]);
            tc.verifyTrue(eq(r.firstdate, q2));
            c = m('b');
            tc.verifyClass(c, 'tse.MVTSeries');
            tc.verifyEqual(c.colnames, "b");
            tc.verifyEqual(c.values, (5:8)');
            s = m(q2:tse.qq(2020,3), 'a');
            tc.verifyClass(s, 'tse.MVTSeries');
            tc.verifyEqual(s.values, [2; 3]);
            tc.verifyTrue(eq(s.firstdate, q2));
            rr = m(q2, {'a', 'c'});
            tc.verifyClass(rr, 'tse.MVTSeries');
            tc.verifyEqual(rr.values, [2 10]);
            whole = m(:, 'c');
            tc.verifyClass(whole, 'tse.MVTSeries');
            % unchanged: single elements, dot access, sub-MVTSeries
            tc.verifyEqual(m(q2, 'b'), 6);
            tc.verifyClass(m.a, 'tse.TSeries');
            tc.verifyClass(m(q2:tse.qq(2020,3)), 'tse.MVTSeries');
        end

        function library_results_do_not_depend_on_option(tc)
            m = TestNDTSeriesIndex.mv();
            off.fc = tse.fconvert(tse.Monthly(), m);
            off.cmp = tse.compare(m, m);
            off.mean = mean(m);
            off.rng = tse.rangeof(m);
            off.lag = lag(m);
            tse.setoption('slicing_keeps_type', true);
            tc.verifyTrue(isequal(tse.fconvert(tse.Monthly(), m), off.fc));
            tc.verifyEqual(tse.compare(m, m), off.cmp);
            tc.verifyEqual(mean(m), off.mean);
            tc.verifyTrue(isequal(tse.rangeof(m), off.rng));
            tc.verifyTrue(isequaln(lag(m), off.lag));
            x = TestNDTSeriesIndex.sample();
            tc.verifyTrue(tse.compare(x, x));
        end
    end
end

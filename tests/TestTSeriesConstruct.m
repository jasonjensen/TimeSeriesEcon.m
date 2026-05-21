classdef TestTSeriesConstruct < matlab.unittest.TestCase
    %TESTTSERIESCONSTRUCT  Mirrors construction tests from
    %    test_tseries.jl "TSeries" and "TSeries 1" testsets.

    methods (Test)
        function from_mit_and_vector(tc)
            s = tse.TSeries(tse.qq(2020,1), (11:22)');
            tc.verifyClass(s, 'tse.TSeries');
            tc.verifyEqual(size(s), [12 1]);
            tc.verifyEqual(length(s), 12);
            tc.verifyEqual(s.values, (11:22)');
            tc.verifyTrue(s.firstdate == tse.qq(2020,1));
        end

        function from_integer_count(tc)
            t = tse.TSeries(5);
            tc.verifyEqual(length(t), 5);
            tc.verifyTrue(t.firstdate == tse.MIT(tse.Unit(),1));
        end

        function from_type_and_count(tc)
            t = tse.TSeries('int32', 5);
            tc.verifyEqual(length(t), 5);
            tc.verifyEqual(class(t.values), 'int32');
            tc.verifyTrue(t.firstdate == tse.MIT(tse.Unit(),1));
        end

        function from_type_and_intRange(tc)
            t = tse.TSeries('uint8', 5:9);
            tc.verifyEqual(class(t.values), 'uint8');
            tc.verifyEqual(length(t), 5);
            tc.verifyTrue(t.firstdate == tse.MIT(tse.Unit(),5));
        end

        function from_type_range_undef(tc)
            t = tse.TSeries('single', tse.MIT(tse.Unit(),1):tse.MIT(tse.Unit(),5), 'undef');
            tc.verifyEqual(class(t.values), 'single');
            tc.verifyEqual(length(t), 5);
        end

        function from_range_defaults_to_nan(tc)
            t = tse.TSeries(tse.qq(1991,1) : tse.qq(1992,4));
            tc.verifyEqual(length(t), 8);
            tc.verifyTrue(all(isnan(t.values)));
        end

        function from_range_scalar_fill(tc)
            t = tse.TSeries(tse.mm(1006,3) : tse.mm(1009,5), 0.3);
            tc.verifyEqual(length(t), 10 + 12 + 12 + 5);
            tc.verifyTrue(all(t.values == 0.3));
        end

        function from_range_mismatched_vector_throws(tc)
            tc.verifyError(@() tse.TSeries(tse.MIT(tse.Unit(),1):tse.MIT(tse.Unit(),5), 1:6), ...
                'tseries:noMatch');
        end

        function from_range_empty(tc)
            % Range start > stop -> empty TSeries
            t = tse.TSeries(tse.yy(2000):tse.yy(1995), 7);
            tc.verifyTrue(isempty(t));
        end

        function firstdate_lastdate_length(tc)
            t = tse.TSeries(tse.MIT(tse.Unit(),2), rand(5,1));
            tc.verifyTrue(t.firstdate == tse.MIT(tse.Unit(),2));
            tc.verifyTrue(tse.lastdate(t) == tse.MIT(tse.Unit(),6));
            tc.verifyEqual(length(t), 5);
        end

        function rangeof_returns_unitrange(tc)
            t = tse.TSeries(tse.qq(2020,1), 1:12);
            rng = tse.rangeof(t);
            tc.verifyClass(rng, 'tse.MITRange');
            tc.verifyTrue(rng.startMIT == tse.qq(2020,1));
            tc.verifyTrue(rng.stopMIT  == tse.qq(2022,4));
        end

        function rangeof_with_drop(tc)
            t = tse.TSeries(tse.qq(2020,1):tse.qq(2021,4), 1);
            tc.verifyTrue(isequal(tse.rangeof(t, 'drop', 2), tse.qq(2020,3):tse.qq(2021,4)));
            tc.verifyTrue(isequal(tse.rangeof(t, 'drop', -2), tse.qq(2020,1):tse.qq(2021,2)));
        end

        function fill_with_function_initializer(tc)
            t = tse.TSeries(tse.qq(2020,1):tse.qq(2021,4), @ones);
            tc.verifyTrue(all(t.values == 1));
            tc.verifyEqual(length(t), 8);
        end

        function frequencyof_returns_class(tc)
            t = tse.TSeries(tse.yy(2000), rand(5,1));
            tc.verifyTrue(isa(tse.frequencyof(t), 'tse.Yearly'));
        end
    end
end

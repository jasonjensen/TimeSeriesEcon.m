classdef TestTSeriesConstruct < matlab.unittest.TestCase
    %TESTTSERIESCONSTRUCT  Mirrors construction tests from
    %    test_tseries.jl "TSeries" and "TSeries 1" testsets.

    methods (Test)
        function from_mit_and_vector(tc)
            s = tseries.TSeries(tseries.qq(2020,1), (11:22)');
            tc.verifyClass(s, 'tseries.TSeries');
            tc.verifyEqual(size(s), [12 1]);
            tc.verifyEqual(length(s), 12);
            tc.verifyEqual(s.values, (11:22)');
            tc.verifyTrue(s.firstdate == tseries.qq(2020,1));
        end

        function from_integer_count(tc)
            t = tseries.TSeries(5);
            tc.verifyEqual(length(t), 5);
            tc.verifyTrue(t.firstdate == tseries.MIT(tseries.Unit(),1));
        end

        function from_type_and_count(tc)
            t = tseries.TSeries('int32', 5);
            tc.verifyEqual(length(t), 5);
            tc.verifyEqual(class(t.values), 'int32');
            tc.verifyTrue(t.firstdate == tseries.MIT(tseries.Unit(),1));
        end

        function from_type_and_intRange(tc)
            t = tseries.TSeries('uint8', 5:9);
            tc.verifyEqual(class(t.values), 'uint8');
            tc.verifyEqual(length(t), 5);
            tc.verifyTrue(t.firstdate == tseries.MIT(tseries.Unit(),5));
        end

        function from_type_range_undef(tc)
            t = tseries.TSeries('single', tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),5), 'undef');
            tc.verifyEqual(class(t.values), 'single');
            tc.verifyEqual(length(t), 5);
        end

        function from_range_defaults_to_nan(tc)
            t = tseries.TSeries(tseries.qq(1991,1) : tseries.qq(1992,4));
            tc.verifyEqual(length(t), 8);
            tc.verifyTrue(all(isnan(t.values)));
        end

        function from_range_scalar_fill(tc)
            t = tseries.TSeries(tseries.mm(1006,3) : tseries.mm(1009,5), 0.3);
            tc.verifyEqual(length(t), 10 + 12 + 12 + 5);
            tc.verifyTrue(all(t.values == 0.3));
        end

        function from_range_mismatched_vector_throws(tc)
            tc.verifyError(@() tseries.TSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),5), 1:6), ...
                'tseries:noMatch');
        end

        function from_range_empty(tc)
            % Range start > stop -> empty TSeries
            t = tseries.TSeries(tseries.yy(2000):tseries.yy(1995), 7);
            tc.verifyTrue(isempty(t));
        end

        function firstdate_lastdate_length(tc)
            t = tseries.TSeries(tseries.MIT(tseries.Unit(),2), rand(5,1));
            tc.verifyTrue(t.firstdate == tseries.MIT(tseries.Unit(),2));
            tc.verifyTrue(tseries.lastdate(t) == tseries.MIT(tseries.Unit(),6));
            tc.verifyEqual(length(t), 5);
        end

        function rangeof_returns_unitrange(tc)
            t = tseries.TSeries(tseries.qq(2020,1), 1:12);
            rng = tseries.rangeof(t);
            tc.verifyClass(rng, 'tseries.MITRange');
            tc.verifyTrue(rng.startMIT == tseries.qq(2020,1));
            tc.verifyTrue(rng.stopMIT  == tseries.qq(2022,4));
        end

        function rangeof_with_drop(tc)
            t = tseries.TSeries(tseries.qq(2020,1):tseries.qq(2021,4), 1);
            tc.verifyTrue(isequal(tseries.rangeof(t, 'drop', 2), tseries.qq(2020,3):tseries.qq(2021,4)));
            tc.verifyTrue(isequal(tseries.rangeof(t, 'drop', -2), tseries.qq(2020,1):tseries.qq(2021,2)));
        end

        function fill_with_function_initializer(tc)
            t = tseries.TSeries(tseries.qq(2020,1):tseries.qq(2021,4), @ones);
            tc.verifyTrue(all(t.values == 1));
            tc.verifyEqual(length(t), 8);
        end

        function frequencyof_returns_class(tc)
            t = tseries.TSeries(tseries.yy(2000), rand(5,1));
            tc.verifyTrue(isa(tseries.frequencyof(t), 'tseries.Yearly'));
        end
    end
end

classdef TestMVTSeriesConstruct < matlab.unittest.TestCase
    %TESTMVTSERIESCONSTRUCT  Mirrors @testset "MV construct" of
    %    test_mvtseries.jl.

    methods (Test)

        function empty(tc)
            x = tseries.MVTSeries(tseries.qq(2020,1));
            tc.verifyEqual(size(x), [0 0]);
        end

        function empty_with_one_name(tc)
            x = tseries.MVTSeries(tseries.qq(2020,1), 'a');
            tc.verifyEqual(size(x), [0 1]);
        end

        function empty_with_two_names(tc)
            x = tseries.MVTSeries(tseries.qq(2020,1), {'a','b'});
            tc.verifyEqual(size(x), [0 2]);
        end

        function from_range_and_names(tc)
            rng = tseries.qq(2020,1):tseries.qq(2020,4);
            x = tseries.MVTSeries(rng, {'a','b'});
            tc.verifyEqual(size(x), [4 2]);
            tc.verifyTrue(all(isnan(x.values(:))));
        end

        function from_range_names_and_scalar(tc)
            rng = tseries.qq(2020,1):tseries.qq(2020,4);
            x = tseries.MVTSeries(rng, {'a','b'}, 5);
            tc.verifyEqual(x.values, 5 * ones(4, 2));
        end

        function from_range_names_zeros(tc)
            rng = tseries.qq(2020,1):tseries.qq(2020,4);
            x = tseries.MVTSeries(rng, {'a','b'}, @zeros);
            tc.verifyEqual(x.values, zeros(4, 2));
        end

        function from_typed(tc)
            x = tseries.MVTSeries('int32', tseries.yy(2020):tseries.yy(2022), {'a','b'});
            tc.verifyEqual(class(x.values), 'int32');
            tc.verifyEqual(size(x), [3 2]);
        end

        function dim_mismatch_throws(tc)
            tc.verifyError(@() tseries.MVTSeries(tseries.MIT(tseries.Unit(),1), {'a','b'}, zeros(10,3)), ...
                'tseries:noMatch');
        end

        function range_data_mismatch_throws(tc)
            tc.verifyError(@() tseries.MVTSeries(tseries.MIT(tseries.Unit(),1):tseries.MIT(tseries.Unit(),5), {'a','b'}, zeros(4,2)), ...
                'tseries:dimMismatch');
        end

        function colnames_property(tc)
            x = tseries.MVTSeries(tseries.qq(2020,1):tseries.qq(2020,4), {'a','b','c'});
            tc.verifyEqual(x.colnames, ["a","b","c"]);
        end

        function firstdate_lastdate_range(tc)
            x = tseries.MVTSeries(tseries.qq(2020,1):tseries.qq(2020,4), {'a','b'});
            tc.verifyTrue(x.firstdate == tseries.qq(2020,1));
            tc.verifyTrue(tseries.lastdate(x) == tseries.qq(2020,4));
            tc.verifyTrue(isequal(tseries.rangeof(x), tseries.qq(2020,1):tseries.qq(2020,4)));
        end

        function frequencyof_returns_class(tc)
            x = tseries.MVTSeries(tseries.qq(2020,1):tseries.qq(2020,4), {'a','b'});
            tc.verifyTrue(isa(tseries.frequencyof(x), 'tseries.Quarterly'));
        end

        function from_tseries_pairs(tc)
            rng = tseries.qq(2020,1):tseries.qq(2021,1);
            pairs = struct( ...
                'hex', tseries.TSeries(tseries.qq(2019,1), (1:20)'), ...
                'why', tseries.TSeries(tseries.qq(2020,1), zeros(5,1)));
            x = tseries.MVTSeries(rng, pairs);
            tc.verifyClass(x, 'tseries.MVTSeries');
            tc.verifyTrue(isequal(tseries.rangeof(x), rng));
            % Aligned: 2020Q1..2021Q1 of hex are positions 5..9 of (1..20)
            tc.verifyEqual(x.values(:,1), (5:9)');
            tc.verifyEqual(x.values(:,2), zeros(5,1));
        end
    end
end

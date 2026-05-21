classdef TestMVTSeriesConstruct < matlab.unittest.TestCase
    %TESTMVTSERIESCONSTRUCT  Mirrors @testset "MV construct" of
    %    test_mvtseries.jl.

    methods (Test)

        function empty(tc)
            x = tse.MVTSeries(tse.qq(2020,1));
            tc.verifyEqual(size(x), [0 0]);
        end

        function empty_with_one_name(tc)
            x = tse.MVTSeries(tse.qq(2020,1), 'a');
            tc.verifyEqual(size(x), [0 1]);
        end

        function empty_with_two_names(tc)
            x = tse.MVTSeries(tse.qq(2020,1), {'a','b'});
            tc.verifyEqual(size(x), [0 2]);
        end

        function from_range_and_names(tc)
            rng = tse.qq(2020,1):tse.qq(2020,4);
            x = tse.MVTSeries(rng, {'a','b'});
            tc.verifyEqual(size(x), [4 2]);
            tc.verifyTrue(all(isnan(x.values(:))));
        end

        function from_range_names_and_scalar(tc)
            rng = tse.qq(2020,1):tse.qq(2020,4);
            x = tse.MVTSeries(rng, {'a','b'}, 5);
            tc.verifyEqual(x.values, 5 * ones(4, 2));
        end

        function from_range_names_zeros(tc)
            rng = tse.qq(2020,1):tse.qq(2020,4);
            x = tse.MVTSeries(rng, {'a','b'}, @zeros);
            tc.verifyEqual(x.values, zeros(4, 2));
        end

        function from_typed(tc)
            x = tse.MVTSeries('int32', tse.yy(2020):tse.yy(2022), {'a','b'});
            tc.verifyEqual(class(x.values), 'int32');
            tc.verifyEqual(size(x), [3 2]);
        end

        function dim_mismatch_throws(tc)
            tc.verifyError(@() tse.MVTSeries(tse.MIT(tse.Unit(),1), {'a','b'}, zeros(10,3)), ...
                'tseries:noMatch');
        end

        function range_data_mismatch_throws(tc)
            tc.verifyError(@() tse.MVTSeries(tse.MIT(tse.Unit(),1):tse.MIT(tse.Unit(),5), {'a','b'}, zeros(4,2)), ...
                'tseries:dimMismatch');
        end

        function colnames_property(tc)
            x = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a','b','c'});
            tc.verifyEqual(x.colnames, ["a","b","c"]);
        end

        function firstdate_lastdate_range(tc)
            x = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a','b'});
            tc.verifyTrue(x.firstdate == tse.qq(2020,1));
            tc.verifyTrue(tse.lastdate(x) == tse.qq(2020,4));
            tc.verifyTrue(isequal(tse.rangeof(x), tse.qq(2020,1):tse.qq(2020,4)));
        end

        function frequencyof_returns_class(tc)
            x = tse.MVTSeries(tse.qq(2020,1):tse.qq(2020,4), {'a','b'});
            tc.verifyTrue(isa(tse.frequencyof(x), 'tse.Quarterly'));
        end

        function from_tseries_pairs(tc)
            rng = tse.qq(2020,1):tse.qq(2021,1);
            pairs = struct( ...
                'hex', tse.TSeries(tse.qq(2019,1), (1:20)'), ...
                'why', tse.TSeries(tse.qq(2020,1), zeros(5,1)));
            x = tse.MVTSeries(rng, pairs);
            tc.verifyClass(x, 'tse.MVTSeries');
            tc.verifyTrue(isequal(tse.rangeof(x), rng));
            % Aligned: 2020Q1..2021Q1 of hex are positions 5..9 of (1..20)
            tc.verifyEqual(x.values(:,1), (5:9)');
            tc.verifyEqual(x.values(:,2), zeros(5,1));
        end
    end
end

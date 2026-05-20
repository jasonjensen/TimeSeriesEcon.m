classdef TestMIT < matlab.unittest.TestCase
    %TESTMIT  Mirrors the @testset "MIT,Duration", "MITops", "mm,qq,yy",
    %         "year,period", "frequencyof", "constructors", "MIT.show"
    %         blocks of TimeSeriesEcon.jl/test/test_mit.jl.

    methods (Test)
        % ---------- mit2yp ----------

        function mit2yp_quarterly_5(tc)
            tc.verifyEqual(double(tseries.mit2yp(tseries.MIT(tseries.Quarterly(), 5))), [1, 2]);
        end

        function mit2yp_quarterly_4(tc)
            tc.verifyEqual(double(tseries.mit2yp(tseries.MIT(tseries.Quarterly(), 4))), [1, 1]);
        end

        function mit2yp_quarterly_3(tc)
            tc.verifyEqual(double(tseries.mit2yp(tseries.MIT(tseries.Quarterly(), 3))), [0, 4]);
        end

        function mit2yp_quarterly_0(tc)
            tc.verifyEqual(double(tseries.mit2yp(tseries.MIT(tseries.Quarterly(), 0))), [0, 1]);
        end

        function mit2yp_quarterly_neg1(tc)
            tc.verifyEqual(double(tseries.mit2yp(tseries.MIT(tseries.Quarterly(), -1))), [-1, 4]);
        end

        function mit2yp_quarterly_neg5(tc)
            tc.verifyEqual(double(tseries.mit2yp(tseries.MIT(tseries.Quarterly(), -5))), [-2, 4]);
        end

        function mit2yp_quarterly_neg6(tc)
            tc.verifyEqual(double(tseries.mit2yp(tseries.MIT(tseries.Quarterly(), -6))), [-2, 3]);
        end

        % ---------- subtractions ----------

        function subtract_mit_mit_yields_duration(tc)
            d = tseries.qq(2020,1) - tseries.qq(2019,2);
            tc.verifyClass(d, 'tseries.Duration');
            tc.verifyEqual(double(d.value), double(3));
        end

        function subtract_mit_int_yields_mit(tc)
            r = tseries.qq(2020,1) - 2;
            tc.verifyClass(r, 'tseries.MIT');
            tc.verifyTrue(isa(r.frequency, 'tseries.Quarterly'));
        end

        function subtract_mit_duration_yields_mit(tc)
            r = tseries.qq(2020,1) - tseries.Duration(tseries.Quarterly(), 2);
            tc.verifyClass(r, 'tseries.MIT');
        end

        function subtract_duration_int_yields_duration(tc)
            r = tseries.Duration(tseries.Quarterly(), 5) - 2;
            tc.verifyClass(r, 'tseries.Duration');
        end

        function subtract_duration_duration_yields_duration(tc)
            r = tseries.Duration(tseries.Quarterly(), 5) - tseries.Duration(tseries.Quarterly(), 2);
            tc.verifyClass(r, 'tseries.Duration');
        end

        function subtract_mixed_frequency_throws(tc)
            tc.verifyError(@() tseries.qq(2020,1) - tseries.mm(2019,2), 'tseries:mixedFreq');
        end

        function subtract_mit_durationOfDifferentFreqThrows(tc)
            tc.verifyError(@() tseries.qq(2020,1) - tseries.Duration(tseries.Monthly(), 5), ...
                'tseries:mixedFreq');
        end

        function subtract_durations_different_freq_throws(tc)
            tc.verifyError(@() tseries.Duration(tseries.Quarterly(),8) - tseries.Duration(tseries.Monthly(),5), ...
                'tseries:mixedFreq');
        end

        % ---------- equality ----------

        function equal_same_mit(tc)
            tc.verifyTrue(tseries.qq(2020,1) == tseries.qq(2020,1));
        end

        function unequal_different_period(tc)
            tc.verifyTrue(tseries.qq(2020,1) ~= tseries.qq(2020,2));
        end

        function unequal_different_frequency(tc)
            tc.verifyTrue(tseries.qq(2020,1) ~= tseries.mm(2020,1));
        end

        function int_equals_mit_value(tc)
            r = tseries.qq(2020,1) - (tseries.qq(2020,1) - 5);
            tc.verifyTrue(5 == r);
            tc.verifyTrue(tseries.Duration(tseries.Quarterly(), 5) == r);
        end

        function duration_ne_mit_same_value(tc)
            tc.verifyTrue(tseries.Duration(tseries.Quarterly(),5) ~= tseries.MIT(tseries.Quarterly(),5));
        end

        function int_equals_mit_with_value(tc)
            tc.verifyTrue(5 == tseries.MIT(tseries.Quarterly(),5));
        end

        % ---------- ordering ----------

        function lt_quarterly(tc)
            tc.verifyTrue(tseries.qq(2000,1) < tseries.qq(2000,2));
        end

        function le_quarterly_eq(tc)
            tc.verifyTrue(tseries.qq(2000,1) <= tseries.qq(2000,1));
        end

        function lt_mixed_freq_throws(tc)
            tc.verifyError(@() tseries.qq(2000,1) < tseries.mm(2000,1), 'tseries:mixedFreq');
        end

        function le_mixed_freq_throws(tc)
            tc.verifyError(@() tseries.qq(2000,1) <= tseries.mm(2000,1), 'tseries:mixedFreq');
        end

        function eq_int_zero(tc)
            tc.verifyTrue(tseries.qq(0,1) == 0);
            tc.verifyTrue(tseries.mm(0,1) == 0);
        end

        function eq_qq_mm_zero(tc)
            % Both numerically zero but different frequencies
            tc.verifyFalse(tseries.qq(0,1) == tseries.mm(0,1));
        end

        function duration_lt_duration(tc)
            tc.verifyTrue(tseries.Duration(tseries.Quarterly(),5) < tseries.Duration(tseries.Quarterly(),6));
        end

        function duration_not_lt_self(tc)
            tc.verifyFalse(tseries.Duration(tseries.Quarterly(),5) < tseries.Duration(tseries.Quarterly(),5));
        end

        function duration_le_self(tc)
            tc.verifyTrue(tseries.Duration(tseries.Quarterly(),5) <= tseries.Duration(tseries.Quarterly(),5));
        end

        function duration_eq_int(tc)
            tc.verifyTrue(tseries.Duration(tseries.Quarterly(),5) == 5);
            tc.verifyTrue(tseries.Duration(tseries.Monthly(),5) == 5);
        end

        function duration_ne_other_freq_same_value(tc)
            tc.verifyFalse(tseries.Duration(tseries.Quarterly(),5) == tseries.Duration(tseries.Monthly(),5));
        end

        function lt_mit_duration_throws(tc)
            tc.verifyError(@() tseries.MIT(tseries.Quarterly(),5) < tseries.Duration(tseries.Quarterly(),5), ...
                'tseries:invalidArith');
        end

        % ---------- addition ----------

        function add_mit_int(tc)
            tc.verifyTrue(tseries.qq(2020,1) + 4 == tseries.qq(2021,1));
        end

        function add_mit_mit_throws(tc)
            tc.verifyError(@() tseries.qq(2020,1) + tseries.qq(1,0), 'tseries:invalidArith');
        end

        function add_mit_mixed_freq_throws(tc)
            tc.verifyError(@() tseries.qq(2020,1) + tseries.mm(1,1), 'tseries:invalidArith');
        end

        function add_mit_duration(tc)
            tc.verifyTrue(tseries.qq(2020,1) + tseries.Duration(tseries.Quarterly(),4) == tseries.qq(2021,1));
        end

        function add_durations(tc)
            r = tseries.Duration(tseries.Quarterly(),5) + tseries.Duration(tseries.Quarterly(),2);
            tc.verifyTrue(r == 7);
            tc.verifyClass(r, 'tseries.Duration');
        end

        function add_duration_int(tc)
            r = tseries.Duration(tseries.Quarterly(),5) + 2;
            tc.verifyTrue(r == 7);
            tc.verifyClass(r, 'tseries.Duration');
        end

        function add_int_duration(tc)
            r = 2 + tseries.Duration(tseries.Quarterly(),5);
            tc.verifyTrue(r == 7);
            tc.verifyClass(r, 'tseries.Duration');
        end

        function add_duration_mixed_freq_throws(tc)
            tc.verifyError(@() tseries.Duration(tseries.Quarterly(),5) + tseries.Duration(tseries.Monthly(),2), ...
                'tseries:mixedFreq');
        end

        function add_mit_duration_mixed_freq_throws(tc)
            tc.verifyError(@() tseries.qq(2020,1) + tseries.Duration(tseries.Monthly(),2), 'tseries:mixedFreq');
        end

        % ---------- conversion to float ----------

        function plus_float_returns_float(tc)
            % TODO: this should actually return something like 8000 + 1.1
            tc.verifyEqual(tseries.qq(2000,1) + 1.1, 2001.1);
            tc.verifyEqual(tseries.qq(2000,1) + 1.2, 2001.2);
        end

        % ---------- year, period ----------

        function year_period_quarterly(tc)
            v = tseries.qq(2020, 2);
            tc.verifyEqual(tseries.year(v), 2020);
            tc.verifyEqual(tseries.period(v), 2);
        end

        function year_period_monthly(tc)
            tc.verifyEqual(tseries.year(tseries.mm(2020,12)), 2020);
            tc.verifyEqual(tseries.period(tseries.mm(2020,12)), 12);
        end

        function year_throws_on_unit(tc)
            tc.verifyError(@() tseries.year(tseries.MIT(tseries.Unit(),1)), 'tseries:noMatch');
        end

        % ---------- mm/qq/yy raw values ----------

        function mm_qq_yy_raw(tc)
            tc.verifyTrue(tseries.mm(2020,1) == tseries.MIT(tseries.Monthly(), 2020*12));
            tc.verifyTrue(tseries.qq(2020,1) == tseries.MIT(tseries.Quarterly(), 2020*4));
            tc.verifyTrue(tseries.yy(2020)   == tseries.MIT(tseries.Yearly(),    2020));
        end

        % ---------- frequencyof ----------

        function frequencyof_returns_class(tc)
            tc.verifyTrue(isa(tseries.frequencyof(tseries.qq(2000,1)), 'tseries.Quarterly'));
            tc.verifyTrue(isa(tseries.frequencyof(tseries.mm(2000,1)), 'tseries.Monthly'));
            tc.verifyTrue(isa(tseries.frequencyof(tseries.yy(2000)),  'tseries.Yearly'));
            tc.verifyTrue(isa(tseries.frequencyof(tseries.MIT(tseries.Unit(),1)), 'tseries.Unit'));
        end

        function frequencyof_throws_on_non_freq(tc)
            tc.verifyError(@() tseries.frequencyof(1), 'tseries:noMatch');
        end

        function frequencyof_on_range(tc)
            rng = tseries.qq(2001,1) : tseries.qq(2002,1);
            tc.verifyTrue(isa(tseries.frequencyof(rng), 'tseries.Quarterly'));
        end

        function frequencyof_on_duration(tc)
            d = tseries.qq(2000,1) - tseries.qq(2000,1);
            tc.verifyTrue(isa(tseries.frequencyof(d), 'tseries.Quarterly'));
        end

        % ---------- ops grab-bag (MITops) ----------

        function unitops(tc)
            U = tseries.Unit();
            tc.verifyTrue(tseries.MIT(U,5) < tseries.MIT(U,8));
            tc.verifyTrue(tseries.MIT(U,5) <= tseries.MIT(U,8));
            tc.verifyTrue(tseries.MIT(U,5) <= tseries.MIT(U,5));
            tc.verifyTrue(tseries.MIT(U,5) >= tseries.MIT(U,5));
            tc.verifyTrue(tseries.MIT(U,5) == tseries.MIT(U,5));
            tc.verifyTrue(tseries.MIT(U,8) >= tseries.MIT(U,5));
            tc.verifyTrue(tseries.MIT(U,8) >  tseries.MIT(U,5));
        end

        function yearly_plus_int(tc)
            tc.verifyTrue(tseries.yy(2001) + 5 == tseries.yy(2006));
        end

        function quarterly_diff(tc)
            tc.verifyTrue(tseries.qq(2003,1) - tseries.qq(2001,3) == 6);
            tc.verifyTrue(tseries.qq(2003,1) - 6 == tseries.qq(2001,3));
        end

        function int_minus_mit_throws(tc)
            tc.verifyError(@() 6 - tseries.qq(2003,1), 'tseries:invalidArith');
        end

        function mit_plus_mit_throws_simple(tc)
            tc.verifyError(@() tseries.qq(2003,1) + tseries.qq(2003,1), 'tseries:invalidArith');
        end

        function mit_plus_diffFreq_throws(tc)
            tc.verifyError(@() tseries.qq(2003,1) + tseries.yy(2003), 'tseries:invalidArith');
        end

        % ---------- constructors / shorthand ----------

        function frequencyof_constructor_calls(tc)
            tc.verifyEqual(tseries.frequencyof(tseries.yy(2022)),  tseries.Yearly());
            tc.verifyEqual(tseries.frequencyof(tseries.qq(2022,1)),tseries.Quarterly());
            tc.verifyEqual(tseries.frequencyof(tseries.mm(2022,1)),tseries.Monthly());
        end

        function constructor_validation_throws(tc)
            tc.verifyError(@() tseries.HalfYearly(-1), 'tseries:invalidArith');
            tc.verifyError(@() tseries.HalfYearly(7),  'tseries:invalidArith');
            tc.verifyError(@() tseries.Quarterly(-1),  'tseries:invalidArith');
            tc.verifyError(@() tseries.Quarterly(4),   'tseries:invalidArith');
            tc.verifyError(@() tseries.Yearly(-1),     'tseries:invalidArith');
            tc.verifyError(@() tseries.Yearly(13),     'tseries:invalidArith');
        end

        function frequency_is_predicates(tc)
            tc.verifyTrue(tseries.isyearly(tseries.Yearly()));
            tc.verifyTrue(tseries.isyearly(tseries.Yearly(2)));
            tc.verifyFalse(tseries.isyearly(tseries.Quarterly()));
            tc.verifyTrue(tseries.isyearly(tseries.yy(2022)));

            tc.verifyTrue(tseries.isquarterly(tseries.Quarterly()));
            tc.verifyTrue(tseries.isquarterly(tseries.Quarterly(2)));
            tc.verifyFalse(tseries.isquarterly(tseries.Yearly()));
            tc.verifyTrue(tseries.isquarterly(tseries.qq(2022,1)));

            tc.verifyTrue(tseries.ishalfyearly(tseries.HalfYearly()));
            tc.verifyTrue(tseries.ishalfyearly(tseries.HalfYearly(2)));
            tc.verifyFalse(tseries.ishalfyearly(tseries.Yearly()));

            tc.verifyTrue(tseries.ismonthly(tseries.Monthly()));
            tc.verifyFalse(tseries.ismonthly(tseries.Yearly()));
            tc.verifyTrue(tseries.ismonthly(tseries.mm(2022,1)));

            tc.verifyTrue(tseries.isweekly(tseries.Weekly()));
            tc.verifyTrue(tseries.isweekly(tseries.Weekly(3)));
            tc.verifyFalse(tseries.isweekly(tseries.Yearly()));

            tc.verifyTrue(tseries.isbdaily(tseries.BDaily()));
            tc.verifyFalse(tseries.isbdaily(tseries.Daily()));

            tc.verifyTrue(tseries.isdaily(tseries.Daily()));
            tc.verifyFalse(tseries.isdaily(tseries.BDaily()));
        end

        % ---------- ppy / endperiod / sanitize_frequency ----------

        function ppy_values(tc)
            tc.verifyEqual(tseries.ppy(tseries.Daily()), 365);
            tc.verifyEqual(tseries.ppy(tseries.BDaily()), 260);
            tc.verifyEqual(tseries.ppy(tseries.Weekly()), 52);
            tc.verifyEqual(tseries.ppy(tseries.Weekly(7)), 52);
            tc.verifyEqual(tseries.ppy(tseries.Weekly(3)), 52);
        end

        function endperiod_values(tc)
            tc.verifyEqual(tseries.endperiod(tseries.frequencyof(tseries.yy(2022))), 12);
            tc.verifyEqual(tseries.endperiod(tseries.Yearly(2)), 2);
            tc.verifyEqual(tseries.endperiod(tseries.Quarterly()), 3);
            tc.verifyEqual(tseries.endperiod(tseries.Quarterly(2)), 2);
            tc.verifyEqual(tseries.endperiod(tseries.HalfYearly()), 6);
            tc.verifyEqual(tseries.endperiod(tseries.HalfYearly(4)), 4);
            tc.verifyEqual(tseries.endperiod(tseries.Monthly()), 1);
            tc.verifyEqual(tseries.endperiod(tseries.Weekly()), 7);
            tc.verifyEqual(tseries.endperiod(tseries.Weekly(6)), 6);
        end

        function sanitize_frequency_default_inst(tc)
            tc.verifyTrue(tseries.sanitize_frequency('Monthly') == tseries.Monthly());
            tc.verifyTrue(tseries.sanitize_frequency('Yearly')  == tseries.Yearly(12));
            tc.verifyTrue(tseries.sanitize_frequency('Quarterly') == tseries.Quarterly(3));
            tc.verifyTrue(tseries.sanitize_frequency('HalfYearly') == tseries.HalfYearly(6));
            tc.verifyTrue(tseries.sanitize_frequency('Weekly')  == tseries.Weekly(7));
        end
    end
end

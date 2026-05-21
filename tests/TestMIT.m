classdef TestMIT < matlab.unittest.TestCase
    %TESTMIT  Mirrors the @testset "MIT,Duration", "MITops", "mm,qq,yy",
    %         "year,period", "frequencyof", "constructors", "MIT.show"
    %         blocks of TimeSeriesEcon.jl/test/test_mit.jl.

    methods (Test)
        % ---------- mit2yp ----------

        function mit2yp_quarterly_5(tc)
            tc.verifyEqual(double(tse.mit2yp(tse.MIT(tse.Quarterly(), 5))), [1, 2]);
        end

        function mit2yp_quarterly_4(tc)
            tc.verifyEqual(double(tse.mit2yp(tse.MIT(tse.Quarterly(), 4))), [1, 1]);
        end

        function mit2yp_quarterly_3(tc)
            tc.verifyEqual(double(tse.mit2yp(tse.MIT(tse.Quarterly(), 3))), [0, 4]);
        end

        function mit2yp_quarterly_0(tc)
            tc.verifyEqual(double(tse.mit2yp(tse.MIT(tse.Quarterly(), 0))), [0, 1]);
        end

        function mit2yp_quarterly_neg1(tc)
            tc.verifyEqual(double(tse.mit2yp(tse.MIT(tse.Quarterly(), -1))), [-1, 4]);
        end

        function mit2yp_quarterly_neg5(tc)
            tc.verifyEqual(double(tse.mit2yp(tse.MIT(tse.Quarterly(), -5))), [-2, 4]);
        end

        function mit2yp_quarterly_neg6(tc)
            tc.verifyEqual(double(tse.mit2yp(tse.MIT(tse.Quarterly(), -6))), [-2, 3]);
        end

        % ---------- subtractions ----------

        function subtract_mit_mit_yields_duration(tc)
            d = tse.qq(2020,1) - tse.qq(2019,2);
            tc.verifyClass(d, 'tse.Duration');
            tc.verifyEqual(double(d.value), double(3));
        end

        function subtract_mit_int_yields_mit(tc)
            r = tse.qq(2020,1) - 2;
            tc.verifyClass(r, 'tse.MIT');
            tc.verifyTrue(isa(r.frequency, 'tse.Quarterly'));
        end

        function subtract_mit_duration_yields_mit(tc)
            r = tse.qq(2020,1) - tse.Duration(tse.Quarterly(), 2);
            tc.verifyClass(r, 'tse.MIT');
        end

        function subtract_duration_int_yields_duration(tc)
            r = tse.Duration(tse.Quarterly(), 5) - 2;
            tc.verifyClass(r, 'tse.Duration');
        end

        function subtract_duration_duration_yields_duration(tc)
            r = tse.Duration(tse.Quarterly(), 5) - tse.Duration(tse.Quarterly(), 2);
            tc.verifyClass(r, 'tse.Duration');
        end

        function subtract_mixed_frequency_throws(tc)
            tc.verifyError(@() tse.qq(2020,1) - tse.mm(2019,2), 'tseries:mixedFreq');
        end

        function subtract_mit_durationOfDifferentFreqThrows(tc)
            tc.verifyError(@() tse.qq(2020,1) - tse.Duration(tse.Monthly(), 5), ...
                'tseries:mixedFreq');
        end

        function subtract_durations_different_freq_throws(tc)
            tc.verifyError(@() tse.Duration(tse.Quarterly(),8) - tse.Duration(tse.Monthly(),5), ...
                'tseries:mixedFreq');
        end

        % ---------- equality ----------

        function equal_same_mit(tc)
            tc.verifyTrue(tse.qq(2020,1) == tse.qq(2020,1));
        end

        function unequal_different_period(tc)
            tc.verifyTrue(tse.qq(2020,1) ~= tse.qq(2020,2));
        end

        function unequal_different_frequency(tc)
            tc.verifyTrue(tse.qq(2020,1) ~= tse.mm(2020,1));
        end

        function int_equals_mit_value(tc)
            r = tse.qq(2020,1) - (tse.qq(2020,1) - 5);
            tc.verifyTrue(5 == r);
            tc.verifyTrue(tse.Duration(tse.Quarterly(), 5) == r);
        end

        function duration_ne_mit_same_value(tc)
            tc.verifyTrue(tse.Duration(tse.Quarterly(),5) ~= tse.MIT(tse.Quarterly(),5));
        end

        function int_equals_mit_with_value(tc)
            tc.verifyTrue(5 == tse.MIT(tse.Quarterly(),5));
        end

        % ---------- ordering ----------

        function lt_quarterly(tc)
            tc.verifyTrue(tse.qq(2000,1) < tse.qq(2000,2));
        end

        function le_quarterly_eq(tc)
            tc.verifyTrue(tse.qq(2000,1) <= tse.qq(2000,1));
        end

        function lt_mixed_freq_throws(tc)
            tc.verifyError(@() tse.qq(2000,1) < tse.mm(2000,1), 'tseries:mixedFreq');
        end

        function le_mixed_freq_throws(tc)
            tc.verifyError(@() tse.qq(2000,1) <= tse.mm(2000,1), 'tseries:mixedFreq');
        end

        function eq_int_zero(tc)
            tc.verifyTrue(tse.qq(0,1) == 0);
            tc.verifyTrue(tse.mm(0,1) == 0);
        end

        function eq_qq_mm_zero(tc)
            % Both numerically zero but different frequencies
            tc.verifyFalse(tse.qq(0,1) == tse.mm(0,1));
        end

        function duration_lt_duration(tc)
            tc.verifyTrue(tse.Duration(tse.Quarterly(),5) < tse.Duration(tse.Quarterly(),6));
        end

        function duration_not_lt_self(tc)
            tc.verifyFalse(tse.Duration(tse.Quarterly(),5) < tse.Duration(tse.Quarterly(),5));
        end

        function duration_le_self(tc)
            tc.verifyTrue(tse.Duration(tse.Quarterly(),5) <= tse.Duration(tse.Quarterly(),5));
        end

        function duration_eq_int(tc)
            tc.verifyTrue(tse.Duration(tse.Quarterly(),5) == 5);
            tc.verifyTrue(tse.Duration(tse.Monthly(),5) == 5);
        end

        function duration_ne_other_freq_same_value(tc)
            tc.verifyFalse(tse.Duration(tse.Quarterly(),5) == tse.Duration(tse.Monthly(),5));
        end

        function lt_mit_duration_throws(tc)
            tc.verifyError(@() tse.MIT(tse.Quarterly(),5) < tse.Duration(tse.Quarterly(),5), ...
                'tseries:invalidArith');
        end

        % ---------- addition ----------

        function add_mit_int(tc)
            tc.verifyTrue(tse.qq(2020,1) + 4 == tse.qq(2021,1));
        end

        function add_mit_mit_throws(tc)
            tc.verifyError(@() tse.qq(2020,1) + tse.qq(1,0), 'tseries:invalidArith');
        end

        function add_mit_mixed_freq_throws(tc)
            tc.verifyError(@() tse.qq(2020,1) + tse.mm(1,1), 'tseries:invalidArith');
        end

        function add_mit_duration(tc)
            tc.verifyTrue(tse.qq(2020,1) + tse.Duration(tse.Quarterly(),4) == tse.qq(2021,1));
        end

        function add_durations(tc)
            r = tse.Duration(tse.Quarterly(),5) + tse.Duration(tse.Quarterly(),2);
            tc.verifyTrue(r == 7);
            tc.verifyClass(r, 'tse.Duration');
        end

        function add_duration_int(tc)
            r = tse.Duration(tse.Quarterly(),5) + 2;
            tc.verifyTrue(r == 7);
            tc.verifyClass(r, 'tse.Duration');
        end

        function add_int_duration(tc)
            r = 2 + tse.Duration(tse.Quarterly(),5);
            tc.verifyTrue(r == 7);
            tc.verifyClass(r, 'tse.Duration');
        end

        function add_duration_mixed_freq_throws(tc)
            tc.verifyError(@() tse.Duration(tse.Quarterly(),5) + tse.Duration(tse.Monthly(),2), ...
                'tseries:mixedFreq');
        end

        function add_mit_duration_mixed_freq_throws(tc)
            tc.verifyError(@() tse.qq(2020,1) + tse.Duration(tse.Monthly(),2), 'tseries:mixedFreq');
        end

        % ---------- conversion to float ----------

        function plus_float_returns_float(tc)
            % TODO: this should actually return something like 8000 + 1.1
            tc.verifyEqual(tse.qq(2000,1) + 1.1, 2001.1);
            tc.verifyEqual(tse.qq(2000,1) + 1.2, 2001.2);
        end

        % ---------- year, period ----------

        function year_period_quarterly(tc)
            v = tse.qq(2020, 2);
            tc.verifyEqual(tse.year(v), 2020);
            tc.verifyEqual(tse.period(v), 2);
        end

        function year_period_monthly(tc)
            tc.verifyEqual(tse.year(tse.mm(2020,12)), 2020);
            tc.verifyEqual(tse.period(tse.mm(2020,12)), 12);
        end

        function year_throws_on_unit(tc)
            tc.verifyError(@() tse.year(tse.MIT(tse.Unit(),1)), 'tseries:noMatch');
        end

        % ---------- mm/qq/yy raw values ----------

        function mm_qq_yy_raw(tc)
            tc.verifyTrue(tse.mm(2020,1) == tse.MIT(tse.Monthly(), 2020*12));
            tc.verifyTrue(tse.qq(2020,1) == tse.MIT(tse.Quarterly(), 2020*4));
            tc.verifyTrue(tse.yy(2020)   == tse.MIT(tse.Yearly(),    2020));
        end

        % ---------- frequencyof ----------

        function frequencyof_returns_class(tc)
            tc.verifyTrue(isa(tse.frequencyof(tse.qq(2000,1)), 'tse.Quarterly'));
            tc.verifyTrue(isa(tse.frequencyof(tse.mm(2000,1)), 'tse.Monthly'));
            tc.verifyTrue(isa(tse.frequencyof(tse.yy(2000)),  'tse.Yearly'));
            tc.verifyTrue(isa(tse.frequencyof(tse.MIT(tse.Unit(),1)), 'tse.Unit'));
        end

        function frequencyof_throws_on_non_freq(tc)
            tc.verifyError(@() tse.frequencyof(1), 'tseries:noMatch');
        end

        function frequencyof_on_range(tc)
            rng = tse.qq(2001,1) : tse.qq(2002,1);
            tc.verifyTrue(isa(tse.frequencyof(rng), 'tse.Quarterly'));
        end

        function frequencyof_on_duration(tc)
            d = tse.qq(2000,1) - tse.qq(2000,1);
            tc.verifyTrue(isa(tse.frequencyof(d), 'tse.Quarterly'));
        end

        % ---------- ops grab-bag (MITops) ----------

        function unitops(tc)
            U = tse.Unit();
            tc.verifyTrue(tse.MIT(U,5) < tse.MIT(U,8));
            tc.verifyTrue(tse.MIT(U,5) <= tse.MIT(U,8));
            tc.verifyTrue(tse.MIT(U,5) <= tse.MIT(U,5));
            tc.verifyTrue(tse.MIT(U,5) >= tse.MIT(U,5));
            tc.verifyTrue(tse.MIT(U,5) == tse.MIT(U,5));
            tc.verifyTrue(tse.MIT(U,8) >= tse.MIT(U,5));
            tc.verifyTrue(tse.MIT(U,8) >  tse.MIT(U,5));
        end

        function yearly_plus_int(tc)
            tc.verifyTrue(tse.yy(2001) + 5 == tse.yy(2006));
        end

        function quarterly_diff(tc)
            tc.verifyTrue(tse.qq(2003,1) - tse.qq(2001,3) == 6);
            tc.verifyTrue(tse.qq(2003,1) - 6 == tse.qq(2001,3));
        end

        function int_minus_mit_throws(tc)
            tc.verifyError(@() 6 - tse.qq(2003,1), 'tseries:invalidArith');
        end

        function mit_plus_mit_throws_simple(tc)
            tc.verifyError(@() tse.qq(2003,1) + tse.qq(2003,1), 'tseries:invalidArith');
        end

        function mit_plus_diffFreq_throws(tc)
            tc.verifyError(@() tse.qq(2003,1) + tse.yy(2003), 'tseries:invalidArith');
        end

        % ---------- constructors / shorthand ----------

        function frequencyof_constructor_calls(tc)
            tc.verifyEqual(tse.frequencyof(tse.yy(2022)),  tse.Yearly());
            tc.verifyEqual(tse.frequencyof(tse.qq(2022,1)),tse.Quarterly());
            tc.verifyEqual(tse.frequencyof(tse.mm(2022,1)),tse.Monthly());
        end

        function constructor_validation_throws(tc)
            tc.verifyError(@() tse.HalfYearly(-1), 'tseries:invalidArith');
            tc.verifyError(@() tse.HalfYearly(7),  'tseries:invalidArith');
            tc.verifyError(@() tse.Quarterly(-1),  'tseries:invalidArith');
            tc.verifyError(@() tse.Quarterly(4),   'tseries:invalidArith');
            tc.verifyError(@() tse.Yearly(-1),     'tseries:invalidArith');
            tc.verifyError(@() tse.Yearly(13),     'tseries:invalidArith');
        end

        function frequency_is_predicates(tc)
            tc.verifyTrue(tse.isyearly(tse.Yearly()));
            tc.verifyTrue(tse.isyearly(tse.Yearly(2)));
            tc.verifyFalse(tse.isyearly(tse.Quarterly()));
            tc.verifyTrue(tse.isyearly(tse.yy(2022)));

            tc.verifyTrue(tse.isquarterly(tse.Quarterly()));
            tc.verifyTrue(tse.isquarterly(tse.Quarterly(2)));
            tc.verifyFalse(tse.isquarterly(tse.Yearly()));
            tc.verifyTrue(tse.isquarterly(tse.qq(2022,1)));

            tc.verifyTrue(tse.ishalfyearly(tse.HalfYearly()));
            tc.verifyTrue(tse.ishalfyearly(tse.HalfYearly(2)));
            tc.verifyFalse(tse.ishalfyearly(tse.Yearly()));

            tc.verifyTrue(tse.ismonthly(tse.Monthly()));
            tc.verifyFalse(tse.ismonthly(tse.Yearly()));
            tc.verifyTrue(tse.ismonthly(tse.mm(2022,1)));

            tc.verifyTrue(tse.isweekly(tse.Weekly()));
            tc.verifyTrue(tse.isweekly(tse.Weekly(3)));
            tc.verifyFalse(tse.isweekly(tse.Yearly()));

            tc.verifyTrue(tse.isbdaily(tse.BDaily()));
            tc.verifyFalse(tse.isbdaily(tse.Daily()));

            tc.verifyTrue(tse.isdaily(tse.Daily()));
            tc.verifyFalse(tse.isdaily(tse.BDaily()));
        end

        % ---------- ppy / endperiod / sanitize_frequency ----------

        function ppy_values(tc)
            tc.verifyEqual(tse.ppy(tse.Daily()), 365);
            tc.verifyEqual(tse.ppy(tse.BDaily()), 260);
            tc.verifyEqual(tse.ppy(tse.Weekly()), 52);
            tc.verifyEqual(tse.ppy(tse.Weekly(7)), 52);
            tc.verifyEqual(tse.ppy(tse.Weekly(3)), 52);
        end

        function endperiod_values(tc)
            tc.verifyEqual(tse.endperiod(tse.frequencyof(tse.yy(2022))), 12);
            tc.verifyEqual(tse.endperiod(tse.Yearly(2)), 2);
            tc.verifyEqual(tse.endperiod(tse.Quarterly()), 3);
            tc.verifyEqual(tse.endperiod(tse.Quarterly(2)), 2);
            tc.verifyEqual(tse.endperiod(tse.HalfYearly()), 6);
            tc.verifyEqual(tse.endperiod(tse.HalfYearly(4)), 4);
            tc.verifyEqual(tse.endperiod(tse.Monthly()), 1);
            tc.verifyEqual(tse.endperiod(tse.Weekly()), 7);
            tc.verifyEqual(tse.endperiod(tse.Weekly(6)), 6);
        end

        function sanitize_frequency_default_inst(tc)
            tc.verifyTrue(tse.sanitize_frequency('Monthly') == tse.Monthly());
            tc.verifyTrue(tse.sanitize_frequency('Yearly')  == tse.Yearly(12));
            tc.verifyTrue(tse.sanitize_frequency('Quarterly') == tse.Quarterly(3));
            tc.verifyTrue(tse.sanitize_frequency('HalfYearly') == tse.HalfYearly(6));
            tc.verifyTrue(tse.sanitize_frequency('Weekly')  == tse.Weekly(7));
        end
    end
end

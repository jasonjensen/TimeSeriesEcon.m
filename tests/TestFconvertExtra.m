classdef TestFconvertExtra < FconvertTestUtils
    %TESTFCONVERTEXTRA  Mirrors the "pass function", "pass custom function",
    %   and "all combinations" testsets from test_fconvert.jl.  The Julia
    %   originals use randomness/property checks; here they are made
    %   deterministic but cover the same equivalences and combinations.

    methods (Static)
        function fs = someFreqs()
            fs = { tse.Daily(), tse.BDaily(), tse.Weekly(), tse.Weekly(3), ...
                   tse.Weekly(6), tse.Weekly(7), tse.Monthly(), tse.Quarterly(), ...
                   tse.Quarterly(1), tse.Quarterly(3), tse.HalfYearly(), ...
                   tse.HalfYearly(1), tse.HalfYearly(4), tse.Yearly(), ...
                   tse.Yearly(3), tse.Yearly(7), tse.Yearly(12) };
        end

        function ts = makeTS(F)
            startMIT = tse.fconvert(F, tse.day('2022-06-15'));
            n = 4 * double(F.PeriodsPerYear);
            ts = tse.TSeries(startMIT, (1:n)');
        end

        function v = secondHighest(x)
            if numel(x) == 1, v = x(1); else, s = sort(x); v = s(end-1); end
        end
    end

    methods (Test)

        function pass_custom_function(tc)
            % to lower frequency: custom aggregator over each group
            ts = tse.TSeries(tc.M(2022,1), (1:12)');
            ts_q = tse.fconvert(@(x) tc.secondHighest(x), tse.Quarterly(), ts);
            tc.vApprox(ts_q.values, [2, 5, 8, 11], 1e-12);

            % to higher frequency: custom disaggregator fn(values, counts)
            ts2 = tse.TSeries(tc.Q(2022,1), (1:4)');
            ts_m = tse.fconvert(@(x, inner) repelem(x(:)/2, inner(:)), tse.Monthly(), ts2);
            tc.vApprox(ts_m.values, [0.5,0.5,0.5,1,1,1,1.5,1.5,1.5,2,2,2], 1e-12);
        end

        function pass_function(tc)
            % fconvert(fn, F_to, ts) must match the equivalent named method,
            % for the to-lower aggregators (mean/sum/min/max).
            fs = TestFconvertExtra.someFreqs();
            for a = 1:numel(fs)
                F_from = fs{a};
                if double(F_from.PeriodsPerYear) <= 1, continue; end   % skip Yearly
                ts = TestFconvertExtra.makeTS(F_from);
                for b = 1:numel(fs)
                    F_to = fs{b};
                    if double(F_to.PeriodsPerYear) >= double(F_from.PeriodsPerYear)
                        continue
                    end
                    pairs = { @mean, 'mean'; @sum, 'sum'; @min, 'min'; @max, 'max' };
                    for r = {'begin', 'end'}
                        ref = r{1};
                        for k = 1:size(pairs, 1)
                            lhs = tse.fconvert(pairs{k,1}, F_to, ts, 'ref', ref);
                            rhs = tse.fconvert(F_to, ts, 'method', pairs{k,2}, 'ref', ref);
                            tc.verifyTrue(eq(lhs.firstdate, rhs.firstdate));
                            tc.vApprox(lhs.values, rhs.values, 1e-9);
                        end
                    end
                end
            end
        end

        function all_combinations(tc)
            % Every ordered pair of frequencies converts without error and
            % yields a non-empty, finite, correctly-typed result.
            fs = TestFconvertExtra.someFreqs();
            for a = 1:numel(fs)
                F_from = fs{a};
                t_from = tse.TSeries(tse.MIT(F_from, int64(100)), (1:800)');
                for b = 1:numel(fs)
                    F_to = fs{b};
                    if eqfreq(F_to, F_from), continue; end
                    expCode = tse.MIT(F_to, int64(0)).frequency;

                    t_to = tse.fconvert(F_to, t_from);
                    tc.verifyEqual(t_to.frequency, expCode);
                    tc.verifyGreaterThan(numel(t_to.values), 0);

                    if double(F_to.PeriodsPerYear) <= double(F_from.PeriodsPerYear)
                        methods = {'mean','sum','point','min','max','begin','end'};
                    else
                        methods = {'const','even','linear'};
                    end
                    for m = methods
                        for r = {'begin','end'}
                            sub = tse.fconvert(F_to, t_from, 'method', m{1}, 'ref', r{1});
                            tc.verifyEqual(sub.frequency, expCode);
                            tc.verifyGreaterThan(numel(sub.values), 0);
                            vv = sub.values(~isnan(sub.values));
                            if ~isempty(vv)
                                tc.verifyLessThan(max(vv), 1e6);
                                tc.verifyGreaterThan(min(vv), -1e6);
                            end
                        end
                    end

                    % ranges
                    rng_to = tse.fconvert(F_to, rangeof(t_from));
                    tc.verifyEqual(rng_to.frequency, expCode);
                    tc.verifyGreaterThan(length(rng_to), 0);
                end
            end
        end
    end
end

function tf = eqfreq(a, b)
    tf = strcmp(class(a), class(b)) && double(a.endPeriod) == double(b.endPeriod);
end

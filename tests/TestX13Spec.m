classdef TestX13Spec < matlab.unittest.TestCase
%TESTX13SPEC  Port of the Julia X13 spec construction, serialisation, and
    %   validation tests. These run without the x13as binary by exercising
    %   x13write in test mode.

    methods (Access = private)
        function verifyContains(tc, s, expected)
            tc.verifyTrue(contains(s, expected), ...
                sprintf('Expected spec string to contain:\n%s\n\nGot:\n%s', expected, s));
        end
        function verifyAllContains(tc, s, expected)
            for i = 1:numel(expected)
                tc.verifyContains(s, expected{i});
            end
        end
        function varargout = verifyWarnContains(tc, f, expected)
            lastwarn('');
            w = warning('on', 'all');
            c = onCleanup(@() warning(w)); %#ok<NASGU>
            [varargout{1:nargout}] = f();
            [msg, ~] = lastwarn();
            tc.verifyTrue(contains(msg, expected), ...
                sprintf('Expected warning to contain:\n%s\n\nGot:\n%s', expected, msg));
        end
        function s = noWarnWrite(tc, spec) %#ok<INUSD>
            w = warning('off', 'all');
            c = onCleanup(@() warning(w));
            s = tse.x13.x13write(spec, 'test', true);
        end
    end

    methods (Test)

        function building_a_spec(tc)
            ts = tse.TSeries(tse.qq(2022,1), (1:50)');
            spec = tse.x13.newspec(ts);
            m = tse.x13.ArimaSpec();
            tse.x13.arima(spec, m);
            tse.x13.estimate(spec);
            tse.x13.transform(spec);
            tse.x13.regression(spec);
            tse.x13.automdl(spec);
            tse.x13.x11(spec);
            tse.x13.x11regression(spec);
            tse.x13.check(spec);
            tse.x13.forecast(spec);
            tse.x13.force(spec);
            tse.x13.pickmdl(spec, [ ...
                tse.x13.ArimaModel(0,1,1,0,1,1, 'default', true), ...
                tse.x13.ArimaModel(0,1,2,0,1,1)]);
            tse.x13.history(spec);
            tse.x13.identify(spec);
            tse.x13.outlier(spec);
            tse.x13.seats(spec);
            tse.x13.slidingspans(spec);
            tse.x13.spectrum(spec);

            tc.verifyClass(spec, 'tse.x13.X13spec');
            tc.verifyClass(spec.arima, 'tse.x13.X13arima');
            tc.verifyClass(spec.estimate, 'tse.x13.X13estimate');
            tc.verifyClass(spec.transform, 'tse.x13.X13transform');
            tc.verifyClass(spec.regression, 'tse.x13.X13regression');
            tc.verifyClass(spec.automdl, 'tse.x13.X13automdl');
            tc.verifyClass(spec.x11, 'tse.x13.X13x11');
            tc.verifyClass(spec.x11regression, 'tse.x13.X13x11regression');
            tc.verifyClass(spec.check, 'tse.x13.X13check');
            tc.verifyClass(spec.forecast, 'tse.x13.X13forecast');
            tc.verifyClass(spec.force, 'tse.x13.X13force');
            tc.verifyClass(spec.pickmdl, 'tse.x13.X13pickmdl');
            tc.verifyClass(spec.history, 'tse.x13.X13history');
            tc.verifyClass(spec.identify, 'tse.x13.X13identify');
            tc.verifyClass(spec.outlier, 'tse.x13.X13outlier');
            tc.verifyClass(spec.seats, 'tse.x13.X13seats');
            tc.verifyClass(spec.slidingspans, 'tse.x13.X13slidingspans');
            tc.verifyClass(spec.spectrum, 'tse.x13.X13spectrum');
            tc.verifyClass(spec.series, 'tse.x13.X13series');

            spec2 = tse.x13.newspec(tse.Quarterly());
            tc.verifyClass(spec2, 'tse.x13.X13spec');
            F = spec2.frequencyof();
            tc.verifyClass(F, 'tse.Quarterly');
            tc.verifyEqual(F.endPeriod, 3);
            tse.x13.series(spec2, ts);
            tc.verifyClass(spec2.series.frequencyof(), 'tse.Quarterly');
        end

        function arimaspec_construction(tc)
            x1 = tse.x13.ArimaSpec(1,0,2);
            tc.verifyEqual(x1.p, 1); tc.verifyEqual(x1.d, 0);
            tc.verifyEqual(x1.q, 2); tc.verifyEqual(x1.period, 0);

            x2 = tse.x13.ArimaSpec(1,0,3);
            tc.verifyEqual(x2.q, 3);

            x3 = tse.x13.ArimaSpec(1,0,2,1,0,3);
            tc.verifyEqual(numel(x3), 2);
            tc.verifyEqual(x3(1).p, 1); tc.verifyEqual(x3(1).q, 2);
            tc.verifyEqual(x3(2).p, 1); tc.verifyEqual(x3(2).q, 3);

            a1 = tse.x13.arima(x3);
            tc.verifyClass(a1, 'tse.x13.X13arima');
            tc.verifyClass(a1.model, 'tse.x13.ArimaModel');
            tc.verifyEqual(a1.model.specs(1).q, 2);
            tc.verifyEqual(a1.model.specs(2).q, 3);

            a2 = tse.x13.arima(x1, x2);
            tc.verifyEqual(a2.model.specs(1).q, 2);
            tc.verifyEqual(a2.model.specs(2).q, 3);

            x4 = tse.x13.ArimaSpec(3);
            tc.verifyEqual(x4.p, 3); tc.verifyEqual(x4.d, 0);

            x5 = tse.x13.ArimaSpec([3]);
            tc.verifyEqual(x5.p, [3]); tc.verifyEqual(x5.d, 0); tc.verifyEqual(x5.q, 0);

            x6 = tse.x13.ArimaSpec(3,2);
            tc.verifyEqual(x6.p, 3); tc.verifyEqual(x6.d, 2); tc.verifyEqual(x6.q, 0);

            x7 = tse.x13.ArimaSpec([3],[2]);
            tc.verifyEqual(x7.p, [3]); tc.verifyEqual(x7.d, [2]); tc.verifyEqual(x7.q, 0);
        end

        function arima_writing(tc)
            % Manual example 1
            ts = tse.TSeries(tse.qq(1950,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Quarterly Grape Harvest");
            spec = tse.x13.newspec(xts);
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1));
            tse.x13.estimate(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('arima {\n        model = (0 1 1)\n}'));
            tc.verifyContains(s, 'estimate { }');

            % Manual example 2
            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.arima(spec, tse.x13.ArimaModel(2,1,0,0,1,1));
            tse.x13.estimate(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('arima {\n        model = (2 1 0)(0 1 1)\n}'));
            tc.verifyContains(s, sprintf('transform {\n        function = log\n}'));

            % Manual example 3
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', {'seasonal','const'});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1));
            tse.x13.estimate(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('arima {\n        model = (0 1 1)\n}'));
            tc.verifyContains(s, sprintf('regression {\n        variables = (seasonal const)\n}'));

            % Manual example 4 (explicit single lag -> cell)
            ts = tse.TSeries(tse.yy(1950), (1:50)');
            xts = tse.x13.series(ts, 'title', "Annual Olive Harvest");
            spec = tse.x13.newspec(xts);
            tse.x13.arima(spec, tse.x13.ArimaModel({2},1,0));
            tse.x13.estimate(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('arima {\n        model = ([2] 1 0)\n}'));

            % Manual example 5 (explicit period)
            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', 'const');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,12));
            tse.x13.estimate(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('arima {\n        model = (0 1 1)12\n}'));
            tc.verifyContains(s, sprintf('regression {\n        variables = const\n}'));

            % Manual example 6 (three factors with explicit period)
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', {'const','seasonal'});
            m = tse.x13.ArimaModel(tse.x13.ArimaSpec(1,1,0), tse.x13.ArimaSpec(1,0,0,3), tse.x13.ArimaSpec(0,0,1));
            tse.x13.arima(spec, m);
            tse.x13.estimate(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('arima {\n        model = (1 1 0)(1 0 0)3(0 0 1)\n}'));
            tc.verifyContains(s, sprintf('regression {\n        variables = (const seasonal)\n}'));

            % Manual example 7
            spec = tse.x13.newspec(xts, ...
                'transform', tse.x13.transform('func', 'log'), ...
                'arima', tse.x13.arima(tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12), ...
                    'ma', [NaN, 1.0], 'fixma', [false, true]), ...
                'estimate', tse.x13.estimate());
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('arima {\n        model = (0 1 1)(0 1 1)12\n        ma = (,1.0f)\n}'), ...
                'estimate { }', ...
                sprintf('transform {\n        function = log\n}') ...
            });

            tc.verifyError(@() tse.x13.arima(tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12), ...
                'ma', [NaN, 1.0], 'fixma', true), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.arima(tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12), ...
                'ar', [NaN, 1.0], 'fixar', true), 'tseries:noMatch');
            tc.verifyWarnContains(@() tse.x13.arima(tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12), ...
                'title', "This is a very long title that will most certainly trigger the warning about the title being truncated"), ...
                'Arima title truncated to 79 characters');
        end

        function automdl_writing(tc)
            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Sales");

            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'seasonal','const'});
            tse.x13.automdl(spec);
            tse.x13.estimate(spec);
            tse.x13.x11(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                'automdl { }', ...
                sprintf('regression {\n        variables = (seasonal const)\n}'), ...
                'x11 { }' ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', 'td');
            tse.x13.automdl(spec, 'diff', [1 1], 'maxorder', [3 NaN]);
            tse.x13.outlier(spec);
            tse.x13.estimate(spec);
            tse.x13.x11(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('automdl {\n        diff = (1, 1)\n        maxorder = (3, )\n}'), ...
                sprintf('regression {\n        variables = td\n}'), ...
                'x11 { }', ...
                'outlier { }' ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'aictest', 'td');
            tse.x13.automdl(spec);
            tse.x13.estimate(spec);
            tse.x13.x11(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                'automdl { }', ...
                sprintf('regression {\n        aictest = td\n}'), ...
                'x11 { }' ...
            });

            tc.verifyError(@() tse.x13.automdl('diff', [3 1]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('diff', [2 2]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('diff', [2 0 0]), 'tseries:noMatch');
            tc.verifyWarnContains(@() tse.x13.automdl('diff', [2 0], 'maxdiff', [2 1]), ...
                'The diff argument of the automdl spec will be ignored');
            tc.verifyError(@() tse.x13.automdl('maxdiff', [3 1]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('maxdiff', [2 2]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('maxdiff', [2 1 0]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('maxorder', [5 2]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('maxorder', [4 3]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('maxorder', [4 2 0]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('armalimit', -0.9), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('fcstlim', -3), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('fcstlim', 103), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('reducecv', -0.9), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('reducecv', 1.1), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.automdl('urfinal', 0.9), 'tseries:noMatch');
        end

        function check_writing(tc)
            ts = tse.TSeries(tse.mm(1964,1), (1:150)');
            xts = tse.x13.series(ts, 'title', "Monthly Retail Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'td', tse.x13.ao(tse.mm(1967,6)), tse.x13.ls(tse.mm(1971,6)), tse.x13.easter(14)});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.check(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                'check { }', ...
                sprintf('arima {\n        model = (0 1 1)(0 1 1)\n}'), ...
                sprintf('regression {\n        variables = (td ao1967.jun ls1971.jun easter[14])\n}') ...
            });

            ts = tse.TSeries(tse.mm(1964,1), (1:500)');
            xts = tse.x13.series(ts, 'title', "Warehouse clubs and supercenters");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', {'td', tse.x13.ao(tse.mm(2000,3)), tse.x13.tc(tse.mm(2001,2))});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.forecast(spec, 'maxlead', 24);
            tse.x13.estimate(spec);
            tse.x13.check(spec, 'acflimit', 2.0, 'qlimit', 0.05);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('check {\n        acflimit = 2.0\n        qlimit = 0.05\n}'), ...
                sprintf('forecast {\n        maxlead = 24\n}'), ...
                'estimate { }', ...
                sprintf('transform {\n        function = log\n}'), ...
                sprintf('arima {\n        model = (0 1 1)(0 1 1)\n}'), ...
                sprintf('regression {\n        variables = (td ao2000.mar tc2001.feb)\n}') ...
            });
        end

        function estimate_writing(tc)
            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', 'seasonal');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1), 'ma', 0.25, 'fixma', true);
            tse.x13.estimate(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                'estimate { }', ...
                sprintf('arima {\n        model = (0 1 1)\n        ma = (0.25f)\n}'), ...
                sprintf('regression {\n        variables = seasonal\n}') ...
            });

            ts = tse.TSeries(tse.mm(1978,12), (1:350)');
            xts = tse.x13.series(ts, 'title', "Monthly Inventory");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', {'td', tse.x13.ao(tse.mm(1999,1))});
            tse.x13.arima(spec, tse.x13.ArimaModel(1,1,0,0,1,1));
            tse.x13.estimate(spec, 'tol', 1e-4, 'maxiter', 100, 'exact', 'ma');
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('estimate {\n        exact = ma\n        maxiter = 100\n        tol = 0.0001\n}'), ...
                sprintf('arima {\n        model = (1 1 0)(0 1 1)\n}'), ...
                sprintf('transform {\n        function = log\n}'), ...
                sprintf('regression {\n        variables = (td ao1999.jan)\n}') ...
            });

            ts = tse.TSeries(tse.mm(1978,12), (1:300)');
            xts = tse.x13.series(ts, 'title', "Monthly Inventory");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.estimate(spec, 'file', "Inven.mdl", 'fix', 'all');
            tse.x13.outlier(spec, 'span', tse.x13.Span(tse.mm(2000,1)));
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('estimate {\n        file = "Inven.mdl"\n        fix = all\n}'), ...
                sprintf('transform {\n        function = log\n}'), ...
                sprintf('outlier {\n        span = (2000.jan, )\n}') ...
            });
        end

        function force_writing(tc)
            ts = tse.TSeries(tse.mm(1967,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Exports of truck parts");

            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec, 'seasonalma', 's3x9');
            tse.x13.force(spec, 'start', tse.x13.M(10));
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('x11 {\n        seasonalma = s3x9\n}'), ...
                sprintf('force {\n        start = oct\n}') ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec, 'seasonalma', 's3x9');
            tse.x13.force(spec, 'start', tse.x13.M(10), 'type', 'regress', 'rho', 0.8);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('x11 {\n        seasonalma = s3x9\n}'), ...
                sprintf('force {\n        rho = 0.8\n        start = oct\n        type = regress\n}') ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec, 'seasonalma', 's3x5');
            tse.x13.force(spec, 'type', 'none', 'round', true);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('x11 {\n        seasonalma = s3x5\n}'), ...
                sprintf('force {\n        round = yes\n        type = none\n}') ...
            });

            tc.verifyError(@() tse.x13.force('rho', -0.1), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.force('rho', 1.1), 'tseries:noMatch');
        end

        function forecast_writing(tc)
            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Sales");

            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', 'td');
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.forecast(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('transform {\n        function = log\n}'), ...
                sprintf('regression {\n        variables = td\n}'), ...
                sprintf('arima {\n        model = (0 1 1)(0 1 1)12\n}'), ...
                'forecast { }' ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', 'td');
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.estimate(spec);
            tse.x13.outlier(spec);
            tse.x13.forecast(spec, 'maxlead', 24);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                'estimate { }', ...
                'outlier { }', ...
                sprintf('forecast {\n        maxlead = 24\n}') ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', 'td');
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.estimate(spec);
            tse.x13.forecast(spec, 'maxlead', 15, 'probability', 0.90, 'exclude', 10);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('forecast {\n        exclude = 10\n        maxlead = 15\n        probability = 0.9\n}'));

            ts = tse.TSeries(tse.mm(1976,1), (1:250)');
            xts = tse.x13.series(ts, 'title', "Monthly Sales", 'span', tse.firstdate(ts):tse.mm(1990,3));
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', 'td');
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.estimate(spec);
            tse.x13.forecast(spec, 'maxlead', 24);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('forecast {\n        maxlead = 24\n}'));

            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', 'td');
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.forecast(spec, 'maxback', 12);
            tse.x13.x11(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('forecast {\n        maxback = 12\n}'), ...
                'x11 { }' ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', 'td');
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.estimate(spec);
            tse.x13.outlier(spec);
            tse.x13.forecast(spec, 'maxlead', 24, 'lognormal', true);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('forecast {\n        lognormal = yes\n        maxlead = 24\n}'));
        end

        function history_writing(tc)
            ts = tse.TSeries(tse.mm(1967,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Sales of livestock");
            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec, 'seasonalma', 's3x9');
            tse.x13.history(spec, 'sadjlags', 2);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('x11 {\n        seasonalma = s3x9\n}'), ...
                sprintf('history {\n        sadjlags = 2\n}') ...
            });

            ts = tse.TSeries(tse.mm(1969,7), (1:150)');
            xts = tse.x13.series(ts, 'title', "Exports of leather goods");
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const','td',tse.x13.ls(tse.mm(1972,5)),tse.x13.ls(tse.mm(1976,10))});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,2,1,1,0));
            tse.x13.estimate(spec);
            tse.x13.history(spec, 'estimates', 'fcst', 'fstep', 1, 'start', tse.mm(1975,1));
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('history {\n        estimates = fcst\n        fstep = 1\n        start = 1975.jan\n}'));

            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const','td',tse.x13.ls(tse.mm(1972,5)),tse.x13.ls(tse.mm(1976,10))});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,2,1,1,0));
            tse.x13.estimate(spec);
            tse.x13.history(spec, 'estimates', {'arma','fcst'}, 'start', tse.mm(1975,1));
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('history {\n        estimates = (arma fcst)\n        start = 1975.jan\n}'));

            ts = tse.TSeries(tse.mm(1967,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Housing Starts in the Midwest", ...
                'comptype', 'add', 'modelspan', tse.x13.Span([], tse.x13.M(12)));
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', 'td');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,2,0,1,1));
            tse.x13.x11(spec, 'seasonalma', 's3x3');
            tse.x13.history(spec, 'estimates', {'sadj','trend'});
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('history {\n        estimates = (sadj trend)\n}'), ...
                'modelspan = (, 0.dec)' ...
            });

            ts = tse.TSeries(tse.qq(1967,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Housing Starts in the Midwest", ...
                'comptype', 'add', 'modelspan', tse.x13.Span([], tse.x13.Q(3)));
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', 'td');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,2,0,1,1));
            tse.x13.x11(spec, 'seasonalma', 's3x3');
            tse.x13.history(spec, 'estimates', {'sadj','trend'});
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('history {\n        estimates = (sadj trend)\n}'), ...
                'modelspan = (, 0.3)', ...
                'period = 4', ...
                'start = 1967.1' ...
            });

            tc.verifyError(@() tse.x13.history('fstep', [1 2 3 4 5]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.history('fstep', [-1 2]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.history('fstep', -2), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.history('sadjlags', [1 2 3 4 5 6]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.history('sadjlags', [-1 2]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.history('sadjlags', -2), 'tseries:noMatch');
        end

        function identify_writing(tc)
            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Sales");

            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.identify(spec, 'diff', [0 1], 'sdiff', [0 1]);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('transform {\n        function = log\n}'), ...
                sprintf('identify {\n        diff = (0, 1)\n        sdiff = (0, 1)\n}') ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const','seasonal'});
            tse.x13.identify(spec, 'diff', [0 1]);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('regression {\n        variables = (const seasonal)\n}'), ...
                sprintf('identify {\n        diff = (0, 1)\n}') ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', {'td', tse.x13.easter(14)});
            tse.x13.identify(spec, 'diff', [1], 'sdiff', [1]);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('identify {\n        diff = (1)\n        sdiff = (1)\n}'));

            ts = tse.TSeries(tse.qq(1963,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Quarterly Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {tse.x13.ls(tse.qq(1971,1))});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.identify(spec, 'diff', [0 1], 'sdiff', [0 1], 'maxlag', 16);
            tse.x13.estimate(spec);
            tse.x13.check(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('identify {\n        diff = (0, 1)\n        sdiff = (0, 1)\n        maxlag = 16\n}'), ...
                'estimate { }', ...
                'check { }' ...
            });
        end

        function metadata_writing(tc)
            ts = tse.TSeries(tse.mm(1964,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Retail Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', 'td', 'aictest', {'td','easter'});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.check(spec);
            tse.x13.outlier(spec, 'types', 'all');
            tse.x13.metadata(spec, {'analyst', 'John J. J. Smith'});
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('regression {\n        variables = td\n        aictest = (td easter)\n}'), ...
                'check { }', ...
                sprintf('outlier {\n        types = all\n}'), ...
                sprintf('metadata {\n        key = "analyst"\n        value = "John J. J. Smith"\n}') ...
            });

            ts = tse.TSeries(tse.mm(1964,1), (1:150)');
            xts = tse.x13.series(ts, 'title', "Monthly Retail Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'td', tse.x13.ao(tse.mm(1967,6)), tse.x13.ls(tse.mm(1971,6)), tse.x13.easter(8)});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.check(spec);
            tse.x13.metadata(spec, {'analyst', 'John J. J. Smith'; 'spec.updated', 'October 31, 2006'});
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                'metadata {', ...
                'key = (', ...
                '"analyst"', ...
                '"spec.updated"', ...
                'value = (', ...
                '"John J. J. Smith"', ...
                '"October 31, 2006"' ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'td', tse.x13.ao(tse.mm(1967,6)), tse.x13.ls(tse.mm(1971,6)), tse.x13.easter(15)});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.check(spec);
            tse.x13.x11(spec);
            tse.x13.metadata(spec, {'analyst', 'John J. J. Smith'; 'spec.final', 'November 10, 2006'; 'key3', 'AO caused by strike, LS caused by survey change'});
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                'x11 { }', ...
                '"spec.final"', ...
                '"key3"', ...
                '"November 10, 2006"', ...
                '"AO caused by strike, LS caused by survey change"' ...
            });

            tc.verifyError(@() tse.x13.metadata({repmat('a', 1, 133), 'success!'}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.metadata({'key', repmat('a', 1, 133)}), 'tseries:noMatch');
            many = arrayfun(@(i) {sprintf('hello%d', i), ' '}, 1:21, 'UniformOutput', false);
            tc.verifyError(@() tse.x13.metadata(vertcat(many{:})), 'tseries:noMatch');
        end

        function outlier_writing(tc)
            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.outlier(spec, 'lsrun', 5, 'types', {'ao','ls'});
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('arima {\n        model = (0 1 1)(0 1 1)12\n}'), ...
                sprintf('outlier {\n        lsrun = 5\n        types = (ao ls)\n}') ...
            });

            ts = tse.TSeries(tse.mm(1976,1), (1:250)');
            xts = tse.x13.series(ts, 'title', "Monthly Sales", 'span', tse.mm(1980,1):tse.mm(1992,12));
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {tse.x13.ls(tse.mm(1981,6)), tse.x13.ls(tse.mm(1990,11))});
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.estimate(spec);
            tse.x13.outlier(spec, 'types', 'ao', 'method', 'addall', 'critical', 4.0);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('outlier {\n        critical = 4.0\n        method = addall\n        types = ao\n}'));

            spec = tse.x13.newspec(xts);
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.estimate(spec);
            tse.x13.outlier(spec, 'types', 'ls', 'critical', 3.0, 'lsrun', 2, 'span', tse.mm(1987,1):tse.mm(1988,12));
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('outlier {\n        critical = 3.0\n        lsrun = 2\n        span = (1987.jan, 1988.dec)\n        types = ls\n}'));

            spec = tse.x13.newspec(xts);
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.estimate(spec);
            tse.x13.outlier(spec, 'critical', [3.0 4.5 4.0], 'types', 'all');
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('outlier {\n        critical = (3.0, 4.5, 4.0)\n        types = all\n}'));

            tc.verifyError(@() tse.x13.outlier('critical', [3.1 4.0 6.0 7.0]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.outlier('lsrun', -1), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.outlier('lsrun', 6), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.outlier('almost', -0.1), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.outlier('tcrate', -0.1), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.outlier('tcrate', 1.1), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.outlier('span', tse.x13.Span([], tse.x13.M(11))), 'tseries:noMatch');
        end

        function pickmdl_writing(tc)
            models = [ ...
                tse.x13.ArimaModel(0,1,1,0,1,1, 'default', true), ...
                tse.x13.ArimaModel(0,1,2,0,1,1), ...
                tse.x13.ArimaModel(2,1,0,0,1,1), ...
                tse.x13.ArimaModel(0,2,2,0,1,1), ...
                tse.x13.ArimaModel(2,1,2,0,1,1) ...
            ];

            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'td','seasonal'});
            tse.x13.pickmdl(spec, models, 'mode', 'fcst');
            tse.x13.estimate(spec);
            tse.x13.x11(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('regression {\n        variables = (td seasonal)\n}'), ...
                'pickmdl {', ...
                'models = (0 1 1)(0 1 1) *', ...
                '(0 1 2)(0 1 1) X', ...
                '(2 1 0)(0 1 1) X', ...
                '(0 2 2)(0 1 1) X', ...
                '(2 1 2)(0 1 1)', ...
                'mode = fcst', ...
                'estimate { }', ...
                'x11 { }' ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', 'td');
            tse.x13.pickmdl(spec, models, 'mode', 'fcst', 'method', 'first', 'fcstlim', 20, 'qlim', 10, 'overdiff', 0.99, 'identify', 'all');
            tse.x13.estimate(spec);
            tse.x13.outlier(spec);
            tse.x13.x11(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                'fcstlim = 20', ...
                'identify = all', ...
                'method = first', ...
                'mode = fcst', ...
                'overdiff = 0.99', ...
                'qlim = 10', ...
                'outlier { }' ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', 'td');
            tse.x13.pickmdl(spec, models, 'mode', 'fcst', 'outofsample', true);
            tse.x13.estimate(spec);
            tse.x13.outlier(spec);
            tse.x13.x11(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('pickmdl {\n        models = (0 1 1)(0 1 1) *\n(0 1 2)(0 1 1) X\n(2 1 0)(0 1 1) X\n(0 2 2)(0 1 1) X\n(2 1 2)(0 1 1)\n        mode = fcst\n        outofsample = yes\n}'));

            tc.verifyError(@() tse.x13.pickmdl('bcstlim', -1), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.pickmdl('bcstlim', 101), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.pickmdl('fcstlim', -1), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.pickmdl('fcstlim', 101), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.pickmdl('qlim', -1), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.pickmdl('qlim', 101), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.pickmdl('overdiff', 1.1), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.pickmdl('overdiff', 0.8), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.pickmdl(models(1)), 'tseries:noMatch');
            models2 = [ ...
                tse.x13.ArimaModel(0,1,1,0,1,1, 'default', true), ...
                tse.x13.ArimaModel(0,1,2,0,1,1, 'default', true) ...
            ];
            tc.verifyError(@() tse.x13.pickmdl(models2), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.pickmdl(), 'tseries:noMatch');
        end

        function regression_writing(tc)
            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Sales");

            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const','seasonal'});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1));
            tse.x13.estimate(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('regression {\n        variables = (const seasonal)\n}'), ...
                sprintf('arima {\n        model = (0 1 1)\n}'), ...
                'estimate { }' ...
            });

            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Irregular Component of Monthly Sales"));
            tse.x13.regression(spec, 'variables', {'const', tse.x13.sincos([4 5])});
            tse.x13.estimate(spec);
            tse.x13.spectrum(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('regression {\n        variables = (const sincos[4 5])\n}'), ...
                'estimate { }', ...
                'spectrum { }' ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', {'td', tse.x13.easter(8), tse.x13.labor(10), tse.x13.thank(3)});
            tse.x13.identify(spec, 'diff', [0 1], 'sdiff', [0 1]);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('regression {\n        variables = (td easter[8] labor[10] thank[3])\n}'), ...
                sprintf('identify {\n        diff = (0, 1)\n        sdiff = (0, 1)\n}') ...
            });

            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', {'tdnolpyear', 'lom', tse.x13.easter(8), tse.x13.labor(10), tse.x13.thank(3)});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.estimate(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('regression {\n        variables = (tdnolpyear lom easter[8] labor[10] thank[3])\n}'));

            ts = tse.TSeries(tse.mm(1990,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Retail inventory of food products");
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {tse.x13.tdstock1coef(31), tse.x13.easterstock(8)}, 'aictest', {'td','easter'});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.x11(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('regression {\n        variables = (tdstock1coef[31] easterstock[8])\n        aictest = (td easter)\n}'));

            mv = tse.MVTSeries(tse.qq(1990,1), ["tls"], (51:200)');
            ts = tse.TSeries(tse.qq(1990,1), (1:150)');
            xts = tse.x13.series(ts, 'title', "Quarterly Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'variables', {tse.x13.ao(tse.qq(2007,1)), tse.x13.qi(tse.qq(2005,2), tse.qq(2005,4)), tse.x13.ao(tse.qq(1998,1)), 'td'}, 'user', 'tls', 'data', mv);
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.estimate(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                'user = tls', ...
                'start = 1990.1', ...
                'variables = (ao2007.1 qi2005.2-2005.4 ao1998.1 td)' ...
            });

            ts = tse.TSeries(tse.mm(1970,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Riverflow");
            spec = tse.x13.newspec(xts);
            mv = tse.MVTSeries(tse.mm(1960,1), ["temp","precip"], [(1.0:0.1:18)', (0.0:0.2:34)']);
            tse.x13.regression(spec, 'variables', {'seasonal','const'}, 'data', mv);
            tse.x13.arima(spec, tse.x13.ArimaModel(3,0,0,0,0,0));
            tse.x13.estimate(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                'start = 1960.jan', ...
                'user = (temp precip)', ...
                'variables = (seasonal const)', ...
                sprintf('arima {\n        model = (3 0 0)(0 0 0)\n}') ...
            });

            tc.verifyError(@() tse.x13.regression('aicdiff', [1.0 1.5], 'pvaictest', 1.5), 'tseries:noMatch');
            mv3 = tse.MVTSeries(tse.mm(1991,1), ["beforecny","betweencny","aftercny"], [(1.0:0.1:17.1)', (0.0:0.2:32.2)', (3.0:0.3:51.3)']);
            tc.verifyError(@() tse.x13.regression('data', mv3, 'usertype', {'holiday','holiday'}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('data', mv3, 'usertype', {'holiday','holiday','somethingelse'}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('data', mv3, 'usertype', 'somethingelse'), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('variables', {tse.x13.tdstock(-1)}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('variables', {tse.x13.tdstock(32)}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('variables', {tse.x13.easter(-1)}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('variables', {tse.x13.easter(26)}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('variables', {tse.x13.labor(-1)}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('variables', {tse.x13.labor(26)}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('variables', {tse.x13.thank(-9)}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('variables', {tse.x13.thank(18)}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('variables', {tse.x13.sceaster(0)}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('variables', {tse.x13.sceaster(25)}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('variables', {tse.x13.easterstock(0)}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.regression('variables', {tse.x13.easterstock(26)}), 'tseries:noMatch');
            tc.verifyWarnContains(@() tse.x13.regression('variables', {tse.x13.aos(tse.qq(1996,1), tse.qq(1997,4)), tse.x13.aos(tse.qq(1997,1), tse.qq(1998,4))}), 'overlapping aos');
            tc.verifyWarnContains(@() tse.x13.regression('variables', {tse.x13.lss(tse.qq(1996,1), tse.qq(1997,4)), tse.x13.lss(tse.qq(1997,1), tse.qq(1998,4))}), 'overlapping lss');
            tc.verifyError(@() tse.x13.regression('aictest', 'something'), 'tseries:noMatch');
        end

        function seats_writing(tc)
            ts = tse.TSeries(tse.mm(1987,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Exports of truck parts");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'auto');
            tse.x13.regression(spec, 'aictest', 'td');
            tse.x13.automdl(spec);
            tse.x13.outlier(spec, 'types', {'ao','ls','tc'});
            tse.x13.forecast(spec, 'maxlead', 36);
            tse.x13.seats(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                'automdl { }', ...
                sprintf('forecast {\n        maxlead = 36\n}'), ...
                sprintf('outlier {\n        types = (ao ls tc)\n}'), ...
                sprintf('seats {\n        out = 0\n}') ...
            });

            ts = tse.TSeries(tse.qq(1990,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Exports of truck parts");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'aictest', 'td');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.forecast(spec, 'maxlead', 12);
            tse.x13.seats(spec, 'finite', true);
            tse.x13.history(spec, 'estimates', {'sadj','trend'});
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, { ...
                sprintf('seats {\n        finite = yes\n        out = 0\n}'), ...
                sprintf('history {\n        estimates = (sadj trend)\n}') ...
            });

            ts = tse.TSeries(tse.mm(1995,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Model based adjustment of Bimonthly exports");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.regression(spec, 'aictest', 'td');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.outlier(spec, 'types', {'ao','ls','tc'});
            tse.x13.forecast(spec, 'maxlead', 18);
            tse.x13.seats(spec, 'tabtables', {'xo','n','s','p'}, 'printphtrf', true);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('seats {\n        out = 0\n        printphtrf = 1\n        tabtables = "xo,n,s,p"\n}'));

            tc.verifyError(@() tse.x13.seats('epsiv', -0.1), 'tseries:noMatch');
            tc.verifyWarnContains(@() tse.x13.seats('hpcycle', false, 'hplan', 2), 'Hodrick-Prescott filters will be used');
            tc.verifyWarnContains(@() tse.x13.seats('print', 'all'), 'The print=all option is not available for the seats spec.');
        end

        function series_writing(tc)
            ts = tse.TSeries(tse.mm(1967,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "A simple example");
            spec = tse.x13.newspec(xts);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, {'start = 1967.jan', 'title = "A simple example"', 'data = (1 2 3 4 5 6 7 8 9 10'});
            tc.verifyClass(xts.frequencyof(), 'tse.Monthly');

            ts = tse.TSeries(tse.qq(1940,1), (1:250)');
            xts = tse.x13.series(ts, 'span', tse.qq(1964,1):tse.qq(1990,4));
            spec = tse.x13.newspec(xts);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, {'period = 4', 'span = (1964.1, 1990.4)', 'start = 1940.1'});

            ts2 = tse.TSeries(tse.qq(1940,1), (1:250)');
            ts2 = ts2(tse.qq(1940,1):tse.qq(1990,4));
            xts = tse.x13.series(ts2, 'start', tse.qq(1964,1));
            spec = tse.x13.newspec(xts);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, {'data = (97 98 99 100', 'period = 4', 'start = 1964.1'});

            ts = tse.TSeries(tse.mm(1976,1), (1.0:0.1:25.0)');
            xts = tse.x13.series(ts, 'span', tse.firstdate(ts):tse.mm(1992,12), 'comptype', 'add', 'decimals', 2);
            spec = tse.x13.newspec(xts);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, {'comptype = add', 'decimals = 2', 'span = (1976.jan, 1992.dec)', 'start = 1976.jan'});

            tc.verifyWarnContains(@() tse.x13.series(ts, 'span', tse.firstdate(ts):tse.mm(1992,12), 'comptype', 'add', 'decimals', 2, ...
                'title', "This is a very long title that will most certainly trigger the warning about the title being truncated"), ...
                'Series title truncated to 79 characters');
            tc.verifyWarnContains(@() tse.x13.series(ts, 'span', tse.firstdate(ts):tse.mm(1992,12), 'comptype', 'add', 'decimals', 2, ...
                'name', "This is a very long name that will most certainly trigger the warning about the title being truncated"), ...
                'Series name truncated to 64 characters');
            tc.verifyError(@() tse.x13.series(ts, 'divpower', 11), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.series(ts, 'span', tse.mm(1960,1):tse.mm(1996,1)), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.series(ts, 'span', tse.mm(1976,1):tse.mm(1997,1)), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.series(ts, 'span', tse.x13.Span([], tse.x13.M(1))), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.series(ts, 'span', tse.x13.Span(tse.mm(1975,3))), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.series(ts, 'span', tse.x13.Span([], tse.mm(1997,3))), 'tseries:noMatch');
        end

        function slidingspans_writing(tc)
            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Tourist");
            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec, 'seasonalma', 's3x9');
            tse.x13.slidingspans(spec);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, {'seasonalma = s3x9', 'slidingspans { }'});

            ts = tse.TSeries(tse.qq(1967,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Quarterly stock prices on NASDAQ");
            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec, 'seasonalma', {'s3x9','s3x9','s3x5','s3x5'}, 'trendma', 7, 'mode', 'logadd');
            tse.x13.slidingspans(spec, 'cutseas', 5.0, 'cutchng', 5.0);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('slidingspans {\n        cutchng = 5.0\n        cutseas = 5.0\n}'));

            ts = tse.TSeries(tse.mm(1980,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Number of employed machinists - X-11");
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const','td',tse.x13.rp(tse.mm(1982,5),tse.mm(1982,10))});
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,2,0,1,1));
            tse.x13.outlier(spec);
            tse.x13.estimate(spec);
            tse.x13.check(spec);
            tse.x13.forecast(spec);
            tse.x13.x11(spec, 'mode', 'add');
            tse.x13.slidingspans(spec, 'outlier', 'keep', 'length', 144);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, {'outlier { }', 'estimate { }', 'check { }', 'forecast { }', 'mode = add', 'length = 144', 'outlier = keep'});

            tc.verifyWarnContains(@() tse.x13.slidingspans('fixmdl', true, 'fixreg', {'td'}), 'fixreg will be ignored');
        end

        function spectrum_writing(tc)
            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Klaatu");
            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec, 'seasonalma', 's3x9', 'trendma', 23);
            tse.x13.spectrum(spec, 'logqs', true);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('spectrum {\n        logqs = yes\n}'));

            ts = tse.TSeries(tse.mm(1967,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Spectrum analysis of Building Permits Series");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log');
            tse.x13.spectrum(spec, 'start', tse.mm(1987,1));
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('spectrum {\n        start = 1987.jan\n}'));

            xts = tse.x13.series(ts, 'title', "TOTAL ONE-FAMILY Housing Starts");
            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec, 'seasonalma', {'s3x9'}, 'title', "Composite adj. of 1-Family housing starts");
            tse.x13.spectrum(spec, 'type', 'periodgram');
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('spectrum {\n        type = periodgram\n}'));
        end

        function transform_writing(tc)
            ts = tse.TSeries(tse.mm(1967,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Transform example");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'data', tse.TSeries(tse.mm(1967,1), (0.1:0.1:5.0)'), 'mode', 'ratio', 'adjust', 'lom');
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, {'adjust = lom', 'mode = ratio', 'start = 1967.jan'});

            ts = tse.TSeries(tse.qq(1997,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Transform example");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'constant', 45.0, 'func', 'auto');
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('transform {\n        function = auto\n        constant = 45.0\n}'));

            ts = tse.TSeries(tse.mm(1980,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Total U.S. Retail Sales --- Current Dollars");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'log', 'data', tse.TSeries(tse.mm(1970,1), (0.1:0.1:17.0)'), 'title', "Consumer Price Index", 'type', 'temporary');
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, {'function = log', 'start = 1970.jan', 'title = "Consumer Price Index"', 'type = temporary'});

            ts = tse.TSeries(tse.qq(1901,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Annual Rainfall");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'power', .3333);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('transform {\n        power = 0.3333\n}'));

            ts = tse.TSeries(tse.mm(1978,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Total U.K. Retail Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'auto', 'aicdiff', 0.0);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('transform {\n        aicdiff = 0.0\n        function = auto\n}'));

            tc.verifyError(@() tse.x13.transform('power', 0.0, 'func', 'log'), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.transform('func', 'sqrt', 'adjust', 'lpyear'), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.transform('power', 0.33, 'adjust', 'lpyear'), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.transform('mode', {'ratio','diff'}), 'tseries:noMatch');
            tc.verifyWarnContains(@() tse.x13.transform('title', "This is a very long title that will most certainly trigger the warning about the title being truncated"), 'Transform title truncated to 79 characters');
            tc.verifyError(@() tse.x13.transform('type', 'permanent'), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.transform('type', {'temporary','permanent'}, 'data', tse.TSeries(tse.qq(1991,1), rand(100,1))), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.transform('type', {'temporary','permanent'}, 'data', tse.MVTSeries(tse.qq(1991,1), ["S1"], rand(100,1))), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.transform('type', 'temporary', 'data', tse.MVTSeries(tse.qq(1991,1), ["s1","s2"], randn(100,2))), 'tseries:noMatch');
        end

        function x11_writing(tc)
            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Klaatu");
            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec);
            tse.x13.spectrum(spec, 'logqs', true);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, 'x11 { }');

            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec, 'seasonalma', 's3x9', 'trendma', 23);
            tse.x13.x11regression(spec, 'variables', 'td', 'aictest', 'td');
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, {'seasonalma = s3x9', 'trendma = 23', sprintf('x11regression {\n        variables = td\n        aictest = td\n}')});

            ts = tse.TSeries(tse.qq(1967,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Quarterly housing starts");
            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec, 'seasonalma', {'s3x3','s3x3','s3x5','s3x5'}, 'trendma', 7);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('x11 {\n        seasonalma = (s3x3 s3x3 s3x5 s3x5)\n        trendma = 7\n}'));

            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'func', 'auto', 'aicdiff', 0.0);
            tse.x13.x11(spec, 'calendarsigma', 'select', 'sigmavec', [tse.x13.M(1), tse.x13.M(2), tse.x13.M(12)]);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('x11 {\n        calendarsigma = select\n        sigmavec = (jan, feb, dec)\n}'));

            tc.verifyError(@() tse.x13.x11('trendma', 8), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.x11('trendma', 1), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.x11('trendma', 102), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.x11('calendarsigma', 'all', 'sigmavec', [tse.x13.M(1), tse.x13.M(3)]), 'tseries:noMatch');
        end

        function x11regression_writing(tc)
            ts = tse.TSeries(tse.mm(1976,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Westus");
            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec);
            tse.x13.x11regression(spec, 'variables', 'td');
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('x11regression {\n        variables = td\n}'));

            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec);
            tse.x13.x11regression(spec, 'variables', 'td', 'aictest', {'td','easter'});
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('x11regression {\n        variables = td\n        aictest = (td easter)\n}'));

            ts = tse.TSeries(tse.mm(1985,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Ukclothes");
            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec);
            mv = tse.MVTSeries(tse.mm(1980,1), ["easter1","easter2"], [(0.1:0.1:11)', (11:-0.1:0.1)']);
            tse.x13.x11regression(spec, 'variables', 'td', 'usertype', 'holiday', 'critical', 4.0, 'data', mv);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, {'critical = 4.0', 'start = 1980.jan', 'user = (easter1 easter2)', 'usertype = holiday', 'variables = td'});

            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec);
            tse.x13.x11regression(spec, 'variables', 'td', 'tdprior', [1.4 1.4 1.4 1.4 1.4 0.0 0.0]);
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyContains(s, sprintf('x11regression {\n        tdprior = (1.4, 1.4, 1.4, 1.4, 1.4, 0.0, 0.0)\n        variables = td\n}'));

            ts = tse.TSeries(tse.mm(1967,1), (1:150)');
            xts = tse.x13.series(ts, 'title', "Motor Home Sales", 'span', tse.x13.Span(tse.mm(1972,1)));
            spec = tse.x13.newspec(xts);
            tse.x13.x11(spec, 'seasonalma', 'x11default', 'sigmalim', [1.8 2.8], 'appendfcst', true);
            tse.x13.x11regression(spec, 'variables', {tse.x13.td(tse.mm(1990,1)), tse.x13.easter(8), tse.x13.labor(10), tse.x13.thank(10)});
            s = tse.x13.x13write(spec, 'test', true);
            tc.verifyAllContains(s, {'appendfcst = yes', 'seasonalma = x11default', 'sigmalim = (1.8, 2.8)', 'variables = (td/1990.jan/ easter[8] labor[10] thank[10])'});

            tc.verifyError(@() tse.x13.x11regression('aictest', 'td', 'variables', 'tdstock'), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.x11regression('aictest', 'something'), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.x11regression('aictest', {'something','td'}), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.x11regression('sigma', -0.1), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.x11regression('tdprior', [0.7 0.7 0.7 1.05 1.4 1.4 1.05 1.8]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.x11regression('tdprior', [0.7 0.7 0.7 1.05 1.4 1.4]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.x11regression('tdprior', [0.7 0.7 -0.7 1.05 1.4 1.4 1.05]), 'tseries:noMatch');
            tc.verifyError(@() tse.x13.x11regression('outlierspan', tse.x13.Span([], tse.x13.M(2))), 'tseries:noMatch');
        end

        function span_writing(tc)
            % open-start span with a fuzzy monthly end -> (, 0.dec)
            ts = tse.TSeries(tse.mm(1967,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Housing Starts in the Midwest", ...
                'comptype', 'add', 'modelspan', tse.x13.Span([], tse.x13.M(12)));
            spec = tse.x13.newspec(xts);
            s = tse.x13.x13write(spec, 'test', true);
            expected = sprintf(['series {\n        comptype = add\n        data = (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 \n', ...
                '                42 43 44 45 46 47 48 49 50)\n        modelspan = (, 0.dec)\n        start = 1967.jan\n        title = "Housing Starts in the Midwest"\n}']);
            tc.verifyContains(s, expected);

            % a span passed as a range equals the same span wrapped in Span()
            ts = tse.TSeries(tse.mm(1976,1), (1:250)');
            xts1 = tse.x13.series(ts, 'title', "Monthly Sales", ...
                'span', tse.mm(1980,1):tse.mm(1992,12));
            spec1 = tse.x13.newspec(xts1);
            s1 = tse.x13.x13write(spec1, 'test', true);
            xts2 = tse.x13.series(ts, 'title', "Monthly Sales", ...
                'span', tse.x13.Span(tse.mm(1980,1):tse.mm(1992,12)));
            spec2 = tse.x13.newspec(xts2);
            s2 = tse.x13.x13write(spec2, 'test', true);
            tc.verifyEqual(s1, s2);
        end

        function validation_errors(tc)
            wr = @(spec) tse.x13.x13write(spec, 'test', true);

            % arima together with pickmdl / automdl
            ts = tse.TSeries(tse.mm(1985,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Unit Auto Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1));
            tse.x13.pickmdl(spec, [tse.x13.ArimaModel(0,1,1,0,1,1,'default',true), tse.x13.ArimaModel(0,1,2,0,1,1)]);
            tc.verifyError(@() wr(spec), 'tseries:noMatch');
            spec = tse.x13.newspec(xts);
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1));
            tse.x13.automdl(spec);
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % automdl together with pickmdl
            spec = tse.x13.newspec(xts);
            tse.x13.automdl(spec);
            tse.x13.pickmdl(spec, [tse.x13.ArimaModel(0,1,1,0,1,1,'default',true), tse.x13.ArimaModel(0,1,2,0,1,1)]);
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % regression variables together with estimate file
            spec = tse.x13.newspec(xts);
            tse.x13.estimate(spec, 'file', "/some/file");
            tse.x13.regression(spec, 'variables', {'td'});
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % history fstep > forecast maxlead
            ts = tse.TSeries(tse.mm(1969,7), (1:150)');
            xts = tse.x13.series(ts, 'title', "Exports of leather goods");
            spec = tse.x13.newspec(xts);
            tse.x13.history(spec, 'estimates', 'fcst', 'fstep', [4 2], 'start', tse.mm(1975,1));
            tse.x13.forecast(spec, 'maxlead', 2);
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % invalid aictest with td variable
            ts = tse.TSeries(tse.mm(1985,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Unit Auto Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const','td'}, 'aictest', 'lom');
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % invalid mixing of td and tdstock
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const','td','tdstock'});
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % stock regressor on flow data; flow regressor on stock data
            xtsF = tse.x13.series(ts, 'title', "Unit Auto Sales", 'type', 'flow');
            spec = tse.x13.newspec(xtsF);
            tse.x13.regression(spec, 'variables', {'const','tdstock'});
            tc.verifyError(@() wr(spec), 'tseries:noMatch');
            xtsS = tse.x13.series(ts, 'title', "Unit Auto Sales", 'type', 'stock');
            spec = tse.x13.newspec(xtsS);
            tse.x13.regression(spec, 'variables', {'const','td'});
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % various regressors on non-monthly/non-quarterly (yearly) data
            tsY = tse.TSeries(tse.yy(1986), (1:50)');
            xtsY = tse.x13.series(tsY, 'title', "Unit Auto Sales");
            for v = {'td','tdnolpyear','td1coef','td1nolpyear','lpyear','lom','loq', ...
                     'tdstock','tdstock1coef','labor','sceaster'}
                spec = tse.x13.newspec(xtsY);
                tse.x13.regression(spec, 'variables', {'const', v{1}});
                tc.verifyError(@() wr(spec), 'tseries:noMatch');
            end

            % mutually excluded regressor combinations (monthly data)
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const','td','tdnolpyear'});
            tc.verifyError(@() wr(spec), 'tseries:noMatch');
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const','lpyear','td'});
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % dated regressors outside the series range
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const', tse.x13.ao(tse.mm(1984,2))});
            tc.verifyError(@() wr(spec), 'tseries:noMatch');
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const', tse.x13.ls(tse.mm(1985,1))});
            tc.verifyError(@() wr(spec), 'tseries:noMatch');
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const', tse.x13.rp(tse.mm(1984,2), tse.mm(1986,3))});
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % transform adjust with td regressor
            spec = tse.x13.newspec(xts);
            tse.x13.regression(spec, 'variables', {'const','td'});
            tse.x13.transform(spec, 'adjust', 'loq');
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % insufficient data in regression spec
            ts = tse.TSeries(tse.mm(1970,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Monthly Riverflow");
            spec = tse.x13.newspec(xts);
            mv = tse.MVTSeries(tse.mm(1960,1), ["temp","precip"], [(1.0:0.1:18)', (0.0:0.2:34)']);
            tse.x13.regression(spec, 'variables', {'seasonal','const'}, 'data', mv);
            tse.x13.forecast(spec, 'maxlead', 2);
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % slidingspans too short / too long
            ts = tse.TSeries(tse.mm(1980,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Machinists");
            spec = tse.x13.newspec(xts);
            tse.x13.slidingspans(spec, 'outlier', 'keep', 'length', 30);
            tc.verifyError(@() wr(spec), 'tseries:noMatch');
            spec = tse.x13.newspec(xts);
            tse.x13.slidingspans(spec, 'outlier', 'keep', 'length', 240);
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % transform.adjust with x11.mode=add
            ts = tse.TSeries(tse.mm(1967,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Transform example");
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec, 'data', tse.TSeries(tse.mm(1967,1), (0.1:0.1:5.0)'), 'mode', 'ratio', 'adjust', 'lom');
            tse.x13.x11(spec, 'mode', 'add');
            tc.verifyError(@() wr(spec), 'tseries:noMatch');

            % default transform + default x11 conflict
            spec = tse.x13.newspec(xts);
            tse.x13.transform(spec);
            tse.x13.x11(spec);
            tc.verifyError(@() wr(spec), 'tseries:noMatch');
        end

        function validation_warns_without_error(tc)
            % These cases warn but must not error (the spec is still written).
            ts = tse.TSeries(tse.mm(1993,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Exports");
            spec = tse.x13.newspec(xts);
            tse.x13.seats(spec, 'hpcycle', true);
            tc.verifyClass(tc.noWarnWrite(spec), 'char');

            ts = tse.TSeries(tse.qq(1988,1), (1:50)');
            xts = tse.x13.series(ts, 'title', "Retail Sales");
            spec = tse.x13.newspec(xts);
            tse.x13.spectrum(spec, 'logqs', true, 'qcheck', true);
            tc.verifyClass(tc.noWarnWrite(spec), 'char');
        end

    end
end

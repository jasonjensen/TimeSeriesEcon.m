classdef TestX13Spec < matlab.unittest.TestCase
    %TESTX13SPEC  Ports a subset of test_x13spec.jl: building specs and the
    %   spec-string serialiser (x13write in test mode), plus the cross-spec
    %   validation errors.  These run without the x13as binary.
    %
    %   Remaining per-spec writing testsets from test_x13spec.jl (series,
    %   transform, regression, automdl, check, estimate, force, forecast,
    %   history, identify, metadata, outlier, pickmdl, seats, slidingspans,
    %   spectrum, x11, x11regression detailed examples) are not yet ported.

    methods (Access = private)
        function verifyContains(tc, s, expected)
            tc.verifyTrue(contains(s, expected), ...
                sprintf('Expected spec string to contain:\n%s\n\nGot:\n%s', expected, s));
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

            x6 = tse.x13.ArimaSpec(3,2);
            tc.verifyEqual(x6.p, 3); tc.verifyEqual(x6.d, 2); tc.verifyEqual(x6.q, 0);
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

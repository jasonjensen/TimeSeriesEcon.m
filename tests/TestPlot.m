classdef TestPlot < matlab.unittest.TestCase
    %TESTPLOT  Smoke tests for the TSeries/MVTSeries plot methods.
    %   These check structure (data length, handle types, number of lines),
    %   not visual appearance.

    properties
        fig
    end

    methods (TestMethodSetup)
        function openFig(tc)
            tc.fig = figure('Visible', 'off');
        end
    end

    methods (TestMethodTeardown)
        function closeFig(tc)
            if ishandle(tc.fig), close(tc.fig); end
        end
    end

    methods (Test)
        function plot_tseries_yp(tc)
            t = tse.TSeries(tse.qq(2020,1), (1:8)');
            h = plot(t);
            tc.verifyTrue(isgraphics(h));
            tc.verifyEqual(numel(h.XData), 8);
            tc.verifyEqual(h.YData(:), (1:8)', 'AbsTol', 1e-12);
        end

        function plot_tseries_mit_loc(tc)
            t = tse.TSeries(tse.qq(2020,1), (1:8)');
            hL = plot(t, 'mit_loc', 'left');
            hR = plot(t, 'mit_loc', 'right');
            % right offset shifts x by 1/N (=0.25 for quarterly)
            tc.verifyEqual(hR.XData(1) - hL.XData(1), 0.25, 'AbsTol', 1e-12);
        end

        function plot_tseries_trange(tc)
            t = tse.TSeries(tse.qq(2020,1), (1:8)');
            h = plot(t, 'trange', tse.MITRange(tse.qq(2020,2), tse.qq(2020,4)));
            tc.verifyEqual(numel(h.XData), 3);
        end

        function plot_tseries_daily(tc)
            t = tse.TSeries(tse.day('2021-01-01'), (1:10)');
            h = plot(t);
            tc.verifyTrue(isa(h.XData, 'datetime'));
            tc.verifyEqual(numel(h.XData), 10);
        end

        function plot_mvts(tc)
            x = tse.MVTSeries(tse.qq(2020,1), {'a','b','c'}, reshape(1:24, 8, 3));
            h = plot(x);
            tc.verifyEqual(numel(h), 3);
        end

        function plot_mvts_vars(tc)
            x = tse.MVTSeries(tse.qq(2020,1), {'a','b','c'}, reshape(1:24, 8, 3));
            h = plot(x, 'vars', {'a','c'});
            tc.verifyEqual(numel(h), 2);
        end
    end
end

classdef X13spec < handle
%X13SPEC  A complete X13-ARIMA-SEATS specification: a series plus any subspecs.
%
%   This is a handle object so that the mutating constructors (e.g.
%   tse.x13.arima(spec, model)) update it in place, mirroring the Julia spec!
%   functions.  Build one with tse.x13.newspec.
%
%   See also: tse.x13.newspec, tse.x13.run, tse.x13.x13write.
    properties
        series = tse.x13.X13default()
        arima = tse.x13.X13default()
        estimate = tse.x13.X13default()
        transform = tse.x13.X13default()
        regression = tse.x13.X13default()
        automdl = tse.x13.X13default()
        x11 = tse.x13.X13default()
        x11regression = tse.x13.X13default()
        check = tse.x13.X13default()
        forecast = tse.x13.X13default()
        force = tse.x13.X13default()
        pickmdl = tse.x13.X13default()
        history = tse.x13.X13default()
        metadata = tse.x13.X13default()
        identify = tse.x13.X13default()
        outlier = tse.x13.X13default()
        seats = tse.x13.X13default()
        slidingspans = tse.x13.X13default()
        spectrum = tse.x13.X13default()
        folder = tse.x13.X13default()
        string = tse.x13.X13default()
    end
    properties (Hidden)
        freq = tse.x13.X13default()
    end
    methods
        function F = frequencyof(obj)
            if ~tse.x13.isdefault(obj.freq)
                F = obj.freq;
            elseif ~tse.x13.isdefault(obj.series)
                F = tse.frequencyof(obj.series.data);
            else
                error('tseries:noMatch', 'X13spec has no frequency.');
            end
        end
    end
end

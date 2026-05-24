function spec = newspec(first, varargin)
%NEWSPEC  Create an X13 specification.
%
%   spec = tse.x13.newspec(ts)            from a TSeries (builds the series spec)
%   spec = tse.x13.newspec(xts)           from an existing X13series
%   spec = tse.x13.newspec(tse.Quarterly())   empty spec for a given frequency
%
%   Any subspec may be supplied as a name-value pair, e.g.
%   tse.x13.newspec(ts, 'arima', tse.x13.arima(tse.x13.ArimaModel(0,1,1))).
%
%   See also: tse.x13.series, tse.x13.run.
    spec = tse.x13.X13spec();
    names = {'series','arima','estimate','transform','regression','automdl', ...
        'x11','x11regression','check','forecast','force','pickmdl','history', ...
        'metadata','identify','outlier','seats','slidingspans','spectrum', ...
        'folder','string'};

    if isa(first, 'tse.TSeries')
        spec.series = tse.x13.series(first);
        spec.freq = tse.frequencyof(first);
    elseif isa(first, 'tse.x13.X13series')
        spec.series = first;
        spec.freq = tse.frequencyof(first.data);
    elseif isa(first, 'tse.Frequency') || ischar(first) || isstring(first) || isa(first, 'meta.class')
        spec.freq = tse.sanitize_frequency(first);
    else
        error('tseries:noMatch', ...
            'newspec requires a TSeries, an X13series, or a frequency.');
    end

    D = tse.x13.X13default();
    d = struct();
    for k = 1:numel(names), d.(names{k}) = D; end
    o = tse.x13.getopts(d, varargin);
    for k = 1:numel(names)
        nm = names{k};
        if ~tse.x13.isdefault(o.(nm))
            spec.(nm) = o.(nm);
        end
    end
end

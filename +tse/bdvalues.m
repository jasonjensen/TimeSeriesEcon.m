function out = bdvalues(t, varargin)
%BDVALUES  Values of a BDaily series on the days a holidays map keeps.
%
%   v = tse.bdvalues(t)
%   v = tse.bdvalues(t, 'holidays_map', map)
%
%   t is a BDaily tse.TSeries or tse.MVTSeries.  Without a map this is
%   t's values; with one (a BDaily logical TSeries covering t's range,
%   true = business day) it keeps only the rows the map marks true, as a
%   column vector for a TSeries and a matrix for an MVTSeries.
%
%   See also: tse.cleanedvalues, tse.set_holidays_map.

    p = inputParser;
    addParameter(p, 'holidays_map', []);
    parse(p, varargin{:});
    if ~(isa(t, 'tse.TSeries') || isa(t, 'tse.MVTSeries')) ...
            || ~isa(tse.frequencyof(t), 'tse.BDaily')
        error('tseries:noMatch', 'bdvalues requires a BDaily TSeries or MVTSeries.');
    end
    if isempty(p.Results.holidays_map)
        out = tse.cleanedvalues(t);
    else
        out = tse.cleanedvalues(t, 'holidays_map', p.Results.holidays_map);
    end
end

function ts = trim_series(F_to, ts, varargin)
%TRIM_SERIES  Trim a series to the F_to-aligned subrange of its range.
%
%   y = tse.trim_series(F_to, ts, 'direction', d)
%
%   Mirrors TimeSeriesEcon.jl trim_series:
%       ts[fconvert(F_from, fconvert(F_to, rangeof(ts), trim=direction))]

    p = inputParser;
    addParameter(p, 'direction', 'both');
    parse(p, varargin{:});
    direction = char(p.Results.direction);

    if ~isa(F_to, 'tse.Frequency')
        F_to = tse.sanitize_frequency(F_to);
    end
    F_from = int2freq(ts.frequency);
    outRange = tse.fconvert(F_to, rangeof(ts), 'trim', direction);
    backRange = tse.fconvert(F_from, outRange);
    ts = ts(backRange);
end

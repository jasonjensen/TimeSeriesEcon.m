function rng = rangeof(x, varargin)
%RANGEOF  The stored range of a TSeries (or just the range itself).
%
%   rangeof(x)            full range
%   rangeof(x,'drop',k)   drop k periods (positive = from start,
%                         negative = from end)

    p = inputParser;
    addParameter(p, 'drop', 0, @(v) isnumeric(v) && isscalar(v));
    parse(p, varargin{:});
    drop = p.Results.drop;

    if isa(x, 'tseries.TSeries')
        rng = tseries.MITRange(x.firstdate, tseries.lastdate(x));
    elseif isa(x, 'tseries.MITRange')
        rng = x;
    elseif isa(x, 'tseries.MIT')
        rng = tseries.MITRange(x, x);
    else
        error('tseries:noMatch', 'rangeof not defined for %s.', class(x));
    end

    if drop > 0
        rng = tseries.MITRange(rng.startMIT + drop, rng.stopMIT, rng.stepSize);
    elseif drop < 0
        rng = tseries.MITRange(rng.startMIT, rng.stopMIT + drop, rng.stepSize);
    end
end

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

    if isa(x, 'tse.TSeries') || isa(x, 'tse.MVTSeries')
        rng = tse.MITRange(x.firstdate, tse.lastdate(x));
    elseif isa(x, 'tse.MITRange')
        rng = x;
    elseif isa(x, 'tse.MIT')
        rng = tse.MITRange(x, x);
    else
        error('tseries:noMatch', 'rangeof not defined for %s.', class(x));
    end

    if drop > 0
        rng = tse.MITRange(rng.startMIT + drop, rng.stepSize, rng.stopMIT);
    elseif drop < 0
        rng = tse.MITRange(rng.startMIT, rng.stepSize, rng.stopMIT + drop);
    end
end

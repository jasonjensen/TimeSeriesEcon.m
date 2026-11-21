function m = firstdate(x, varargin)
%FIRSTDATE  First MIT of a TSeries (or MITRange).
    if isa(x, 'tse.TSeries') || isa(x, 'tse.MVTSeries')
        m = x.firstdate;
    elseif isa(x, 'tse.NDTSeries')
        m = x.firstdate(varargin{:});
    elseif isa(x, 'tse.MITRange')
        m = x.startMIT;
    else
        error('tseries:noMatch', 'firstdate not defined for %s.', class(x));
    end
end

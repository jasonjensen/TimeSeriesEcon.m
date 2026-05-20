function m = firstdate(x)
%FIRSTDATE  First MIT of a TSeries (or MITRange).
    if isa(x, 'tseries.TSeries')
        m = x.firstdate;
    elseif isa(x, 'tseries.MITRange')
        m = x.startMIT;
    else
        error('tseries:noMatch', 'firstdate not defined for %s.', class(x));
    end
end

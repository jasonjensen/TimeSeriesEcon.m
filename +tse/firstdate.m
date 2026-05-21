function m = firstdate(x)
%FIRSTDATE  First MIT of a TSeries (or MITRange).
    if isa(x, 'tse.TSeries')
        m = x.firstdate;
    elseif isa(x, 'tse.MITRange')
        m = x.startMIT;
    else
        error('tseries:noMatch', 'firstdate not defined for %s.', class(x));
    end
end

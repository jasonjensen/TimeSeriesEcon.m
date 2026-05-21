function m = lastdate(x)
%LASTDATE  Last MIT of a TSeries (or MITRange).
    if isa(x, 'tse.TSeries') || isa(x, 'tse.MVTSeries')
        n = length(x.values);
        if n == 0
            m = x.firstdate - 1;
        else
            m = x.firstdate + (int64(n) - 1);
        end
    elseif isa(x, 'tse.MITRange')
        m = last(x);
    else
        error('tseries:noMatch', 'lastdate not defined for %s.', class(x));
    end
end

function r = strip_ts(t)
%STRIP_TS  Remove leading and trailing not-a-number observations from t.
%
%   r = tse.strip_ts(t)
%
%   Equivalent to Julia's `strip(t)`.  `strip` is not used as a name
%   because MATLAB has a built-in `strip()` for strings.

    if ~isa(t, 'tse.TSeries')
        error('tseries:noMatch', 'strip_ts requires a TSeries.');
    end
    n = length(t.values);
    if n == 0
        r = t;
        return
    end
    iStart = 1;
    while iStart <= n && tse.istypenan(t.values(iStart))
        iStart = iStart + 1;
    end
    iEnd = n;
    while iEnd >= iStart && tse.istypenan(t.values(iEnd))
        iEnd = iEnd - 1;
    end
    if iStart > iEnd
        r = tse.TSeries(t.firstdate);
        return
    end
    newFD = t.firstdate + (iStart - 1);
    r = tse.TSeries(newFD, t.values(iStart:iEnd));
end

function F = sanitize_frequency(x)
%SANITIZE_FREQUENCY Return the canonical concrete instance for the given
%frequency type or class name.  Defaults: Quarterly->Quarterly(3),
%Yearly->Yearly(12), HalfYearly->HalfYearly(6), Weekly->Weekly(7).

    if isa(x, 'tse.Frequency')
        F = x;
        return
    end
    if ischar(x) || isstring(x)
        x = char(x);
    elseif isa(x, 'meta.class')
        x = x.Name;
    else
        error('tseries:noMatch', 'sanitize_frequency expects a Frequency, class name, or meta.class.');
    end
    x = regexprep(x, '^tseries\.', '');
    switch x
        case 'Yearly',    F = tse.Yearly(12);
        case 'HalfYearly', F = tse.HalfYearly(6);
        case 'Quarterly', F = tse.Quarterly(3);
        case 'Monthly',   F = tse.Monthly();
        case 'Weekly',    F = tse.Weekly(7);
        case 'Daily',     F = tse.Daily();
        case 'BDaily',    F = tse.BDaily();
        case 'Unit',      F = tse.Unit();
        otherwise
            error('tseries:noMatch', 'Unknown frequency: %s', x);
    end
end

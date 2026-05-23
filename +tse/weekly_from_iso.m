function m = weekly_from_iso(y, p)
%WEEKLY_FROM_ISO Construct a Weekly{7} MIT from ISO year and week number.

    if p > 53 || p < 1
        error('tseries:noMatch', ...
            'The provided period must be between 1 and 53 (inclusive).');
    end
    firstDay = datetime(double(y), 1, 1);
    woffd = week(firstDay, 'iso-weekofyear');
    if woffd ~= 1
        padd = 1;
    else
        padd = 0;
    end
    proposed = firstDay + days((p - 1 + padd) * 7);
    m = tse.week(proposed);
    d = mitToDate(m);
    if year(d) ~= y && week(d, 'iso-weekofyear') < 52
        error('tseries:noMatch', 'The year %d does not have a week %d.', y, p);
    end
end

function m = from_date(d)
%FROM_DATE  Convert an IRIS date double into a tse.MIT.
%
%   m = tse.iris.from_date(qq(2020, 1))
%
%   Calls IRIS's public dat2ypf to decode year/period/frequency, then builds
%   the matching tse.MIT via tse.MIT(F, y, p) / tse.day / tse.weekly_from_iso.
%   Requires IRIS on the path; see tse.iris.isavailable.
    if ~tse.iris.isavailable()
        error('tseries:noMatch', ...
            'IRIS Toolbox is not on the path; cannot convert IRIS dates.');
    end
    if ~isnumeric(d) || ~isscalar(d)
        error('tseries:noMatch', 'from_date expects a scalar numeric IRIS date.');
    end
    if isnan(d)
        error('tseries:noMatch', 'Cannot convert NaN to a tse.MIT.');
    end
    [y, p, freq] = dat2ypf(double(d));
    switch double(freq)
        case 0                       % Unit / integer dates
            m = tse.MIT(int32(11), int64(p));
        case 1                       % Yearly
            m = tse.MIT(tse.Yearly(12), double(y), 1);
        case 2                       % Half-yearly
            m = tse.MIT(tse.HalfYearly(6), double(y), double(p));
        case 4                       % Quarterly
            m = tse.MIT(tse.Quarterly(3), double(y), double(p));
        case 12                      % Monthly
            m = tse.MIT(tse.Monthly(), double(y), double(p));
        case 52                      % Weekly (IRIS uses ISO weeks)
            m = tse.weekly_from_iso(double(y), double(p));
        case 365                     % Daily: p is day-of-year
            dt = datetime(double(y), 1, 1) + days(double(p) - 1);
            m = tse.day(dt);
        otherwise
            error('tseries:noMatch', ...
                'Unsupported IRIS frequency code %g for date %g.', double(freq), double(d));
    end
end

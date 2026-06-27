function m = from_date(d)
%FROM_DATE  Convert a 1-element Dynare dates object into a tse.MIT.
%
%   m = tse.dynare.from_date(dates('2020Q1'))
%
%   The .freq field of the dates object selects the tse.Frequency; for
%   year-period frequencies (A/B/Q/M/W) the .time matrix supplies year and
%   subperiod, while daily uses the canonical YYYY-MM-DD string form.
%   Requires Dynare on the path; see tse.dynare.isavailable.
    if ~tse.dynare.isavailable()
        error('tseries:noMatch', ...
            'Dynare is not on the path; cannot read a Dynare dates object.');
    end
    if ~isa(d, 'dates')
        error('tseries:noMatch', 'from_date expects a Dynare dates object.');
    end
    if double(d.ndat) ~= 1
        error('tseries:noMatch', ...
            'from_date expects a 1-element dates (got %d); use from_range for multi-element.', ...
            double(d.ndat));
    end
    freq = double(d.freq);
    switch freq
        case 1
            m = tse.MIT(tse.Yearly(12), double(d.time(1, 1)), 1);
        case 2
            m = tse.MIT(tse.HalfYearly(6), double(d.time(1, 1)), double(d.time(1, 2)));
        case 4
            m = tse.MIT(tse.Quarterly(3), double(d.time(1, 1)), double(d.time(1, 2)));
        case 12
            m = tse.MIT(tse.Monthly(), double(d.time(1, 1)), double(d.time(1, 2)));
        case 52
            m = tse.weekly_from_iso(double(d.time(1, 1)), double(d.time(1, 2)));
        case 365
            s = char(d);                              % e.g. '2020-01-15'
            dt = datetime(s, 'InputFormat', 'yyyy-MM-dd');
            m = tse.day(dt);
        otherwise
            error('tseries:noMatch', 'Unsupported Dynare frequency code: %g.', freq);
    end
end

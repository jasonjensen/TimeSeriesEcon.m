function d = to_date(m)
%TO_DATE  Convert a tse.MIT into an IRIS date double.
%
%   d = tse.iris.to_date(tse.qq(2020, 1))
%
%   Dispatches on the MIT's frequency to the matching IRIS constructor
%   (yy/hh/qq/mm/ww/dd/zz).  Errors on BDaily since IRIS 2015 has no
%   business-day frequency.  Requires IRIS on the path.
    if ~tse.iris.isavailable()
        error('tseries:noMatch', ...
            'IRIS Toolbox is not on the path; cannot build IRIS dates.');
    end
    if ~isa(m, 'tse.MIT')
        error('tseries:noMatch', 'to_date expects a tse.MIT.');
    end
    F = tse.frequencyof(m);
    if isa(F, 'tse.Yearly')
        if F.endPeriod ~= 12
            warning('IRIS yearly is calendar-year only; endMonth %d will be ignored.', ...
                F.endPeriod);
        end
        yp = tse.mit2yp(m);
        d = yy(double(yp(1)));
    elseif isa(F, 'tse.HalfYearly')
        yp = tse.mit2yp(m);
        d = hh(double(yp(1)), double(yp(2)));
    elseif isa(F, 'tse.Quarterly')
        yp = tse.mit2yp(m);
        d = qq(double(yp(1)), double(yp(2)));
    elseif isa(F, 'tse.Monthly')
        yp = tse.mit2yp(m);
        d = mm(double(yp(1)), double(yp(2)));
    elseif isa(F, 'tse.Weekly')
        yp = tse.mit2yp(m);
        d = ww(double(yp(1)), double(yp(2)));
    elseif isa(F, 'tse.Daily')
        dt = tse.toDate(m);
        d = dd(year(dt), month(dt), day(dt));
    elseif isa(F, 'tse.BDaily')
        error('tseries:noMatch', ...
            ['IRIS Toolbox 2015 has no business-day frequency.  Convert ', ...
             'this BDaily MIT to a Daily MIT (e.g. via tse.day) first.']);
    elseif isa(F, 'tse.Unit')
        d = zz(double(m));
    else
        error('tseries:noMatch', 'Unsupported frequency: %s', class(F));
    end
end

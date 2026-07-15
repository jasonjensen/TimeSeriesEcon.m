function d = to_date(m)
%TO_DATE  Convert a tse.MIT into a 1-element Dynare dates object.
%
%   d = tse.dynare.to_date(tse.qq(2020, 1))
%
%   Dispatches on the MIT's frequency to the matching dates constructor:
%   dates('A',y), dates('H',y,p), dates('Q',y,p), dates('M',y,p),
%   dates('W',y,p), dates('D',y,m,d).  Errors on BDaily and Unit.
    if ~tse.dynare.isavailable()
        error('tseries:noMatch', ...
            'Dynare is not on the path; cannot build a Dynare dates object.');
    end
    if ~isa(m, 'tse.MIT')
        error('tseries:noMatch', 'to_date expects a tse.MIT.');
    end
    F = tse.frequencyof(m);
    if isa(F, 'tse.Yearly')
        if F.endPeriod ~= 12
            warning('Dynare yearly is calendar-year only; endMonth %d will be ignored.', ...
                F.endPeriod);
        end
        yp = tse.mit2yp(m);
        d = dates('A', double(yp(1)));
    elseif isa(F, 'tse.HalfYearly')
        yp = tse.mit2yp(m);
        d = dates('H', double(yp(1)), double(yp(2)));
    elseif isa(F, 'tse.Quarterly')
        yp = tse.mit2yp(m);
        d = dates('Q', double(yp(1)), double(yp(2)));
    elseif isa(F, 'tse.Monthly')
        yp = tse.mit2yp(m);
        d = dates('M', double(yp(1)), double(yp(2)));
    elseif isa(F, 'tse.Weekly')
        yp = tse.mit2yp(m);
        d = dates('W', double(yp(1)), double(yp(2)));
    elseif isa(F, 'tse.Daily')
        dt = tse.toDate(m);
        d = dates('D', year(dt), month(dt), day(dt));
    elseif isa(F, 'tse.BDaily')
        error('tseries:noMatch', ...
            ['Dynare has no business-day frequency.  Convert this BDaily ', ...
             'MIT to a Daily MIT (e.g. via tse.day) first.']);
    elseif isa(F, 'tse.Unit')
        error('tseries:noMatch', ...
            'Dynare has no frequency-less date class; tse.Unit cannot be sent across.');
    else
        error('tseries:noMatch', 'Unsupported frequency: %s', class(F));
    end
end

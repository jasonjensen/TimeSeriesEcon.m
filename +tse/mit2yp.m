function yp = mit2yp(m)
%MIT2YP  Recover (year, period) from an MIT.  Returns a 1x2 int64 row.
%
%   For YPFrequency{N}: standard quotient/remainder of the raw integer,
%   adjusted so that period is in 1..N.  For Daily, period is the
%   day-of-year (1..366).  For BDaily, period is the business-day number
%   within the year.  For Weekly, period is the ISO-style week number.
%   Other calendar frequencies error.

    if ~isa(m, 'tse.MIT')
        error('tseries:noMatch', 'mit2yp expects an MIT.');
    end
    F = int2freq(m.frequency);
    if isa(F, 'tse.YPFrequency')
        N = int64(F.PeriodsPerYear);
        [y, p] = idivremFix(m.value, N);
        if p < 0
            y = y - 1;
            p = p + N + 1;
        else
            p = p + 1;
        end
        yp = [int64(y), int64(p)];
    elseif isa(F, 'tse.Daily')
        d = mitToDate(m);
        yp = [int64(year(d)), int64(day(d, 'dayofyear'))];
    elseif isa(F, 'tse.BDaily')
        d = mitToDate(m);
        y = year(d);
        firstDayOfYear = datetime(y, 1, 1);
        fd_dow = weekday(firstDayOfYear);     % 1=Sun..7=Sat
        fd_iso = mod(fd_dow - 2, 7) + 1;      % 1=Mon..7=Sun
        if fd_iso > 5
            daysAdj = 8 - fd_iso;
        else
            daysAdj = 0;
        end
        firstBDay = firstDayOfYear + days(daysAdj);
        firstBDayMIT = tse.bday(firstBDay);
        diff = m.value - firstBDayMIT.value + 1;
        yp = [int64(y), int64(diff)];
    elseif isa(F, 'tse.Weekly')
        d = mitToDate(m);
        yp = [int64(year(d)), int64(ceil(day(d, 'dayofyear') / 7))];
    else
        error('tseries:noMatch', ...
            'Value of type MIT{%s} cannot be represented as (year, period).', class(F));
    end
end

function [q, r] = idivremFix(a, b)
    q = idivide(a, b, 'fix');
    r = a - q * b;
end

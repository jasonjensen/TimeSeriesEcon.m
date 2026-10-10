function yw = iso_week(m)
%ISO_WEEK  ISO 8601 [year, week] of a Weekly MIT, as IRIS's ww(y, w) expects.
%
%   yw = tse.iris.iso_week(tse.week('2021-01-10'))   % -> [2021 1]
%
%   The week is the ISO week (Monday to Sunday) that contains the MIT's last
%   day, which for tse.Weekly(7) is the same week.  This differs from
%   tse.mit2yp, whose week number is ceil(day-of-year / 7) as in Julia and
%   is off by one from ISO in about half of all years.  The inverse for
%   Weekly(7) is tse.weekly_from_iso.  Does not need IRIS.
    if ~isa(m, 'tse.MIT') || ~isa(tse.frequencyof(m), 'tse.Weekly')
        error('tseries:noMatch', 'iso_week expects a Weekly MIT.');
    end
    d = tse.toDate(m);
    isodow = mod(weekday(d) - 2, 7) + 1;      % Mon = 1 ... Sun = 7
    thu = d + days(4 - isodow);               % ISO weeks belong to their Thursday's year
    yw = [year(thu), ceil(day(thu, 'dayofyear') / 7)];
end

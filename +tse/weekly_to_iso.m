function yw = weekly_to_iso(m)
%WEEKLY_TO_ISO  ISO 8601 [year, week] of a Weekly MIT.
%
%   yw = tse.weekly_to_iso(tse.week('2021-01-10'))   % -> [2021 1]
%
%   The inverse of tse.weekly_from_iso: for a Weekly{7} MIT,
%   tse.weekly_from_iso(yw(1), yw(2)) == m.  A week ending on another day
%   gives the ISO week (Monday to Sunday) that contains its last day.
%
%   This is not tse.mit2yp, whose week number is ceil(day-of-year / 7) of
%   the week's last day (Julia's _mit2yp); the two differ in about half of
%   all years.  Julia has no public inverse of weekly_from_iso; this one is
%   consistent with Julia's weekly_from_iso, which uses Dates.week (ISO).
    if ~isa(m, 'tse.MIT') || ~isa(tse.frequencyof(m), 'tse.Weekly')
        error('tseries:noMatch', 'weekly_to_iso expects a Weekly MIT.');
    end
    d = tse.toDate(m);
    isodow = mod(weekday(d) - 2, 7) + 1;      % Mon = 1 ... Sun = 7
    thu = d + days(4 - isodow);               % an ISO week belongs to its Thursday's year
    yw = [year(thu), ceil(day(thu, 'dayofyear') / 7)];
end

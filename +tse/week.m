function m = week(d, endDay)
%WEEK  Construct a Weekly MIT from a date or date string.
%
%   m = tse.week('2022-01-01')          % endDay = 7 (Sunday, the default)
%   m = tse.week('2022-01-01', 6)       % Saturday-end weeks
%
%   endDay (1=Mon .. 7=Sun) is the day on which each week ends.
%   See also: tse.weekly_from_iso, tse.day, tse.bday.

    if nargin < 2 || isempty(endDay)
        endDay = 7;
    end
    if ischar(d) || isstring(d)
        d = datetime(string(d), 'InputFormat', 'yyyy-MM-dd');
    end
    if ~isa(d, 'datetime')
        error('tseries:noMatch', 'week(d) requires datetime, char, or string input.');
    end
    v = dateToWeeklyValue(d, endDay);
    m = tse.MIT(tse.Weekly(endDay), v);
end

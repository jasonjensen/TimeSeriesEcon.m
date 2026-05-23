function m = week(d, endDay)
%WEEKLY  Construct an MIT{Weekly{endDay}} from a date or date string.
%
%   m = tse.week('2022-01-01')          % endDay=7 (Sunday)
%   m = tse.week('2022-01-01', 6)       % Saturday-end weeks

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

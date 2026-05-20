function m = weekly(d, endDay)
%WEEKLY  Construct an MIT{Weekly{endDay}} from a date or date string.
%
%   m = tseries.weekly('2022-01-01')          % endDay=7 (Sunday)
%   m = tseries.weekly('2022-01-01', 6)       % Saturday-end weeks

    if nargin < 2 || isempty(endDay)
        endDay = 7;
    end
    if ischar(d) || isstring(d)
        d = datetime(string(d), 'InputFormat', 'yyyy-MM-dd');
    end
    if ~isa(d, 'datetime')
        error('tseries:noMatch', 'weekly(d) requires datetime, char, or string input.');
    end
    v = dateToWeeklyValue(d, endDay);
    m = tseries.MIT(tseries.Weekly(endDay), v);
end

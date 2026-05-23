function v = dateToWeeklyValue(d, endDay)
%DATETOWEEKLYVALUE Map a datetime to MIT{Weekly{endDay}} raw integer value.
%
%   Mirrors Julia's week(d, end_day) which computes
%       ceil(value(d) / 7) + max(0, min(1, dayofweek(d) - end_day))
%   where value(d) = days since 0000-12-31.

    if nargin < 2
        endDay = 7;
    end
    epoch = datetime(0, 12, 31);
    valD  = floor(days(d - epoch));
    base  = ceil(valD / 7);
    dow_m = weekday(d);             % 1=Sun .. 7=Sat
    dow_i = mod(dow_m - 2, 7) + 1;  % 1=Mon .. 7=Sun (ISO)
    extra = max(0, min(1, dow_i - endDay));
    v = int64(base + extra);
end

function v = dateToBDailyValue(d)
%DATETOBDAILYVALUE Map a datetime to MIT{BDaily} raw integer value.
%
%   We mirror Julia: walk the proleptic Gregorian date offset from the same
%   epoch (0000-12-31), then subtract two days for every completed week
%   between the epoch and d.

    epoch = datetime(0, 12, 31);
    raw = int64(floor(days(d - epoch)));
    [numWeekends, rem_] = idivremFix(raw, int64(7));
    if rem_ < 0
        numWeekends = numWeekends - 1;
        rem_ = rem_ + 7;
    end
    adjustment = int64(0);
    if rem_ == 0       % Sunday
        adjustment = int64(-1);  % representable; caller should not normally pass a weekend
    elseif rem_ == 6   % Saturday
        adjustment = int64(1);
    end
    v = raw - int64(numWeekends * 2 + adjustment);
end

function [q, r] = idivremFix(a, b)
% truncate-toward-zero integer division returning (q, r) with r same sign as a.
    q = idivide(a, b, 'fix');
    r = a - q * b;
end

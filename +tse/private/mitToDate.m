function d = mitToDate(m, ref)
%MITTODATE Convert a calendar-frequency MIT to a MATLAB datetime.
%
%   d = mitToDate(m)          last day of the MIT period
%   d = mitToDate(m, 'begin') first day of the MIT period

    if nargin < 2
        ref = 'end';
    end
    F = int2freq(m.frequency);
    epoch = datetime(0, 12, 31);
    val = double(m.value);
    if isa(F, 'tse.Daily')
        d = epoch + days(val);
    elseif isa(F, 'tse.BDaily')
        % invert dateToBDailyValue: add back 2 days per completed week
        d = epoch + days(val + 2 * floor((val - 1) / 5));
    elseif isa(F, 'tse.Weekly')
        endDay = F.endPeriod;
        if strcmp(ref, 'begin')
            d = epoch + days(val * 7 - 6) - days(7 - endDay);
        else
            d = epoch + days(val * 7) - days(7 - endDay);
        end
    elseif isa(F, 'tse.Monthly')
        [y, mo] = idivremFix(val, 12);
        if strcmp(ref, 'begin')
            d = datetime(y, 1, 1) + calmonths(mo);
        else
            d = datetime(y, 1, 1) + calmonths(mo + 1) - days(1);
        end
    elseif isa(F, 'tse.Quarterly')
        endMonth = F.endPeriod;
        [y, q] = idivremFix(val, 4);
        if strcmp(ref, 'begin')
            d = datetime(y, 1, 1) + calmonths(q * 3 - (3 - endMonth));
        else
            d = datetime(y, 1, 1) + calmonths((q + 1) * 3 - (3 - endMonth)) - days(1);
        end
    elseif isa(F, 'tse.HalfYearly')
        endMonth = F.endPeriod;
        [y, h] = idivremFix(val, 2);
        if strcmp(ref, 'begin')
            d = datetime(y, 1, 1) + calmonths(h * 6 - (6 - endMonth));
        else
            d = datetime(y, 1, 1) + calmonths((h + 1) * 6 - (6 - endMonth)) - days(1);
        end
    elseif isa(F, 'tse.Yearly')
        endMonth = F.endPeriod;
        if strcmp(ref, 'begin')
            d = datetime(val, 1, 1) - calmonths(12 - endMonth);
        else
            d = datetime(val + 1, 1, 1) - calmonths(12 - endMonth) - days(1);
        end
    else
        error('tseries:noMatch', 'Cannot convert MIT{%s} to date.', class(F));
    end
end

function [q, r] = idivremFix(a, b)
% Truncate-toward-zero integer division returning (q, r) with r same sign as a.
    q = fix(a / b);
    r = a - q * b;
end

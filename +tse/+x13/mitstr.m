function s = mitstr(m)
%MITSTR  Format an MIT the way X13-ARIMA-SEATS expects it in a spec file.
%
%   Quarterly/other  ->  "year.period"      (e.g. 1967.1)
%   Monthly          ->  "year.monthname"   (e.g. 1987.jan)
%   Yearly           ->  "year"             (e.g. 1950)
%
%   See also: tse.x13.rangestr.
    yp = tse.mit2yp(m);
    y = double(yp(1));
    p = double(yp(2));
    if tse.isyearly(m)
        s = sprintf('%d', y);
    elseif tse.ismonthly(m)
        months = {'jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'};
        s = sprintf('%d.%s', y, months{p});
    else
        s = sprintf('%d.%d', y, p);
    end
end

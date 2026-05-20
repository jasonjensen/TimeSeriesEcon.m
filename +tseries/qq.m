function m = qq(y, p)
%QQ Construct an MIT{Quarterly} from year and period (1..4).
%
%   m = tseries.qq(2020, 1)   % 2020Q1
    m = tseries.MIT(tseries.Quarterly(), y, p);
end

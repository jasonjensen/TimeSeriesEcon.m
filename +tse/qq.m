function m = qq(y, p)
%QQ Construct an MIT{Quarterly} from year and period (1..4).
%
%   m = tse.qq(2020, 1)   % 2020Q1
    m = tse.MIT(tse.Quarterly(), y, p);
end

function m = qq(y, p)
%QQ Construct an MIT{Quarterly} from year and period (1..4).
%
%   m = tse.qq(2020, 1)   % 2020Q1
%
%   Fast path: skips Frequency-object construction and goes straight to
%   the int-coded MIT constructor.  Quarterly{end_month=3} = code 67.
    m = tse.MIT(int32(67), int64(4 * y + p - 1));
end

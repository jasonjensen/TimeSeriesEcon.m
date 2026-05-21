function m = mm(y, p)
%MM Construct an MIT{Monthly} from year and period (1..12).
%
%   Fast path: Monthly = code 32, value = 12*y + p - 1.
    m = tse.MIT(int32(32), int64(12 * y + p - 1));
end

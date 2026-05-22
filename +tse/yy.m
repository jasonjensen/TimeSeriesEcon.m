function m = yy(y, p)
%YY Construct an MIT{Yearly} from year (and optional period, default 1).
%
%   Fast path: Yearly{end_month=12} = code 256, value = y + p - 1.
    if nargin < 2
        p = 1;
    end
    m = tse.MIT(int32(268), int64(y + p - 1));
end

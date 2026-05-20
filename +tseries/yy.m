function m = yy(y, p)
%YY Construct an MIT{Yearly} from year (and optional period, default 1).
    if nargin < 2
        p = 1;
    end
    m = tseries.MIT(tseries.Yearly(), y, p);
end

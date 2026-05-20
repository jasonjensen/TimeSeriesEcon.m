function p = period(m)
%PERIOD  Period component of an MIT.  See also: tseries.mit2yp.
    yp = tseries.mit2yp(m);
    p = double(yp(2));
end

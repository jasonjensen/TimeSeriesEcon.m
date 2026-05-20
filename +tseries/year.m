function y = year(m)
%YEAR  Year component of an MIT.  See also: tseries.mit2yp.
    yp = tseries.mit2yp(m);
    y = double(yp(1));
end

function p = period(m)
%PERIOD  Period component of an MIT.  See also: tse.mit2yp.
    yp = tse.mit2yp(m);
    p = double(yp(2));
end

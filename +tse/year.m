function y = year(m)
%YEAR  Year component of an MIT.  See also: tse.mit2yp.
    yp = tse.mit2yp(m);
    y = double(yp(1));
end

function c = M(n)
%M  Fuzzy monthly period marker, e.g. tse.x13.M(12) is December.
%
%   See also: tse.x13.FPConst, tse.x13.Q, tse.x13.H, tse.x13.Span.
    c = tse.x13.FPConst('monthly', n);
end

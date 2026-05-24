function c = Q(n)
%Q  Fuzzy quarterly period marker, e.g. tse.x13.Q(3) is the third quarter.
%
%   See also: tse.x13.FPConst, tse.x13.M, tse.x13.H, tse.x13.Span.
    c = tse.x13.FPConst('quarterly', n);
end

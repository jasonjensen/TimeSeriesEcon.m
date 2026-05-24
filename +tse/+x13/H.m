function c = H(n)
%H  Fuzzy half-yearly period marker, e.g. tse.x13.H(2) is the second half.
%
%   See also: tse.x13.FPConst, tse.x13.M, tse.x13.Q, tse.x13.Span.
    c = tse.x13.FPConst('halfyearly', n);
end

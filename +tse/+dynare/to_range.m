function d = to_range(r)
%TO_RANGE  Convert a tse.MITRange into a contiguous Dynare dates object.
%
%   d = tse.dynare.to_range(tse.qq(2020,1):tse.qq(2024,4))
%
%   Builds the endpoints and uses Dynare's colon to fill in between.
    if ~tse.dynare.isavailable()
        error('tseries:noMatch', 'Dynare is not on the path.');
    end
    if ~isa(r, 'tse.MITRange')
        error('tseries:noMatch', 'to_range expects a tse.MITRange.');
    end
    a = tse.dynare.to_date(first(r));
    b = tse.dynare.to_date(last(r));
    d = a:b;
end

function d = to_range(r)
%TO_RANGE  Convert a tse.MITRange into an IRIS date vector.
%
%   d = tse.iris.to_range(tse.qq(2020,1):tse.qq(2024,4))
%
%   Builds the IRIS endpoints and uses IRIS's colon to fill in between.
    if ~isa(r, 'tse.MITRange')
        error('tseries:noMatch', 'to_range expects a tse.MITRange.');
    end
    a = tse.iris.to_date(first(r));
    b = tse.iris.to_date(last(r));
    d = a:b;
end

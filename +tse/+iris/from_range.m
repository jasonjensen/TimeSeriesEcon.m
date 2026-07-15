function r = from_range(d)
%FROM_RANGE  Convert an IRIS date vector into a tse.MITRange.
%
%   r = tse.iris.from_range(qq(2020,1):qq(2024,4))
%
%   Uses the endpoints; an empty vector is rejected because no frequency
%   can be inferred without at least one date.
    if isempty(d)
        error('tseries:noMatch', ...
            'from_range cannot infer a frequency from an empty date vector.');
    end
    d = double(d(:));
    a = tse.iris.from_date(d(1));
    b = tse.iris.from_date(d(end));
    r = a:b;
end

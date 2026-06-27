function r = from_range(d)
%FROM_RANGE  Convert a multi-element Dynare dates object into a tse.MITRange.
%
%   r = tse.dynare.from_range(dates('2020Q1'):dates('2024Q4'))
%
%   Uses the first and last elements; an empty dates is rejected because no
%   frequency can be inferred without at least one date.  Non-contiguous
%   dates are accepted but the returned MITRange spans the endpoints (any
%   gaps inside the original are filled).
    if ~tse.dynare.isavailable()
        error('tseries:noMatch', 'Dynare is not on the path.');
    end
    if ~isa(d, 'dates')
        error('tseries:noMatch', 'from_range expects a Dynare dates object.');
    end
    if double(d.ndat) == 0
        error('tseries:noMatch', ...
            'from_range cannot infer a frequency from an empty dates object.');
    end
    a = tse.dynare.from_date(d(1));
    b = tse.dynare.from_date(d(end));
    r = a:b;
end

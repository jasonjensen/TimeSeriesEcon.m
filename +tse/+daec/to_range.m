function ax = to_range(r)
%TO_RANGE  Convert a tse.MITRange into a DataEcon range DEAxis.
%
%   ax = tse.daec.to_range(tse.qq(2020,1):tse.qq(2024,4))
%
%   The axis carries the frequency, length, and starting date value; because
%   tse.MIT and DEDate share the same encoding, no date conversion is needed
%   beyond building the starting DEDate.
    if ~tse.daec.isavailable()
        error('tseries:noMatch', ...
            'DataEcon MATLAB classes are not on the path; cannot build a DEAxis.');
    end
    if ~isa(r, 'tse.MITRange')
        error('tseries:noMatch', 'to_range expects a tse.MITRange.');
    end
    ax = DEAxis(tse.daec.to_date(first(r)), length(r));
end

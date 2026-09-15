function d = to_date(m)
%TO_DATE  Convert a tse.MIT into a DataEcon DEDate.
%
%   d = tse.daec.to_date(tse.qq(2020, 3))
%
%   tse.MIT and DEDate share the same integer encoding: the frequency codes
%   from +tse/private/freq2int.m ARE DataEcon's frequency_t enum, and both
%   store the date as the same rata die / period-since-epoch integer
%   (0001-01-01 => 1, the Julia Dates.Date convention libdaec targets).  So
%   the conversion is the identity on (frequency, value); no libdaec date
%   round-trip is needed, and it works even when the native library is not
%   loaded.
    if ~tse.daec.isavailable()
        error('tseries:noMatch', ...
            'DataEcon MATLAB classes are not on the path; cannot build a DEDate.');
    end
    if ~isa(m, 'tse.MIT')
        error('tseries:noMatch', 'to_date expects a tse.MIT.');
    end
    d = DEDate(double(m.frequency), int64(m.value));
end

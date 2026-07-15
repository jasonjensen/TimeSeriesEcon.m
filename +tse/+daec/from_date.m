function m = from_date(d)
%FROM_DATE  Convert a DataEcon DEDate into a tse.MIT.
%
%   m = tse.daec.from_date(d)
%
%   Inverse of tse.daec.to_date; see that file for why the mapping is the
%   identity on (frequency, value).  Needs only the DEDate class on the path,
%   not the native libdaec library.
    if ~isa(d, 'DEDate')
        error('tseries:noMatch', 'from_date expects a DEDate.');
    end
    m = tse.MIT(int32(d.frequency), int64(d.value));
end

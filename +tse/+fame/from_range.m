function rng = from_range(r)
%FROM_RANGE  Convert a FAME range descriptor into a tse.MITRange.
%
%   rng = tse.fame.from_range(r)
%
%   r is a struct with fields freq (FAME frequency code), first and last
%   (FAME date indices), as produced by tse.fame.to_range or read from a
%   FAME object's range.  Requires the CHLI to be loaded.
%
%   See also: tse.fame.to_range, tse.fame.from_date.
    if ~isstruct(r) || ~all(isfield(r, {'freq', 'first', 'last'}))
        error('tseries:noMatch', ...
            'from_range expects a struct with fields freq, first, and last.');
    end
    a = tse.fame.from_date(r.freq, r.first);
    b = tse.fame.from_date(r.freq, r.last);
    rng = a:b;
end

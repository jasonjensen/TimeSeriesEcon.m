function m = from_date(freq, idx)
%FROM_DATE  Convert a FAME date index into a tse.MIT.
%
%   m = tse.fame.from_date(freq, idx)
%
%   A bare FAME date index carries no frequency, so `freq` must be supplied
%   -- either a FAME frequency code (numeric) or a tse.Frequency.  Inverse of
%   tse.fame.to_date; see the private fame_offset helper for the mapping.
%   Requires the CHLI to be loaded except for Unit frequency.
%
%   See also: tse.fame.to_date, tse.fame.from_range.
    if isa(freq, 'tse.Frequency')
        F = freq;
    elseif isnumeric(freq) && isscalar(freq)
        F = tse.fame.freq_from_fame(freq);
    else
        error('tseries:noMatch', ...
            'from_date expects a FAME frequency code or a tse.Frequency as its first argument.');
    end
    if isa(F, 'tse.Unit')
        m = tse.MIT(tse.Unit(), int64(idx));
        return
    end
    tse.fame.CHLI.ensure_loaded();
    m = tse.MIT(F, int64(idx) - fame_offset(F));
end

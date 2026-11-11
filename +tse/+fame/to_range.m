function r = to_range(rng)
%TO_RANGE  Convert a tse.MITRange into a FAME range descriptor.
%
%   r = tse.fame.to_range(tse.qq(2020,1):tse.qq(2024,4))
%
%   Returns a struct with fields:
%       freq   - the FAME frequency code
%       first  - FAME date index of the first period
%       last   - FAME date index of the last period
%
%   This is the descriptor the series read/write layer feeds to the CHLI
%   range calls.  Requires the CHLI to be loaded.
%
%   See also: tse.fame.from_range, tse.fame.to_date.
    if ~isa(rng, 'tse.MITRange')
        error('tseries:noMatch', 'to_range expects a tse.MITRange.');
    end
    F = tse.frequencyof(rng);
    r = struct('freq',  tse.fame.freq_to_fame(F), ...
               'first', tse.fame.to_date(first(rng)), ...
               'last',  tse.fame.to_date(last(rng)));
end

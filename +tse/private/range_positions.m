function ks = range_positions(rng, firstValue, nStored, stored)
%RANGE_POSITIONS  Storage rows selected by an MITRange (internal).
%
%   ks = range_positions(rng, firstValue, nStored) returns the 1-based row
%   positions, in rng's order, of the dates rng selects within storage
%   whose first row is the MIT value firstValue and which holds nStored
%   rows.  Bounds are checked on the selected dates rather than on the
%   endpoints, so a strided or reversed range whose stop lies outside
%   storage is accepted when every date it lands on is stored.  An empty
%   range selects nothing.  The optional stored range is only used in the
%   error message.  Frequency is the caller's to check.

    n = length(rng);
    if n == 0
        ks = zeros(1, 0);
        return
    end
    s = double(rng.stepSize);
    k0 = double(rng.startMIT.value - firstValue) + 1;
    kLast = k0 + (n - 1) * s;
    if min(k0, kLast) < 1 || max(k0, kLast) > nStored
        if nargin < 4
            error('tseries:bounds', 'Range %s is out of bounds.', char(rng));
        end
        error('tseries:bounds', 'Range %s is outside %s.', char(rng), char(stored));
    end
    ks = k0 : s : kLast;
end

function [x, kind] = mit_xcoords(rng, loc)
%MIT_XCOORDS  Build plot x-coordinates for the MITs in an MITRange.
%
%   [x, kind] = mit_xcoords(rng, loc)
%
%   For YP frequencies, x is numeric: toFloat(mit) + mit_offset(loc).
%   For Daily/BDaily/Weekly, x is a datetime vector (MATLAB plots these
%   with a native date ruler).  For other frequencies (e.g. Unit), x is
%   numeric value + offset.
%
%   kind is one of 'yp', 'datetime', or 'numeric'.

    F = int2freq(rng.frequency);
    mits = collect(rng);
    n = numel(mits);
    if isa(F, 'tse.YPFrequency')
        off = mit_offset(loc, F);
        x = zeros(1, n);
        for k = 1:n
            x(k) = toFloat(mits(k)) + off;
        end
        kind = 'yp';
    elseif isa(F, 'tse.Daily') || isa(F, 'tse.BDaily') || isa(F, 'tse.Weekly')
        x = NaT(1, n);
        for k = 1:n
            x(k) = mitToDate(mits(k));
        end
        kind = 'datetime';
    else
        off = mit_offset(loc, F);
        x = zeros(1, n);
        for k = 1:n
            x(k) = double(mits(k).value) + off;
        end
        kind = 'numeric';
    end
end

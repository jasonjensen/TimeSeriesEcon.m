function [code, datefreq] = type_to_fame(v)
%TYPE_TO_FAME  Map MATLAB values to a FAME type code (and, for dates, a freq).
%
%   [code, datefreq] = tse.fame.type_to_fame(v)
%
%   FAME type codes (see FAME.jl src/Types.jl):
%     numeric=1, namelist=2, boolean=3, string=4, precision=5, date=6.
%
%   MATLAB -> FAME element type:
%     single            -> numeric   (1)   (Float32)
%     logical           -> boolean   (3)
%     char/string/cell  -> string    (4)
%     double / integer  -> precision (5)   (Float64; integers promoted)
%     tse.MIT           -> date      (6)   with the MIT's FAME frequency
%
%   datefreq is 0 (undefined) unless v is a tse.MIT, in which case it is the
%   FAME frequency code of the stored dates.
%
%   See also: tse.fame.type_from_fame.
    datefreq = 0;
    if isa(v, 'tse.MIT')
        code = 6;
        datefreq = tse.fame.freq_to_fame(tse.frequencyof(v(1)));
    elseif islogical(v)
        code = 3;
    elseif ischar(v) || isstring(v) || iscell(v)
        code = 4;
    elseif isa(v, 'single')
        code = 1;
    elseif isnumeric(v)
        code = 5;                    % double and integer types -> precision
    else
        error('tseries:noMatch', 'No FAME type for MATLAB class %s.', class(v));
    end
end

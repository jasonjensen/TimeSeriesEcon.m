function v = daec_bool(v)
%DAEC_BOOL  Logical values from stored integers marked Bool.
%
%   TimeSeriesEcon.jl stores Bool as 1-byte integers 0 and 1 with a
%   jtype/jeltype marker of "Bool".  Any other stored value is an error
%   rather than a silent true.
    if ~isnumeric(v) || ~isreal(v) || any(v(:) ~= 0 & v(:) ~= 1)
        error('tseries:daec', 'Values marked Bool must be 0 or 1.');
    end
    v = logical(v);
end

function mixed_freq_error(F1, F2)
%MIXED_FREQ_ERROR Throw a standard mixed-frequency error.
%   Accepts either tse.Frequency objects or int32 frequency codes.
    if isa(F1, 'tse.Frequency')
        s1 = char(F1);
    elseif isnumeric(F1)
        s1 = char(int2freq(int32(F1)));
    else
        s1 = class(F1);
    end
    if isa(F2, 'tse.Frequency')
        s2 = char(F2);
    elseif isnumeric(F2)
        s2 = char(int2freq(int32(F2)));
    else
        s2 = class(F2);
    end
    err = MException('tseries:mixedFreq', ...
        'Mixing frequencies not allowed: %s and %s.', s1, s2);
    throwAsCaller(err);
end

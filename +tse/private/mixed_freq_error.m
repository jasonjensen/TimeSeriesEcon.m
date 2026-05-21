function mixed_freq_error(F1, F2)
%MIXED_FREQ_ERROR Throw a standard mixed-frequency error.
    s1 = class(F1);
    s2 = class(F2);
    if isa(F1, 'tse.Frequency'), s1 = char(F1); end
    if isa(F2, 'tse.Frequency'), s2 = char(F2); end
    err = MException('tseries:mixedFreq', ...
        'Mixing frequencies not allowed: %s and %s.', s1, s2);
    throwAsCaller(err);
end

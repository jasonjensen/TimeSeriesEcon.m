function F = frequencyof(x)
%FREQUENCYOF  Return the frequency of an MIT, Duration, MITRange, or Frequency.
    if isa(x, 'tseries.Frequency')
        F = x;
    elseif isa(x, 'tseries.MIT') || isa(x, 'tseries.Duration')
        F = x.frequency;
    elseif isa(x, 'tseries.MITRange')
        F = x.startMIT.frequency;
    else
        error('tseries:noMatch', '%s does not have a frequency.', class(x));
    end
end

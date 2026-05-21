function F = frequencyof(x)
%FREQUENCYOF  Return the frequency of an MIT, Duration, MITRange, or Frequency.
    if isa(x, 'tse.Frequency')
        F = x;
    elseif isa(x, 'tse.MIT') || isa(x, 'tse.Duration') || isa(x, 'tse.TSeries') || isa(x, 'tse.MVTSeries')
        F = x.frequency;
    elseif isa(x, 'tse.MITRange')
        F = x.startMIT.frequency;
    else
        error('tseries:noMatch', '%s does not have a frequency.', class(x));
    end
end

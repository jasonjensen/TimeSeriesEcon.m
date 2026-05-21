function F = frequencyof(x)
%FREQUENCYOF  Return the frequency of an MIT, Duration, MITRange, or Frequency.
    if isa(x, 'tseries.Frequency')
        F = x;
    elseif isa(x, 'tseries.MIT') || isa(x, 'tseries.Duration') || isa(x, 'tseries.TSeries') || isa(x, 'tseries.MVTSeries')
        F = x.frequency;
    elseif isa(x, 'tseries.MITRange')
        F = x.frequency;
    else
        error('tseries:noMatch', '%s does not have a frequency.', class(x));
    end
end

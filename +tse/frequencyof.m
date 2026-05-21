function F = frequencyof(x)
%FREQUENCYOF  Return the frequency of an MIT, Duration, MITRange, or Frequency.
%
%   Always returns a tse.Frequency object.  MIT and Duration store frequency
%   internally as an int32 code; this function reconstructs the object.
    if isa(x, 'tse.Frequency')
        F = x;
    elseif isa(x, 'tse.MIT') || isa(x, 'tse.Duration')
        F = int2freq(x.frequency);
    elseif isa(x, 'tse.TSeries') || isa(x, 'tse.MVTSeries')
        F = int2freq(x.frequency);
    elseif isa(x, 'tse.MITRange')
        F = int2freq(x.frequency);
    else
        error('tseries:noMatch', '%s does not have a frequency.', class(x));
    end
end

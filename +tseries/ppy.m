function n = ppy(x)
%PPY  Periods per year for the frequency of x.
    F = tseries.frequencyof(x);
    if isa(F, 'tseries.Unit')
        error('tseries:noMatch', 'Frequency Unit does not have periods per year.');
    end
    n = double(F.PeriodsPerYear);
end

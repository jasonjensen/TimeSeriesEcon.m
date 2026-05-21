function n = ppy(x)
%PPY  Periods per year for the frequency of x.
    F = tse.frequencyof(x);
    if isa(F, 'tse.Unit')
        error('tseries:noMatch', 'Frequency Unit does not have periods per year.');
    end
    n = double(F.PeriodsPerYear);
end

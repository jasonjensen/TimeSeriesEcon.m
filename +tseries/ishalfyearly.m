function tf = ishalfyearly(x)
    tf = isa(tseries.frequencyof(x), 'tseries.HalfYearly');
end

function tf = isyearly(x)
    tf = isa(tseries.frequencyof(x), 'tseries.Yearly');
end

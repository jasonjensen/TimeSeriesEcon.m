function tf = isweekly(x)
    tf = isa(tseries.frequencyof(x), 'tseries.Weekly');
end

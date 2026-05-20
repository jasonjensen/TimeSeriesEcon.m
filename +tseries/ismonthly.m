function tf = ismonthly(x)
    tf = isa(tseries.frequencyof(x), 'tseries.Monthly');
end

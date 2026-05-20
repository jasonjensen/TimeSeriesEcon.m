function tf = isquarterly(x)
    tf = isa(tseries.frequencyof(x), 'tseries.Quarterly');
end

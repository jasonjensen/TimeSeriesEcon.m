function tf = isdaily(x)
    tf = isa(tseries.frequencyof(x), 'tseries.Daily');
end

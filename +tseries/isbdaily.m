function tf = isbdaily(x)
    tf = isa(tseries.frequencyof(x), 'tseries.BDaily');
end

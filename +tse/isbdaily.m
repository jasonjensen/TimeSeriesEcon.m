function tf = isbdaily(x)
    tf = isa(tse.frequencyof(x), 'tse.BDaily');
end

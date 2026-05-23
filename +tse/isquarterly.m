function tf = isquarterly(x)
%ISQUARTERLY  True if x has Quarterly frequency.
    tf = isa(tse.frequencyof(x), 'tse.Quarterly');
end

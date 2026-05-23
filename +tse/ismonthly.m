function tf = ismonthly(x)
%ISMONTHLY  True if x has Monthly frequency.
    tf = isa(tse.frequencyof(x), 'tse.Monthly');
end

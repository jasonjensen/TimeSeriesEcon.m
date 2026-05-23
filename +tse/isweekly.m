function tf = isweekly(x)
%ISWEEKLY  True if x has Weekly frequency.
    tf = isa(tse.frequencyof(x), 'tse.Weekly');
end

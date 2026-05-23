function tf = isyearly(x)
%ISYEARLY  True if x has Yearly frequency.
    tf = isa(tse.frequencyof(x), 'tse.Yearly');
end

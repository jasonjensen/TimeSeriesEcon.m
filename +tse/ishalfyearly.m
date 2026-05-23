function tf = ishalfyearly(x)
%ISHALFYEARLY  True if x has HalfYearly frequency.
    tf = isa(tse.frequencyof(x), 'tse.HalfYearly');
end

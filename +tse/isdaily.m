function tf = isdaily(x)
%ISDAILY  True if x has Daily frequency (MIT/Duration/MITRange/TSeries/...).
    tf = isa(tse.frequencyof(x), 'tse.Daily');
end

function tf = isbdaily(x)
%ISBDAILY  True if x has BDaily (business-daily) frequency.
    tf = isa(tse.frequencyof(x), 'tse.BDaily');
end

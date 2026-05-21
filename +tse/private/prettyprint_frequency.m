function s = prettyprint_frequency(F)
%PRETTYPRINT_FREQUENCY Default printable name (suppress default end-period).
    if isa(F, 'tse.Frequency')
        s = char(F);
    else
        s = class(F);
    end
end

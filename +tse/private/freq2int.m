function c = freq2int(F)
%FREQ2INT  Convert a tse.Frequency object to its integer code (int32).
%
%   Encoding (mirrors TimeSeriesEcon.jl / TimeSeriesEconPy conventions):
%     Unit        -> 11
%     Daily       -> 12
%     BDaily      -> 13
%     Weekly(ep)  -> 16 + ep   (ep=1=Mon .. 7=Sun -> 17..23)
%     Monthly     -> 32
%     Quarterly(ep)   -> 64 + mod(ep,3)   (ep=3 -> 64; ep=1 -> 65; ep=2 -> 66)
%     HalfYearly(ep)  -> 128 + mod(ep,6)  (ep=6 -> 128; ep=1..5 -> 129..133)
%     Yearly(ep)      -> 256 + mod(ep,12) (ep=12 -> 256; ep=1..11 -> 257..267)
%
%   See also: int2freq.

    if isa(F, 'tse.Unit')
        c = int32(11);
    elseif isa(F, 'tse.Daily')
        c = int32(12);
    elseif isa(F, 'tse.BDaily')
        c = int32(13);
    elseif isa(F, 'tse.Weekly')
        c = int32(16 + F.endPeriod);
    elseif isa(F, 'tse.Monthly')
        c = int32(32);
    elseif isa(F, 'tse.Quarterly')
        c = int32(64 + mod(F.endPeriod, 3));
    elseif isa(F, 'tse.HalfYearly')
        c = int32(128 + mod(F.endPeriod, 6));
    elseif isa(F, 'tse.Yearly')
        c = int32(256 + mod(F.endPeriod, 12));
    else
        error('tseries:noMatch', 'Unknown frequency class: %s', class(F));
    end
end

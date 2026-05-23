function F = int2freq(c)
%INT2FREQ  Reconstruct a tse.Frequency object from its integer code.
%
%   This is the inverse of freq2int.  Used to convert the stored int32
%   frequency field back to a Frequency object for display or external API.
%
%   See also: freq2int.

    c = int32(c);
    if c == int32(11)
        F = tse.Unit();
    elseif c == int32(12)
        F = tse.Daily();
    elseif c == int32(13)
        F = tse.BDaily();
    elseif c >= int32(17) && c <= int32(23)
        F = tse.Weekly(double(c) - 16);
    elseif c == int32(32)
        F = tse.Monthly();
    elseif c >= int32(64) && c <= int32(67)
        ep = mod(double(c) - 64, 3);
        if ep == 0, ep = 3; end
        F = tse.Quarterly(ep);
    elseif c >= int32(128) && c <= int32(134)
        ep = mod(double(c) - 128, 6);
        if ep == 0, ep = 6; end
        F = tse.HalfYearly(ep);
    elseif c >= int32(256) && c <= int32(268)
        ep = mod(double(c) - 256, 12);
        if ep == 0, ep = 12; end
        F = tse.Yearly(ep);
    else
        error('tseries:noMatch', 'Unknown frequency code: %d', double(c));
    end
end

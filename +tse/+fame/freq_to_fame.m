function code = freq_to_fame(F)
%FREQ_TO_FAME  Map a tse.Frequency to a FAME frequency code.
%
%   code = tse.fame.freq_to_fame(tse.Quarterly(3))   % -> 162
%
%   FAME frequency integer codes (see FAME.jl src/Types.jl and the FAME CHLI):
%     daily        = 8      business     = 9
%     weekly_sun   = 16     weekly_mon..sat = 17..22
%     monthly      = 129
%     quarterly_oct/nov/dec = 160..162
%     annual_jan..dec       = 192..203
%     semiannual_jul..dec   = 204..209
%     case         = 232
%
%   The tse end period is carried through in the code, so calendar variants
%   round-trip exactly:
%     Weekly(ep)     -> 16 if ep==7 (Sunday), else 16+ep   (Mon..Sat = 17..22)
%     Quarterly(ep)  -> 159 + ep                            (ep in 1..3)
%     HalfYearly(ep) -> 203 + ep                            (ep in 1..6)
%     Yearly(ep)     -> 191 + ep                            (ep in 1..12)
%
%   See also: tse.fame.freq_from_fame.
    if ~isa(F, 'tse.Frequency')
        error('tseries:noMatch', 'freq_to_fame expects a tse.Frequency (got %s).', class(F));
    end
    if isa(F, 'tse.Daily')
        code = 8;
    elseif isa(F, 'tse.BDaily')
        code = 9;
    elseif isa(F, 'tse.Weekly')
        if F.endPeriod == 7
            code = 16;                  % weekly_sunday
        else
            code = 16 + F.endPeriod;    % weekly_monday..saturday (17..22)
        end
    elseif isa(F, 'tse.Monthly')
        code = 129;
    elseif isa(F, 'tse.Quarterly')
        code = 159 + F.endPeriod;       % quarterly_october..december (160..162)
    elseif isa(F, 'tse.HalfYearly')
        code = 203 + F.endPeriod;       % semiannual_july..december (204..209)
    elseif isa(F, 'tse.Yearly')
        code = 191 + F.endPeriod;       % annual_january..december (192..203)
    elseif isa(F, 'tse.Unit')
        code = 232;                     % case
    else
        error('tseries:noMatch', 'Unsupported frequency for FAME: %s', class(F));
    end
end

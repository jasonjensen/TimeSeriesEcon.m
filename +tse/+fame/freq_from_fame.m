function F = freq_from_fame(code)
%FREQ_FROM_FAME  Map a FAME frequency code to a tse.Frequency.
%
%   F = tse.fame.freq_from_fame(162)   % -> tse.Quarterly(3)
%
%   Inverse of tse.fame.freq_to_fame for the frequencies TimeSeriesEcon.m
%   supports.  FAME frequencies with no tse analogue raise an error:
%     undefined=0, tenday=32, biweekly=64..77, twicemonthly=128,
%     bimonthly=144/145, ypp/ppy=224/225, secondly/minutely/hourly=226..228,
%     millisecondly=229, weekly_pattern=233.
%
%   See also: tse.fame.freq_to_fame.
    code = double(code);
    switch code
        case 8
            F = tse.Daily();
        case 9
            F = tse.BDaily();
        case 16
            F = tse.Weekly(7);                 % weekly_sunday
        case {17, 18, 19, 20, 21, 22}
            F = tse.Weekly(code - 16);         % weekly_monday..saturday
        case 129
            F = tse.Monthly();
        case {160, 161, 162}
            F = tse.Quarterly(code - 159);
        case {204, 205, 206, 207, 208, 209}
            F = tse.HalfYearly(code - 203);
        case {192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203}
            F = tse.Yearly(code - 191);
        case 232
            F = tse.Unit();
        otherwise
            error('tseries:noMatch', ...
                'FAME frequency code %d has no TimeSeriesEcon.m equivalent.', code);
    end
end

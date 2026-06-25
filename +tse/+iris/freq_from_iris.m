function F = freq_from_iris(code)
%FREQ_FROM_IRIS  Map an IRIS frequency code to a tse.Frequency instance.
%
%   Calendar-yearly frequencies are returned with the calendar end period
%   (Yearly(12), HalfYearly(6), Quarterly(3), Weekly(7)) -- IRIS has no
%   end-month concept of its own.
    switch double(code)
        case 0
            F = tse.Unit();
        case 1
            F = tse.Yearly(12);
        case 2
            F = tse.HalfYearly(6);
        case 4
            F = tse.Quarterly(3);
        case 12
            F = tse.Monthly();
        case 52
            F = tse.Weekly(7);
        case 365
            F = tse.Daily();
        otherwise
            error('tseries:noMatch', 'Unknown IRIS frequency code: %g.', double(code));
    end
end

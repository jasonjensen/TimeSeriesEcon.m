function F = freq_from_dynare(code)
%FREQ_FROM_DYNARE  Map a Dynare frequency code to a tse.Frequency instance.
%
%   Calendar-yearly frequencies are returned with the calendar end period
%   (Yearly(12), HalfYearly(6), Quarterly(3), Weekly(7)) -- Dynare has no
%   end-month concept of its own.
    switch double(code)
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
            error('tseries:noMatch', 'Unknown Dynare frequency code: %g.', double(code));
    end
end

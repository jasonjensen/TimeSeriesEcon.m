function code = freq_to_iris(F)
%FREQ_TO_IRIS  Map a tse.Frequency to an IRIS frequency code.
%
%   IRIS codes: 0 = unknown (Unit), 1 = yearly, 2 = half-yearly,
%               4 = quarterly, 12 = monthly, 52 = weekly, 365 = daily.
%
%   Errors with a clear message for tse.BDaily (IRIS 2015 has no
%   business-day frequency -- convert to Daily first).
    if ~isa(F, 'tse.Frequency')
        error('tseries:noMatch', 'freq_to_iris expects a tse.Frequency.');
    end
    if isa(F, 'tse.Yearly')
        code = 1;
    elseif isa(F, 'tse.HalfYearly')
        code = 2;
    elseif isa(F, 'tse.Quarterly')
        code = 4;
    elseif isa(F, 'tse.Monthly')
        code = 12;
    elseif isa(F, 'tse.Weekly')
        code = 52;
    elseif isa(F, 'tse.Daily')
        code = 365;
    elseif isa(F, 'tse.BDaily')
        error('tseries:noMatch', ...
            ['IRIS Toolbox 2015 has no business-day frequency. ', ...
             'Convert your BDaily series to Daily before sending it across.']);
    elseif isa(F, 'tse.Unit')
        code = 0;
    else
        error('tseries:noMatch', 'Unsupported frequency: %s', class(F));
    end
end

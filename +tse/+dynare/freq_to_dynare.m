function code = freq_to_dynare(F)
%FREQ_TO_DYNARE  Map a tse.Frequency to a Dynare frequency code.
%
%   Dynare codes: 1 = annual, 2 = half-yearly (biannual), 4 = quarterly,
%                 12 = monthly, 52 = weekly, 365 = daily.
%
%   Errors with a clear message for tse.BDaily (Dynare's dates has no
%   business-day frequency -- convert to Daily first) and for tse.Unit
%   (Dynare has no frequency-less date class).
    if ~isa(F, 'tse.Frequency')
        error('tseries:noMatch', 'freq_to_dynare expects a tse.Frequency.');
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
            ['Dynare has no business-day frequency.  Convert your BDaily ', ...
             'series to Daily before sending it across.']);
    elseif isa(F, 'tse.Unit')
        error('tseries:noMatch', ...
            'Dynare has no frequency-less date class; tse.Unit cannot be sent across.');
    else
        error('tseries:noMatch', 'Unsupported frequency: %s', class(F));
    end
end

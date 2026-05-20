function n = endperiod(x)
%ENDPERIOD  Return the end-period marker for the frequency of x.
%
%   For Weekly{end_day}, this is end_day (1..7).
%   For Quarterly{end_month}, HalfYearly{end_month}, Yearly{end_month}, the
%   end month (1..3, 1..6, 1..12 respectively).
%   For frequencies without a configurable end-period (Monthly, Daily,
%   BDaily, Unit), returns 1.
    F = tseries.frequencyof(x);
    n = double(F.endPeriod);
end

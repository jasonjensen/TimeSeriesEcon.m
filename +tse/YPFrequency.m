classdef (Abstract) YPFrequency < tse.CalendarFrequency
    %YPFREQUENCY Abstract base for year-period (YP) frequencies.
    %
    %   A YP frequency divides the year into a fixed number of equal periods.
    %   The number of periods per year is exposed as the constant
    %   PeriodsPerYear (1 for Yearly, 2 for HalfYearly, 4 for Quarterly,
    %   12 for Monthly).
end

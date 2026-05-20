classdef Daily < tseries.CalendarFrequency
    %DAILY  All days are valid.

    properties (Constant)
        Name = 'Daily'
        PeriodsPerYear = 365  % approximate
    end

    methods
        function F = Daily()
            % no parameters
        end

        function d = defaultEndPeriod(~)
            d = 1;
        end
    end
end

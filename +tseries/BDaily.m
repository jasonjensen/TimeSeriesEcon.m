classdef BDaily < tseries.CalendarFrequency
    %BDAILY Business daily.  Excludes Saturdays and Sundays.

    properties (Constant)
        Name = 'BDaily'
        PeriodsPerYear = 260  % approximate
    end

    methods
        function F = BDaily()
            % no parameters
        end

        function d = defaultEndPeriod(~)
            d = 1;
        end
    end
end

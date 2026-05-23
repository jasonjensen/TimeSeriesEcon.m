classdef Monthly < tse.YPFrequency
    %MONTHLY 12 periods per year.  No end-month parameter.

    properties (Constant)
        Name = 'Monthly'
        PeriodsPerYear = 12
    end

    methods
        function F = Monthly()
            % endPeriod is always 1 for Monthly (fixed)
        end

        function d = defaultEndPeriod(~)
            d = 1;
        end
    end
end

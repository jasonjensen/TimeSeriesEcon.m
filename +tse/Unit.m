classdef Unit < tse.Frequency
    %UNIT Non-calendar frequency.

    properties (Constant)
        Name = 'Unit'
        PeriodsPerYear = NaN  % undefined; ppy() errors for Unit
    end

    methods
        function F = Unit()
            % endPeriod stays at its default of 1
        end

        function d = defaultEndPeriod(~)
            d = 1;
        end

        function tf = lt(~, ~)
            error('tseries:invalidArith', 'Frequency Unit does not have a periods-per-year ordering.');
        end
    end
end

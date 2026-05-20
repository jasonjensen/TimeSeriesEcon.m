classdef Yearly < tseries.YPFrequency
    %YEARLY 1 period per year, end month between 1 and 12 (default 12).

    properties (Constant)
        Name = 'Yearly'
        PeriodsPerYear = 1
    end

    methods
        function F = Yearly(endMonth)
            if nargin < 1
                endMonth = 12;
            end
            if ~isnumeric(endMonth) || ~isscalar(endMonth) || endMonth ~= fix(endMonth)
                error('tseries:invalidArith', ...
                    'The end_month for a Yearly frequency must be an integer. Received: %s', num2str(endMonth));
            end
            if endMonth > 12 || endMonth < 1
                error('tseries:invalidArith', ...
                    'The end_month for a Yearly frequency must be between 1 and 12. Received: %d', endMonth);
            end
            F.endPeriod = double(endMonth);
        end

        function d = defaultEndPeriod(~)
            d = 12;
        end
    end
end

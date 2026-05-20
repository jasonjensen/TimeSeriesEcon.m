classdef Quarterly < tseries.YPFrequency
    %QUARTERLY 4 periods per year, end month between 1 and 3 (default 3).

    properties (Constant)
        Name = 'Quarterly'
        PeriodsPerYear = 4
    end

    methods
        function F = Quarterly(endMonth)
            if nargin < 1
                endMonth = 3;
            end
            if ~isnumeric(endMonth) || ~isscalar(endMonth) || endMonth ~= fix(endMonth)
                error('tseries:invalidArith', ...
                    'The end_month for a Quarterly frequency must be an integer. Received: %s', num2str(endMonth));
            end
            if endMonth > 3 || endMonth < 1
                error('tseries:invalidArith', ...
                    'The end_month for a Quarterly frequency must be between 1 and 3. Received: %d', endMonth);
            end
            F.endPeriod = double(endMonth);
        end

        function d = defaultEndPeriod(~)
            d = 3;
        end
    end
end

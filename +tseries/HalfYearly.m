classdef HalfYearly < tseries.YPFrequency
    %HALFYEARLY 2 periods per year, end month between 1 and 6 (default 6).

    properties (Constant)
        Name = 'HalfYearly'
        PeriodsPerYear = 2
    end

    methods
        function F = HalfYearly(endMonth)
            if nargin < 1
                endMonth = 6;
            end
            if ~isnumeric(endMonth) || ~isscalar(endMonth) || endMonth ~= fix(endMonth)
                error('tseries:invalidArith', ...
                    'The end_month for a HalfYearly frequency must be an integer. Received: %s', num2str(endMonth));
            end
            if endMonth > 6 || endMonth < 1
                error('tseries:invalidArith', ...
                    'The end_month for a HalfYearly frequency must be between 1 and 6. Received: %d', endMonth);
            end
            F.endPeriod = double(endMonth);
        end

        function d = defaultEndPeriod(~)
            d = 6;
        end
    end
end

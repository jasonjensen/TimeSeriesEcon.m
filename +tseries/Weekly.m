classdef Weekly < tseries.CalendarFrequency
    %WEEKLY  Weekly frequency.  endPeriod is the end-of-week day (1=Mon,
    %        7=Sun).  Default 7.

    properties (Constant)
        Name = 'Weekly'
        PeriodsPerYear = 52
    end

    methods
        function F = Weekly(endDay)
            if nargin < 1
                endDay = 7;
            end
            if ~isnumeric(endDay) || ~isscalar(endDay) || endDay ~= fix(endDay) ...
                    || endDay < 1 || endDay > 7
                error('tseries:invalidArith', ...
                    'The end_day for a Weekly frequency must be an integer in 1..7.  Received: %s', ...
                    num2str(endDay));
            end
            F.endPeriod = double(endDay);
        end

        function d = defaultEndPeriod(~)
            d = 7;
        end
    end
end

classdef MIT
    %MIT  Moment in time (single point of a given frequency).
    %
    %   Construction:
    %       MIT(F)              empty (value 0)
    %       MIT(F, n)           from raw integer offset
    %       MIT(F, y, p)        from year and period (YP frequencies only,
    %                           or daily/bdaily where p = day-of-year)
    %
    %   See also: tse.Duration, tse.qq, tse.mm, tse.yy,
    %             tse.daily, tse.bdaily, tse.weekly,
    %             tse.MITRange.

    properties (SetAccess = immutable)
        value (1,1) int64       = int64(0)
        frequency (1,1) int32   = int32(11)   % integer code; see freq2int / int2freq
    end

    methods
        function obj = MIT(F, varargin)
            if nargin == 0
                return  % default-constructed MIT, used internally
            end
            % Accept either a tse.Frequency object or an int32 frequency code.
            if isa(F, 'tse.Frequency')
                obj.frequency = freq2int(F);
                fObj = F;          % keep original for yp2value (case 2)
            elseif isnumeric(F) && isscalar(F)
                obj.frequency = int32(F);
                fObj = [];         % will reconstruct only if needed
            else
                error('tseries:noMatch', ...
                    'MIT(F, ...) requires a tse.Frequency or integer frequency code.');
            end
            switch numel(varargin)
                case 0
                    obj.value = int64(0);
                case 1
                    obj.value = int64(varargin{1});
                case 2
                    y = int64(varargin{1});
                    p = int64(varargin{2});
                    if isempty(fObj)
                        fObj = int2freq(obj.frequency);
                    end
                    obj.value = tse.MIT.yp2value(fObj, y, p);
                otherwise
                    error('tseries:noMatch', ...
                        'MIT accepts at most three arguments (frequency, year, period).');
            end
        end

        % ---------- conversions ----------

        function n = int64(m)
            n = m.value;
        end

        function n = double(m)
            % default conversion: integer value.  YP-specific fractional
            % form (year + (p-1)/N) is provided via toFloat() instead.
            n = double(m.value);
        end

        function n = toFloat(m)
            % Floating-point representation as year + (period-1)/N for YP
            % frequencies; falls back to raw value otherwise.  Used for
            % plotting.
            F = int2freq(m.frequency);
            if isa(F, 'tse.YPFrequency')
                yp = mit2yp(m);
                n = double(yp(1)) + (double(yp(2)) - 1) / double(F.PeriodsPerYear);
            else
                n = double(m.value);
            end
        end

        % ---------- arithmetic ----------

        function r = plus(a, b)
            if isa(a, 'tse.MIT') && isa(b, 'tse.MIT')
                error('tseries:invalidArith', ...
                    'Illegal addition of two MIT values.');
            elseif isa(a, 'tse.Duration') && isa(b, 'tse.MIT')
                error('tseries:invalidArith', ...
                    'Illegal addition of Duration and MIT. Try MIT + Duration.');
            elseif isa(a, 'tse.MIT') && isa(b, 'tse.Duration')
                if a.frequency ~= b.frequency
                    mixed_freq_error(a.frequency, b.frequency);
                end
                r = tse.MIT(a.frequency, a.value + b.value);
            elseif isa(a, 'tse.MIT') && isnumeric(b)
                if isa(b, 'double') && any(b ~= fix(b))
                    % Float math: return float.
                    r = toFloat(a) + b;
                else
                    r = tse.MIT(a.frequency, a.value + int64(b));
                end
            elseif isnumeric(a) && isa(b, 'tse.MIT')
                if isa(a, 'double') && any(a ~= fix(a))
                    r = a + toFloat(b);
                else
                    r = tse.MIT(b.frequency, int64(a) + b.value);
                end
            else
                error('tseries:invalidArith', 'Invalid operands to plus.');
            end
        end

        function r = minus(a, b)
            if isa(a, 'tse.MIT') && isa(b, 'tse.MIT')
                if a.frequency ~= b.frequency
                    mixed_freq_error(a.frequency, b.frequency);
                end
                r = tse.Duration(a.frequency, a.value - b.value);
            elseif isa(a, 'tse.MIT') && isa(b, 'tse.Duration')
                if a.frequency ~= b.frequency
                    mixed_freq_error(a.frequency, b.frequency);
                end
                r = tse.MIT(a.frequency, a.value - b.value);
            elseif isa(a, 'tse.MIT') && isnumeric(b)
                if isa(b, 'double') && any(b ~= fix(b))
                    r = toFloat(a) - b;
                else
                    r = tse.MIT(a.frequency, a.value - int64(b));
                end
            elseif isnumeric(a) && isa(b, 'tse.MIT')
                error('tseries:invalidArith', 'Cannot subtract MIT from Integer.');
            else
                error('tseries:invalidArith', 'Invalid operands to minus.');
            end
        end

        function r = uminus(~) %#ok<STOUT>
            error('tseries:invalidArith', 'Unary minus is not defined on MIT.');
        end

        function r = mtimes(a, b)
            r = times(a, b);
        end

        function r = times(~, ~) %#ok<STOUT>
            error('tseries:invalidArith', 'Multiplication is not defined on MIT.');
        end

        function r = mrdivide(a, b)
            r = rdivide(a, b);
        end

        function r = rdivide(a, b)
            if isa(a, 'tse.MIT') && isa(b, 'tse.Duration')
                if a.frequency ~= b.frequency
                    mixed_freq_error(a.frequency, b.frequency);
                end
                r = double(a.value) / double(b.value);
            else
                error('tseries:invalidArith', 'Division is only defined for MIT / Duration of the same frequency.');
            end
        end

        % ---------- equality ----------

        function tf = eq(a, b)
            if isa(a, 'tse.MIT') && isa(b, 'tse.MIT')
                tf = (a.frequency == b.frequency) && (a.value == b.value);
            elseif isa(a, 'tse.MIT') && isnumeric(b)
                tf = (a.value == int64(b));
            elseif isnumeric(a) && isa(b, 'tse.MIT')
                tf = (int64(a) == b.value);
            elseif isa(a, 'tse.MIT') && isa(b, 'tse.Duration')
                tf = false;
            elseif isa(a, 'tse.Duration') && isa(b, 'tse.MIT')
                tf = false;
            else
                tf = false;
            end
        end

        function tf = ne(a, b)
            tf = ~eq(a, b);
        end

        function tf = lt(a, b)
            if isa(a, 'tse.MIT') && isa(b, 'tse.MIT')
                if a.frequency ~= b.frequency
                    mixed_freq_error(a.frequency, b.frequency);
                end
                tf = (a.value < b.value);
            elseif isa(a, 'tse.MIT') && isa(b, 'tse.Duration')
                error('tseries:invalidArith', 'Illegal comparison of MIT and Duration.');
            elseif isa(a, 'tse.Duration') && isa(b, 'tse.MIT')
                error('tseries:invalidArith', 'Illegal comparison of Duration and MIT.');
            elseif isa(a, 'tse.MIT') && isnumeric(b)
                tf = (a.value < int64(b));
            elseif isnumeric(a) && isa(b, 'tse.MIT')
                tf = (int64(a) < b.value);
            else
                error('tseries:invalidArith', 'Invalid operands to lt.');
            end
        end

        function tf = le(a, b)
            tf = lt(a, b) || eq(a, b);
        end

        function tf = gt(a, b)
            tf = lt(b, a);
        end

        function tf = ge(a, b)
            tf = gt(a, b) || eq(a, b);
        end

        function tf = isequal(a, b)
            tf = eq(a, b);
        end

        function tf = iszero(m)
            tf = (m.value == 0);
        end

        function h = hash(m)
            h = string(double(m.frequency)) + ":" + string(double(m.value));
        end

        % ---------- ranges ----------

        function rng = colon(varargin)
            if nargin == 2
                a = varargin{1}; b = varargin{2};
                if isnumeric(a) || isnumeric(b)
                    error('tseries:invalidArith', ...
                        'Cannot mix Int and MIT in the same range.');
                end
                if a.frequency ~= b.frequency
                    mixed_freq_error(a.frequency, b.frequency);
                end
                rng = tse.MITRange(a, b);
            elseif nargin == 3
                a = varargin{1}; s = varargin{2}; b = varargin{3};
                if isnumeric(a) || isnumeric(b)
                    error('tseries:invalidArith', ...
                        'Cannot mix Int and MIT in the same range.');
                end
                if a.frequency ~= b.frequency
                    mixed_freq_error(a.frequency, b.frequency);
                end
                if isa(s, 'tse.Duration')
                    if a.frequency ~= s.frequency
                        mixed_freq_error(a.frequency, s.frequency);
                    end
                    step = s.value;
                elseif isnumeric(s)
                    step = int64(s);
                else
                    error('tseries:invalidArith', 'Invalid step in MIT range.');
                end
                rng = tse.MITRange(a, b, step);
            else
                error('tseries:invalidArith', 'Wrong number of args to colon.');
            end
        end

        % ---------- introspection ----------

        function F = frequencyof(m)
            F = m.frequency;
        end

        function yp = mit2yp(m)
            yp = tse.mit2yp(m);
        end

        function y = year(m)
            yp = tse.mit2yp(m);
            y = yp(1);
        end

        function p = period(m)
            yp = tse.mit2yp(m);
            p = yp(2);
        end

        % (length/numel/size left to MATLAB defaults so that object arrays
        %  of MITs behave normally; a scalar MIT then has size [1 1].)

        % ---------- display ----------

        function s = char(m)
            F = int2freq(m.frequency);
            if isa(F, 'tse.Unit')
                s = sprintf('%dU', double(m.value));
            elseif isa(F, 'tse.Yearly')
                yp = tse.mit2yp(m);
                s = sprintf('%dY', double(yp(1)));
                if F.endPeriod ~= F.defaultEndPeriod()
                    s = [s sprintf('{%d}', F.endPeriod)];
                end
            elseif isa(F, 'tse.HalfYearly')
                yp = tse.mit2yp(m);
                s = sprintf('%dH%d', double(yp(1)), double(yp(2)));
                if F.endPeriod ~= F.defaultEndPeriod()
                    s = [s sprintf('{%d}', F.endPeriod)];
                end
            elseif isa(F, 'tse.Quarterly')
                yp = tse.mit2yp(m);
                s = sprintf('%dQ%d', double(yp(1)), double(yp(2)));
                if F.endPeriod ~= F.defaultEndPeriod()
                    s = [s sprintf('{%d}', F.endPeriod)];
                end
            elseif isa(F, 'tse.Monthly')
                yp = tse.mit2yp(m);
                s = sprintf('%dM%d', double(yp(1)), double(yp(2)));
            elseif isa(F, 'tse.Daily') || isa(F, 'tse.BDaily')
                d = mitToDate(m);
                s = char(d, 'yyyy-MM-dd');
            elseif isa(F, 'tse.Weekly')
                d = mitToDate(m);
                s = char(d, 'yyyy-MM-dd');
            elseif isa(F, 'tse.YPFrequency')
                yp = tse.mit2yp(m);
                s = sprintf('%dP%d', double(yp(1)), double(yp(2)));
            else
                s = sprintf('%s(%d)', class(F), double(m.value));
            end
        end

        function s = string(m)
            s = string(char(m));
        end

        function disp(m)
            fprintf('%s\n', char(m));
        end
    end

    methods (Static, Access = private)
        function v = yp2value(F, y, p)
            y = int64(y); p = int64(p);
            if isa(F, 'tse.YPFrequency')
                N = int64(F.PeriodsPerYear);
                v = N * y + p - 1;
            elseif isa(F, 'tse.Daily')
                firstDay = dateOfYearJan1(y);
                v = dateToDailyValue(firstDay) + p - 1;
            elseif isa(F, 'tse.BDaily')
                firstDay = dateOfYearJan1(y);
                fd_dow = weekday(firstDay);  % 1=Sun .. 7=Sat
                fd_iso = mod(fd_dow - 2, 7) + 1;  % 1=Mon..7=Sun
                if fd_iso > 5
                    daysAdj = 8 - fd_iso;
                else
                    daysAdj = 0;
                end
                d = firstDay + days(daysAdj);
                v = dateToBDailyValue(d) + p - 1;
            elseif isa(F, 'tse.Weekly')
                firstDay = dateOfYearJan1(y);
                d = firstDay + days(7 * (p - 1));
                v = dateToWeeklyValue(d, F.endPeriod);
            elseif isa(F, 'tse.Unit')
                error('tseries:noMatch', ...
                    'MIT{Unit} does not support (year, period) construction.');
            else
                error('tseries:noMatch', ...
                    'MIT{%s} does not support (year, period) construction.', class(F));
            end
        end
    end
end

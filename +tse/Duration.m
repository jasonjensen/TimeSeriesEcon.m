classdef Duration
    %DURATION  Distance between two moments-in-time of the same frequency.
    %
    %   See also: tse.MIT.

    properties (SetAccess = immutable)
        value      = int64(0)
        frequency  = int32(11)
    end

    methods
        function obj = Duration(F, value)
            if nargin == 0
                return
            end
            % Fast path: integer freq code + already-int64 value.
            if nargin == 2 && isnumeric(F)
                obj.frequency = int32(F);
                obj.value     = int64(value);
                return
            end
            if isa(F, 'tse.Frequency')
                obj.frequency = freq2int(F);
            else
                error('tseries:noMatch', ...
                    'Duration(F, n) requires a tse.Frequency or integer frequency code.');
            end
            if nargin < 2
                value = 0;
            end
            obj.value = int64(value);
        end

        % ---------- conversions ----------

        function n = int64(d)
            n = d.value;
        end

        function n = double(d)
            F = int2freq(d.frequency);
            if isa(F, 'tse.YPFrequency')
                % Julia: Float(d) = Int(d) / N for YP
                n = double(d.value) / double(F.PeriodsPerYear);
            else
                n = double(d.value);
            end
        end

        function n = toInt(d)
            n = double(d.value);
        end

        % ---------- arithmetic ----------

        function r = plus(a, b)
            if isa(a, 'tse.Duration') && isa(b, 'tse.Duration')
                if a.frequency ~= b.frequency
                    mixed_freq_error(a.frequency, b.frequency);
                end
                r = tse.Duration(a.frequency, a.value + b.value);
            elseif isa(a, 'tse.Duration') && isa(b, 'tse.MIT')
                error('tseries:invalidArith', ...
                    'Illegal addition of Duration and MIT. Try MIT + Duration.');
            elseif isa(a, 'tse.Duration') && isnumeric(b)
                r = tse.Duration(a.frequency, a.value + int64(b));
            elseif isnumeric(a) && isa(b, 'tse.Duration')
                r = tse.Duration(b.frequency, int64(a) + b.value);
            else
                error('tseries:invalidArith', 'Invalid operands to plus.');
            end
        end

        function r = minus(a, b)
            if isa(a, 'tse.Duration') && isa(b, 'tse.Duration')
                if a.frequency ~= b.frequency
                    mixed_freq_error(a.frequency, b.frequency);
                end
                r = tse.Duration(a.frequency, a.value - b.value);
            elseif isa(a, 'tse.Duration') && isnumeric(b)
                r = tse.Duration(a.frequency, a.value - int64(b));
            elseif isnumeric(a) && isa(b, 'tse.Duration')
                r = tse.Duration(b.frequency, int64(a) - b.value);
            else
                error('tseries:invalidArith', 'Invalid operands to minus.');
            end
        end

        function r = uminus(d)
            r = tse.Duration(d.frequency, -d.value);
        end

        function r = mtimes(a, b)
            r = times(a, b);
        end

        function r = times(a, b)
            if isa(a, 'tse.Duration') && isnumeric(b)
                r = tse.Duration(a.frequency, a.value * int64(b));
            elseif isnumeric(a) && isa(b, 'tse.Duration')
                r = tse.Duration(b.frequency, int64(a) * b.value);
            else
                error('tseries:invalidArith', ...
                    'Multiplication of two Durations is not defined.');
            end
        end

        function r = rdivide(a, b)
            if isa(a, 'tse.Duration') && isa(b, 'tse.Duration')
                if a.frequency ~= b.frequency
                    mixed_freq_error(a.frequency, b.frequency);
                end
                r = double(a.value) / double(b.value);
            else
                error('tseries:invalidArith', 'Division of Duration is only defined Duration / Duration of same frequency.');
            end
        end

        function r = mrdivide(a, b)
            r = rdivide(a, b);
        end

        function r = rem(a, b)
            if ~isa(b, 'tse.Duration')
                error('tseries:invalidArith', 'Modulus only defined Duration vs Duration.');
            end
            if a.frequency ~= b.frequency
                mixed_freq_error(a.frequency, b.frequency);
            end
            r = tse.Duration(a.frequency, rem(a.value, b.value));
        end

        function r = mod(a, b)
            r = rem(a, b);
        end

        function r = idivide(a, b)
            r = floor_div(a, b);
        end

        function r = floor_div(a, b)
            if ~isa(b, 'tse.Duration')
                error('tseries:invalidArith', 'Integer division only defined Duration vs Duration.');
            end
            if a.frequency ~= b.frequency
                mixed_freq_error(a.frequency, b.frequency);
            end
            r = tse.Duration(a.frequency, idivide(a.value, b.value, 'fix'));
        end

        function r = div(a, b)
            r = floor_div(a, b);
        end

        % ---------- equality ----------

        function tf = eq(a, b)
            if isa(a, 'tse.Duration') && isa(b, 'tse.Duration')
                tf = (a.frequency == b.frequency) && (a.value == b.value);
            elseif isa(a, 'tse.Duration') && isnumeric(b)
                tf = (a.value == int64(b));
            elseif isnumeric(a) && isa(b, 'tse.Duration')
                tf = (int64(a) == b.value);
            elseif isa(a, 'tse.Duration') && isa(b, 'tse.MIT')
                tf = false;
            elseif isa(a, 'tse.MIT') && isa(b, 'tse.Duration')
                tf = false;
            else
                tf = false;
            end
        end

        function tf = ne(a, b)
            tf = ~eq(a, b);
        end

        function tf = lt(a, b)
            if isa(a, 'tse.Duration') && isa(b, 'tse.Duration')
                if a.frequency ~= b.frequency
                    mixed_freq_error(a.frequency, b.frequency);
                end
                tf = (a.value < b.value);
            elseif isa(a, 'tse.Duration') && isnumeric(b)
                tf = (a.value < int64(b));
            elseif isnumeric(a) && isa(b, 'tse.Duration')
                tf = (int64(a) < b.value);
            elseif isa(a, 'tse.MIT') || isa(b, 'tse.MIT')
                error('tseries:invalidArith', ...
                    'Illegal comparison of Duration and MIT.');
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

        function F = frequencyof(d)
            F = int2freq(d.frequency);
        end

        function s = char(d)
            s = sprintf('%d', double(d.value));
        end

        function s = string(d)
            s = string(char(d));
        end

        function disp(d)
            fprintf('%s\n', char(d));
        end
    end
end

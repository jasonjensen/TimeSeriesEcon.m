classdef MITRange
    %MITRANGE  An ordered, evenly-spaced range of MITs.
    %
    %   MITRange(a, b)       unit-step range [a, b]
    %   MITRange(a, s, b)    step range with integer step s
    %
    %   Supports `length`, `numel`, `isempty`, indexing rng(k), end,
    %   `intersect`, `union`, `ismember`, iteration via `for m = collect(rng)`.

    properties (SetAccess = immutable)
        startMIT
        stopMIT
        stepSize (1,1) int64 = int64(1)
    end

    methods
        function obj = MITRange(a, varargin)
            if nargin == 0
                obj.startMIT = tseries.MIT(tseries.Unit(), 1);
                obj.stopMIT  = tseries.MIT(tseries.Unit(), 0);
                return
            end
            if ~isa(a, 'tseries.MIT')
                error('tseries:noMatch', 'MITRange requires MIT endpoints.');
            end
            switch numel(varargin)
                case 1
                    b = varargin{1};
                    if ~isa(b, 'tseries.MIT')
                        error('tseries:noMatch', 'MITRange requires MIT endpoints.');
                    end
                    if ~eq(a.frequency, b.frequency)
                        mixed_freq_error(a.frequency, b.frequency);
                    end
                    obj.startMIT = a;
                    obj.stopMIT  = b;
                    obj.stepSize = int64(1);
                case 2
                    s = varargin{1};
                    b = varargin{2};
                    if ~isa(b, 'tseries.MIT')
                        error('tseries:noMatch', 'MITRange requires MIT endpoints.');
                    end
                    if ~eq(a.frequency, b.frequency)
                        mixed_freq_error(a.frequency, b.frequency);
                    end
                    if isa(s, 'tseries.Duration')
                        if ~eq(a.frequency, s.frequency)
                            mixed_freq_error(a.frequency, s.frequency);
                        end
                        obj.stepSize = s.value;
                    elseif isnumeric(s)
                        obj.stepSize = int64(s);
                    else
                        error('tseries:invalidArith', 'Step must be integer or Duration.');
                    end
                    obj.startMIT = a;
                    obj.stopMIT  = b;
                otherwise
                    error('tseries:noMatch', 'MITRange takes 2 or 3 arguments.');
            end
        end

        function F = frequencyof(rng)
            F = rng.startMIT.frequency;
        end

        function n = length(rng)
            if rng.stepSize == 1
                n = double(rng.stopMIT.value - rng.startMIT.value + 1);
                if n < 0
                    n = 0;
                end
            else
                diff = rng.stopMIT.value - rng.startMIT.value;
                if (rng.stepSize > 0 && diff < 0) || (rng.stepSize < 0 && diff > 0)
                    n = 0;
                else
                    n = double(idivide(diff, rng.stepSize, 'fix') + 1);
                end
            end
        end

        function n = numel(rng)
            n = length(rng);
        end

        function tf = isempty(rng)
            tf = length(rng) == 0;
        end

        function s = size(rng, dim)
            n = length(rng);
            if nargin < 2
                s = [1, n];
            else
                if dim == 2
                    s = n;
                else
                    s = 1;
                end
            end
        end

        function n = step(rng)
            n = double(rng.stepSize);
        end

        function m = first(rng)
            m = rng.startMIT;
        end

        function m = last(rng)
            if rng.stepSize == 1
                m = rng.stopMIT;
            else
                n = length(rng);
                m = rng(n);
            end
        end

        function ind = end(rng, ~, ~)
            ind = length(rng);
        end

        function n = numArgumentsFromSubscript(~, ~, ~)
            % We always return one result from subsref / subsasgn calls.
            n = 1;
        end

        function out = subsref(rng, S)
            if numel(S) == 1 && strcmp(S(1).type, '()')
                subs = S(1).subs;
                if numel(subs) ~= 1
                    error('tseries:bounds', 'MITRange supports 1-D indexing only.');
                end
                idx = subs{1};
                if ischar(idx) && strcmp(idx, ':')
                    out = collect(rng);
                elseif isnumeric(idx)
                    idx = int64(idx);
                    if any(idx(:) < 1) || any(idx(:) > length(rng))
                        error('tseries:bounds', 'MITRange index out of bounds.');
                    end
                    if isscalar(idx)
                        out = tseries.MIT(rng.startMIT.frequency, ...
                            rng.startMIT.value + (idx - 1) * rng.stepSize);
                    else
                        out = arrayfun(@(k) tseries.MIT(rng.startMIT.frequency, ...
                            rng.startMIT.value + (k - 1) * rng.stepSize), idx);
                    end
                else
                    error('tseries:bounds', 'Unsupported MITRange index type.');
                end
            else
                out = builtin('subsref', rng, S);
            end
        end

        function out = collect(rng)
            n = length(rng);
            if n == 0
                out = tseries.MIT.empty(1,0);
                return
            end
            F = rng.startMIT.frequency;
            out = repmat(tseries.MIT(F, 0), 1, n);
            v0 = rng.startMIT.value;
            for k = 1:n
                out(k) = tseries.MIT(F, v0 + (int64(k) - 1) * rng.stepSize);
            end
        end

        function tf = ismember(rng, m)
            if isa(rng, 'tseries.MITRange') && isa(m, 'tseries.MIT')
                if ~eq(rng.startMIT.frequency, m.frequency)
                    tf = false;
                    return
                end
                if rng.stepSize == 1
                    tf = (m.value >= rng.startMIT.value) && (m.value <= rng.stopMIT.value);
                else
                    diff = m.value - rng.startMIT.value;
                    if rng.stepSize > 0
                        tf = (m.value >= rng.startMIT.value) && (m.value <= rng.stopMIT.value) && rem(diff, rng.stepSize) == 0;
                    else
                        tf = (m.value <= rng.startMIT.value) && (m.value >= rng.stopMIT.value) && rem(diff, rng.stepSize) == 0;
                    end
                end
            elseif isa(rng, 'tseries.MIT') && isa(m, 'tseries.MITRange')
                tf = ismember(m, rng);
            else
                tf = false;
            end
        end

        function r = intersect(a, b)
            if ~isa(a, 'tseries.MITRange') || ~isa(b, 'tseries.MITRange')
                error('tseries:noMatch', 'intersect requires two MITRanges.');
            end
            if a.stepSize ~= 1 || b.stepSize ~= 1
                error('tseries:noMatch', 'intersect on stepped MITRanges not supported.');
            end
            if ~eq(a.startMIT.frequency, b.startMIT.frequency)
                mixed_freq_error(a.startMIT.frequency, b.startMIT.frequency);
            end
            lo = max(a.startMIT.value, b.startMIT.value);
            hi = min(a.stopMIT.value, b.stopMIT.value);
            F  = a.startMIT.frequency;
            r  = tseries.MITRange(tseries.MIT(F, lo), tseries.MIT(F, hi));
        end

        function r = union(a, b)
            if ~isa(a, 'tseries.MITRange') || ~isa(b, 'tseries.MITRange')
                error('tseries:noMatch', 'union requires two MITRanges.');
            end
            if a.stepSize ~= 1 || b.stepSize ~= 1
                error('tseries:noMatch', 'union on stepped MITRanges not supported.');
            end
            if ~eq(a.startMIT.frequency, b.startMIT.frequency)
                mixed_freq_error(a.startMIT.frequency, b.startMIT.frequency);
            end
            lo = min(a.startMIT.value, b.startMIT.value);
            hi = max(a.stopMIT.value, b.stopMIT.value);
            F  = a.startMIT.frequency;
            r  = tseries.MITRange(tseries.MIT(F, lo), tseries.MIT(F, hi));
        end

        function tf = eq(a, b)
            tf = isa(a, 'tseries.MITRange') && isa(b, 'tseries.MITRange') ...
                && eq(a.startMIT, b.startMIT) ...
                && eq(a.stopMIT,  b.stopMIT) ...
                && a.stepSize == b.stepSize;
        end

        function tf = isequal(a, b)
            tf = eq(a, b);
        end

        function rng = plus(a, b)
            if isa(a, 'tseries.MITRange') && (isnumeric(b) || isa(b, 'tseries.Duration'))
                if isa(b, 'tseries.Duration')
                    if ~eq(a.startMIT.frequency, b.frequency)
                        mixed_freq_error(a.startMIT.frequency, b.frequency);
                    end
                    shift = b.value;
                else
                    shift = int64(b);
                end
                F = a.startMIT.frequency;
                rng = tseries.MITRange( ...
                    tseries.MIT(F, a.startMIT.value + shift), ...
                    a.stepSize, ...
                    tseries.MIT(F, a.stopMIT.value  + shift) ...
                );
            elseif (isnumeric(a) || isa(a, 'tseries.Duration')) && isa(b, 'tseries.MITRange')
                rng = plus(b, a);
            else
                error('tseries:invalidArith', 'Invalid operands to MITRange.plus.');
            end
        end

        function rng = minus(a, b)
            if isa(a, 'tseries.MITRange') && (isnumeric(b) || isa(b, 'tseries.Duration'))
                if isa(b, 'tseries.Duration')
                    if ~eq(a.startMIT.frequency, b.frequency)
                        mixed_freq_error(a.startMIT.frequency, b.frequency);
                    end
                    shift = b.value;
                else
                    shift = int64(b);
                end
                F = a.startMIT.frequency;
                rng = tseries.MITRange( ...
                    tseries.MIT(F, a.startMIT.value - shift), ...
                    tseries.MIT(F, a.stopMIT.value  - shift), ...
                    a.stepSize);
            else
                error('tseries:invalidArith', 'Invalid operands to MITRange.minus.');
            end
        end

        function s = char(rng)
            if rng.stepSize == 1
                s = sprintf('%s:%s', char(rng.startMIT), char(rng.stopMIT));
            else
                s = sprintf('%s:%d:%s', char(rng.startMIT), double(rng.stepSize), char(rng.stopMIT));
            end
        end

        function s = string(rng)
            s = string(char(rng));
        end

        function disp(rng)
            F = rng.startMIT.frequency;
            if isa(F, 'tseries.CalendarFrequency') && ~isa(F, 'tseries.YPFrequency') && ~isa(F, 'tseries.Unit')
                fprintf('%s %s\n', prettyprint_frequency(F), char(rng));
            else
                fprintf('%s\n', char(rng));
            end
        end
    end
end

classdef TSeries
    %TSERIES  Univariate time series indexed by MIT.
    %
    %   A TSeries has:
    %     firstdate : the MIT of position 1
    %     values    : a column vector of numeric values
    %
    %   The "stored range" is firstdate .. firstdate + length(values) - 1.
    %
    %   Construction (most useful forms):
    %     TSeries()                      % empty
    %     TSeries(n)                     % Unit frequency, length n
    %     TSeries(type, n)               % Unit frequency, length n, typed
    %     TSeries(mit)                   % empty starting at mit
    %     TSeries(type, mit)             % empty, typed
    %     TSeries(range)                 % NaN-filled
    %     TSeries(type, range)           % typed, NaN-filled
    %     TSeries(range, [])             % alias for "uninitialized"
    %     TSeries(range, undef_marker)   % 'undef' (string) is treated like []
    %     TSeries(range, scalar)         % filled with the scalar
    %     TSeries(range, fn)             % fn(length(range)) initializer
    %     TSeries(mit, vec)              % first date + values
    %     TSeries(range, vec)            % range + matching values
    %
    %   Indexing:
    %     t(i)           integer index (1-based) into values, returns numeric
    %     t(rng_int)     integer range, returns numeric vector
    %     t(:)           returns t itself
    %     t(mit)         MIT index, returns scalar (bounds-checked)
    %     t(mit_rng)     MITRange, returns a new TSeries
    %     t(mit_vec)     vector of MITs, returns numeric vector
    %     t(boolvec)     logical mask, returns numeric vector
    %
    %   Assignment:
    %     t(mit)        = v   grows the series if mit is outside the range
    %     t(mit_rng)    = v   ditto
    %     t(integer)    = v   in-range only (BoundsError on out-of-range)

    properties
        firstdate
        values
        frequency
    end

    methods
        % ---------- constructors ----------

        function obj = TSeries(varargin)
            if nargin == 0
                % Skip the tse.Unit() materialisation -- Unit's int code is 11.
                obj.firstdate = tse.MIT(int32(11), int64(1));
                obj.frequency = int32(11);
                obj.values = zeros(0, 1);
                return
            end

            % Form: TSeries(type, ...) where first arg is a numeric type
            if (ischar(varargin{1}) || isstring(varargin{1})) ...
                    && numel(varargin) >= 2 ...
                    && isTypeName(char(varargin{1}))
                T = char(varargin{1});
                obj = tse.TSeries.fromType(T, varargin(2:end));
                return
            end

            first = varargin{1};
            if isnumeric(first) && isscalar(first) && first >= 0 && first == fix(first)
                % TSeries(n) integer count, Unit frequency
                if nargin > 1
                    error('tseries:noMatch', 'TSeries(n) takes no initializer.');
                end
                obj.firstdate = tse.MIT(int32(11), int64(1));
                obj.frequency = int32(11);
                obj.values = nan(double(first), 1);
                return
            end

            if isa(first, 'tse.MIT')
                if nargin == 1
                    obj.firstdate = first;
                    obj.frequency = obj.firstdate.frequency;
                    obj.values = zeros(0, 1);
                else
                    second = varargin{2};
                    if isnumeric(second)
                        obj.firstdate = first;
                        obj.values = second(:);
                        obj.frequency = obj.firstdate.frequency;
                    elseif islogical(second)
                        obj.firstdate = first;
                        obj.values = second(:);
                        obj.frequency = obj.firstdate.frequency;
                    else
                        error('tseries:noMatch', ...
                            'TSeries(mit, vec) requires a vector of values.');
                    end
                end
                return
            end

            if isa(first, 'tse.MITRange')
                obj = tse.TSeries.fromRange(first, varargin(2:end));
                return
            end

            if isnumeric(first) && ~isscalar(first)
                % Integer range like 1:5 -> Unit-frequency MITRange
                if nargin == 1
                    rng = tse.MITRange( ...
                        tse.MIT(int32(11), int64(first(1))), ...
                        tse.MIT(int32(11), int64(first(end))));
                    obj = tse.TSeries(rng);
                    return
                end
            end

            error('tseries:noMatch', 'Unsupported TSeries() argument signature.');
        end
    end

    methods (Static, Hidden)
        function obj = fromRange(rng, more)
            % helper for TSeries(range, ...)
            if isempty(more)
                obj = tse.TSeries();
                obj.firstdate = rng.startMIT;
                obj.frequency = obj.firstdate.frequency;
                obj.values = nan(length(rng), 1);
                return
            end
            init = more{1};
            obj = tse.TSeries();
            obj.firstdate = rng.startMIT;
            obj.frequency = obj.firstdate.frequency;
            n = length(rng);
            if isempty(init) || (ischar(init) && strcmpi(init, 'undef')) ...
                    || (isstring(init) && strcmpi(init, 'undef'))
                obj.values = nan(n, 1);
            elseif isa(init, 'function_handle')
                obj.values = init(n, 1);
                if ~isvector(obj.values) || numel(obj.values) ~= n
                    obj.values = reshape(obj.values(:), [], 1);
                end
            elseif isnumeric(init) && isscalar(init)
                obj.values = repmat(init, n, 1);
            elseif islogical(init) && isscalar(init)
                obj.values = repmat(init, n, 1);
            elseif (isnumeric(init) || islogical(init)) && ~isscalar(init)
                if numel(init) ~= n
                    error('tseries:noMatch', 'Range and data lengths mismatch.');
                end
                obj.values = init(:);
            else
                error('tseries:noMatch', 'Unsupported initializer for TSeries(range, ...).');
            end
        end

        function obj = fromType(T, args)
            % helper for TSeries(type, ...)
            if isempty(args)
                error('tseries:noMatch', 'TSeries(type, ...) requires more args.');
            end
            first = args{1};
            obj = tse.TSeries();
            if isnumeric(first) && isscalar(first) && first >= 0 && first == fix(first)
                % TSeries(type, n)
                obj.firstdate = tse.MIT(tse.Unit(), 1);
                obj.values = repmat(tse.typenan(T), double(first), 1);
                obj.values = cast(obj.values, T);
                obj.frequency = obj.firstdate.frequency;
                return
            end
            if isa(first, 'tse.MIT')
                if numel(args) == 1
                    obj.firstdate = first;
                    obj.values = zeros(0, 1, T);
                    obj.frequency = obj.firstdate.frequency;
                else
                    second = args{2};
                    if isnumeric(second) || islogical(second)
                        obj.firstdate = first;
                        obj.values = cast(second(:), T);
                        obj.frequency = obj.firstdate.frequency;
                    else
                        error('tseries:noMatch', 'Unsupported TSeries(type, mit, ...) signature.');
                    end
                end
                return
            end
            if isa(first, 'tse.MITRange')
                rng = first;
                n = length(rng);
                obj.firstdate = rng.startMIT;
                obj.frequency = obj.firstdate.frequency;
                if numel(args) == 1
                    obj.values = repmat(tse.typenan(T), n, 1);
                    obj.values = cast(obj.values, T);
                    return
                end
                init = args{2};
                if isempty(init) || (ischar(init) && strcmpi(init, 'undef')) ...
                        || (isstring(init) && strcmpi(init, 'undef'))
                    obj.values = cast(repmat(tse.typenan(T), n, 1), T);
                elseif isnumeric(init) && isscalar(init)
                    obj.values = cast(repmat(init, n, 1), T);
                elseif (isnumeric(init) || islogical(init)) && ~isscalar(init)
                    if numel(init) ~= n
                        error('tseries:noMatch', 'Range and data lengths mismatch.');
                    end
                    obj.values = cast(init(:), T);
                elseif isa(init, 'function_handle')
                    obj.values = cast(init(n, 1), T);
                else
                    error('tseries:noMatch', 'Unsupported TSeries(type, range, ...) signature.');
                end
                return
            end
            if isnumeric(first) && ~isscalar(first)
                % TSeries(type, intRange) e.g. TSeries(UInt8, 4 .+ (1:5))
                if numel(args) == 1
                    rng = tse.MITRange(tse.MIT(tse.Unit(),first(1)), ...
                                            tse.MIT(tse.Unit(),first(end)));
                    obj = tse.TSeries.fromType(T, {rng});
                    return
                else
                    rng = tse.MITRange(tse.MIT(tse.Unit(),first(1)), ...
                                            tse.MIT(tse.Unit(),first(end)));
                    obj = tse.TSeries.fromType(T, [{rng}, args(2:end)]);
                    return
                end
            end
            error('tseries:noMatch', 'Unsupported TSeries(type, ...) signature.');
        end

        function [v, extra] = bdaily_filter_(t, varargin)
        %BDAILY_FILTER_  Extract skip_all_nans/skip_holidays/holidays_map
        %   from varargin, apply cleanedvalues if BDaily, return values
        %   and remaining positional args.
            skipKeys = {'skip_all_nans', 'skip_holidays', 'holidays_map'};
            hasSkip = false;
            skipArgs = {};
            extra = {};
            k = 1;
            while k <= numel(varargin)
                a = varargin{k};
                if (ischar(a) || isstring(a)) && any(strcmpi(a, skipKeys))
                    hasSkip = true;
                    skipArgs{end+1} = char(a); %#ok<AGROW>
                    skipArgs{end+1} = varargin{k+1}; %#ok<AGROW>
                    k = k + 2;
                else
                    extra{end+1} = a; %#ok<AGROW>
                    k = k + 1;
                end
            end
            if hasSkip && isa(tse.frequencyof(t), 'tse.BDaily')
                v = tse.cleanedvalues(t, skipArgs{:});
            else
                v = t.values;
            end
        end
    end

    methods
        % ---------- introspection ----------
        % NB: We do not define a method called firstdate(t) because the
        % property of the same name takes that slot.  Use t.firstdate
        % directly or call tse.firstdate(t).

        function m = lastdate(t)
            m = tse.lastdate(t);
        end

        function F = frequencyof(t)
            F = t.frequency;
        end

        function rng = rangeof(t, varargin)
            rng = tse.rangeof(t, varargin{:});
        end

        function rng = range(t, varargin)
            rng = tse.rangeof(t, varargin{:});
        end

        function n = length(t)
            n = length(t.values);
        end

        function n = numel(t)
            n = numel(t.values);
        end

        function s = size(t, varargin)
            s = size(t.values, varargin{:});
        end

        function tf = isempty(t)
            tf = isempty(t.values);
        end

        function n = numArgumentsFromSubscript(~, ~, ~)
            n = 1;
        end

        function v = rawdata(t)
            v = t.values;
        end

        function v = values_(t)
            v = t.values;
        end

        function tf = isassigned_(t, idx)
            if isa(idx, 'tse.MIT')
                rng = rangeof(t);
                tf = ismember(rng, idx);
            elseif isnumeric(idx)
                tf = (idx >= 1) && (idx <= length(t.values));
            else
                tf = false;
            end
        end

        function ind = end(t, k, ~)
            if k == 1
                ind = lastdate(t);
            else
                ind = 1;
            end
        end

        % ---------- indexing ----------

        function varargout = subsref(t, S)
            if isempty(S)
                varargout = {t};
                return
            end
            type1 = S(1).type;
            if type1(1) == '('
                subs = S(1).subs;
                if numel(subs) ~= 1
                    error('tseries:bounds', ...
                        'TSeries supports 1-D indexing only.');
                end
                idx = subs{1};
                % --- inline fast path: scalar MIT lookup ----------------
                if isa(idx, 'tse.MIT') && isscalar(idx)
                    if idx.frequency ~= t.frequency
                        mixed_freq_error(idx.frequency, t.frequency);
                    end
                    k = idx.value - t.firstdate.value + 1;
                    if k < 1 || k > numel(t.values)
                        error('tseries:bounds', 'MIT %s is out of range.', char(idx));
                    end
                    out = t.values(k);
                    if numel(S) > 1
                        out = subsref(out, S(2:end));
                    end
                    varargout = {out};
                    return
                end
                % --- general dispatcher --------------------------------
                out = tse.TSeries.doGet(t, idx);
                if numel(S) > 1
                    out = subsref(out, S(2:end));
                end
                varargout = {out};
                return
            elseif type1(1) == '.'
                varargout = {builtin('subsref', t, S)};
                return
            else
                error('tseries:bounds', 'Unsupported TSeries indexing.');
            end
        end

        function t = subsasgn(t, S, val)
            if isempty(S)
                t = val;
                return
            end
            if strcmp(S(1).type, '()')
                subs = S(1).subs;
                if numel(subs) ~= 1
                    error('tseries:bounds', ...
                        'TSeries supports 1-D indexing only.');
                end
                idx = subs{1};
                t = tse.TSeries.doSet(t, idx, val);
                return
            elseif strcmp(S(1).type, '.')
                t = builtin('subsasgn', t, S, val);
                return
            else
                error('tseries:bounds', 'Unsupported TSeries assignment.');
            end
        end

        % ---------- low-level utilities ----------

        function t = resize(t, rng)
            % rng: MITRange (new range) or integer (new length, keep firstdate)
            if isa(rng, 'tse.MITRange')
                if ~eq(rng.frequency, t.frequency)
                    mixed_freq_error(rng.frequency, t.frequency);
                end
                fdNew = rng.startMIT;
                nNew  = length(rng);
                T = class(t.values);
                newVals = repmat(tse.typenan(T), nNew, 1);
                newVals = cast(newVals, T);
                fdOld = t.firstdate;
                oldRange = rangeof(t);
                inter = intersect(oldRange, rng);
                if ~isempty(inter)
                    srcStart = double(inter.startMIT.value - fdOld.value) + 1;
                    srcEnd   = srcStart + length(inter) - 1;
                    dstStart = double(inter.startMIT.value - fdNew.value) + 1;
                    dstEnd   = dstStart + length(inter) - 1;
                    newVals(dstStart:dstEnd) = t.values(srcStart:srcEnd);
                end
                t.firstdate = fdNew;
                t.values = newVals;
            elseif isnumeric(rng) && isscalar(rng)
                nNew = double(rng);
                nOld = length(t.values);
                if nNew == nOld
                    return
                elseif nNew < nOld
                    t.values = t.values(1:nNew);
                else
                    T = class(t.values);
                    pad = repmat(tse.typenan(T), nNew - nOld, 1);
                    t.values = [t.values; cast(pad, T)];
                end
            else
                error('tseries:noMatch', 'resize requires a range or integer.');
            end
        end

        % ---------- display ----------

        function disp(t)
            summary_(t);
            if isempty(t.values), return; end
            fprintf(':\n');
            nval = length(t.values);
            rng = rangeof(t);
            maxLabel = 0;
            allMits = collect(rng);
            for k = 1:nval
                s = char(allMits(k));
                if numel(s) > maxLabel, maxLabel = numel(s); end
            end
            limit = 24;
            if nval <= limit
                for k = 1:nval
                    fprintf('    %s : %g\n', lpad(char(allMits(k)), maxLabel), ...
                        double(t.values(k)));
                end
            else
                top = floor(limit/2);
                bot = nval - (limit - top) + 1;
                for k = 1:top
                    fprintf('    %s : %g\n', lpad(char(allMits(k)), maxLabel), ...
                        double(t.values(k)));
                end
                fprintf('       ...\n');
                for k = bot:nval
                    fprintf('    %s : %g\n', lpad(char(allMits(k)), maxLabel), ...
                        double(t.values(k)));
                end
            end
        end

        function s = summary(t)
            s = summaryStr(t);
        end

        % ---------- plotting ----------

        function varargout = plot(t, varargin)
            % plot(t, 'mit_loc', loc, 'trange', rng, <line opts>)
            %
            % Mirrors the one_tseries plot recipe from TimeSeriesEcon.jl.
            % 'mit_loc' is 'left' (default), 'middle', or 'right'; 'trange'
            % restricts the plotted range.  Remaining options pass through
            % to the built-in plot.
            [mit_loc, trange, rest] = tsPlotArgs(varargin);
            rng = rangeof(t);
            if ~isempty(trange)
                rng = intersect(trange, rng);
            end
            [x, kind] = mit_xcoords(rng, mit_loc);
            y = tse.lookup(t, rng);
            h = plot(x, y, rest{:});
            if strcmp(kind, 'yp')
                mit_yp_ticklabels(ancestor(h(1), 'axes'), int2freq(t.frequency), mit_loc);
            end
            if nargout > 0, varargout = {h}; end
        end

        % ---------- arithmetic ----------

        function r = plus(a, b)
            r = binaryOp(a, b, @plus);
        end

        function r = minus(a, b)
            r = binaryOp(a, b, @minus);
        end

        function r = times(a, b)
            r = binaryOp(a, b, @times);
        end

        function r = rdivide(a, b)
            r = binaryOp(a, b, @rdivide);
        end

        function r = ldivide(a, b)
            r = binaryOp(a, b, @ldivide);
        end

        function r = power(a, b)
            r = binaryOp(a, b, @power);
        end

        function r = uminus(t)
            r = t;
            r.values = -t.values;
        end

        function r = uplus(t)
            r = t;
        end

        function r = mtimes(a, b)
            % Scalar * TSeries / TSeries * scalar => element-wise.
            % Anything else defers to numeric mtimes (will usually error
            % for vector*vector, which matches Julia behaviour).
            if isa(a, 'tse.TSeries') && isscalar(b) && isnumeric(b)
                r = a;
                r.values = a.values * b;
                return
            end
            if isa(b, 'tse.TSeries') && isscalar(a) && isnumeric(a)
                r = b;
                r.values = a * b.values;
                return
            end
            va = tseriesValues(a);
            vb = tseriesValues(b);
            r = va * vb;
        end

        function r = mrdivide(a, b)
            if isa(a, 'tse.TSeries') && isscalar(b) && isnumeric(b)
                r = a;
                r.values = a.values / b;
                return
            end
            r = tseriesValues(a) / tseriesValues(b);
        end

        function r = mldivide(a, b)
            if isa(b, 'tse.TSeries') && isscalar(a) && isnumeric(a)
                r = b;
                r.values = a \ b.values;
                return
            end
            r = tseriesValues(a) \ tseriesValues(b);
        end

        % ---------- comparison (element-wise) ----------

        function r = eq(a, b)
            r = binaryOp(a, b, @eq);
        end

        function r = ne(a, b)
            r = binaryOp(a, b, @ne);
        end

        function r = lt(a, b)
            r = binaryOp(a, b, @lt);
        end

        function r = le(a, b)
            r = binaryOp(a, b, @le);
        end

        function r = gt(a, b)
            r = binaryOp(a, b, @gt);
        end

        function r = ge(a, b)
            r = binaryOp(a, b, @ge);
        end

        function tf = isequal(a, b)
            if ~isa(a, 'tse.TSeries') || ~isa(b, 'tse.TSeries')
                tf = false; return
            end
            tf = eq(a.firstdate, b.firstdate) ...
                && isequal(a.values, b.values);
        end

        function tf = isequaln(a, b)
            if ~isa(a, 'tse.TSeries') || ~isa(b, 'tse.TSeries')
                tf = false; return
            end
            tf = eq(a.firstdate, b.firstdate) ...
                && isequaln(a.values, b.values);
        end

        % ---------- reductions ----------
        % Hoist t.values into a local so the property read only goes
        % through subsref once.  (For overridden subsref classes, every
        % `t.values` access costs ~µs.)
        %
        % For BDaily series, mean/std/var/median support:
        %   'skip_all_nans', 'skip_holidays', 'holidays_map'

        function r = sum(t, varargin),    v = t.values; r = sum(v, varargin{:});    end
        function r = prod(t, varargin),   v = t.values; r = prod(v, varargin{:});   end

        function r = mean(t, varargin)
            [v, extra] = tse.TSeries.bdaily_filter_(t, varargin{:});
            r = mean(v, extra{:});
        end
        function r = median(t, varargin)
            [v, extra] = tse.TSeries.bdaily_filter_(t, varargin{:});
            r = median(v, extra{:});
        end
        function r = std(t, varargin)
            [v, extra] = tse.TSeries.bdaily_filter_(t, varargin{:});
            r = std(v, extra{:});
        end
        function r = var(t, varargin)
            [v, extra] = tse.TSeries.bdaily_filter_(t, varargin{:});
            r = var(v, extra{:});
        end
        function r = quantile(t, p, varargin)
            [v, extra] = tse.TSeries.bdaily_filter_(t, varargin{:});
            r = quantile(v, p, extra{:});
        end
        function r = cov(t, varargin)
            % cov(t) or cov(t, t2) with optional skip options
            if nargin >= 2 && isa(varargin{1}, 'tse.TSeries')
                t2 = varargin{1};
                [v1, extra] = tse.TSeries.bdaily_filter_(t, varargin{2:end});
                [v2, ~]     = tse.TSeries.bdaily_filter_(t2, varargin{2:end});
                r = cov(v1, v2, extra{:});
            else
                [v, extra] = tse.TSeries.bdaily_filter_(t, varargin{:});
                r = cov(v, extra{:});
            end
        end
        function r = cor(t, varargin)
            % cor(t) or cor(t, t2) with optional skip options
            if nargin >= 2 && isa(varargin{1}, 'tse.TSeries')
                t2 = varargin{1};
                [v1, extra] = tse.TSeries.bdaily_filter_(t, varargin{2:end});
                [v2, ~]     = tse.TSeries.bdaily_filter_(t2, varargin{2:end});
                r = corr(v1, v2, extra{:});
            else
                [v, extra] = tse.TSeries.bdaily_filter_(t, varargin{:});
                r = corr(v, extra{:});
            end
        end

        function r = min(t, varargin),    v = t.values; r = min(v, varargin{:});    end
        function r = max(t, varargin),    v = t.values; r = max(v, varargin{:});    end
        function r = any(t, varargin),    v = t.values; r = any(v, varargin{:});    end
        function r = all(t, varargin),    v = t.values; r = all(v, varargin{:});    end

        % ---------- cumulative / difference ----------

        function r = cumsum(t, varargin)
            r = t;
            r.values = cumsum(t.values, varargin{:});
        end

        function r = cumprod(t, varargin)
            r = t;
            r.values = cumprod(t.values, varargin{:});
        end

        % NB: not overriding `diff` because Julia's diff has a different
        % sign convention from MATLAB's.  Use tse.diff_ts() or the
        % diff_ts method below.
        function r = diff_ts(t, k)
            % Direct-formula implementation that skips the intermediate
            % `t - lag(t, -k)` binary-op chain.
            if nargin < 2, k = -1; end
            v = t.values;
            n = numel(v);
            F = t.frequency;
            fdv = t.firstdate.value;
            if k < 0
                absk = -k;
                if absk >= n
                    r = tse.TSeries(tse.MIT(F, fdv + int64(absk)));
                    return
                end
                out = v(absk+1:end) - v(1:end-absk);
                fd  = tse.MIT(F, fdv + int64(absk));
            else
                if k >= n
                    r = tse.TSeries(tse.MIT(F, fdv));
                    return
                end
                out = v(1:end-k) - v(k+1:end);
                fd  = tse.MIT(F, fdv);
            end
            r = tse.TSeries(fd, out);
        end

        % ---------- shift / lag / lead ----------

        function r = shift(t, k)
            % Shift dates by k (negative = lag, positive = lead).
            % Fast path: bypass MIT.minus (which allocates a new MIT via
            % the public constructor with arg dispatch).
            r = t;
            r.firstdate = tse.MIT(t.frequency, t.firstdate.value - int64(k));
        end

        function r = lag(t, k)
            if nargin < 2, k = 1; end
            r = t;
            r.firstdate = tse.MIT(t.frequency, t.firstdate.value + int64(k));
        end

        function r = lead(t, k)
            if nargin < 2, k = 1; end
            r = t;
            r.firstdate = tse.MIT(t.frequency, t.firstdate.value - int64(k));
        end

        % ---------- percent change ----------

        function r = pct(t, shiftValue, varargin)
            % pct(t, shift_value=-1, 'islog', false)
            %
            % Direct numeric implementation: avoids the four binary-op
            % chain (shift -> minus -> rdivide -> times -> mtimes).
            if nargin < 2, shiftValue = -1; end
            islog = false;
            if ~isempty(varargin)
                p = inputParser; addParameter(p, 'islog', false);
                parse(p, varargin{:});
                islog = p.Results.islog;
            end
            v = t.values;
            if islog, v = exp(v); end
            n = numel(v);
            F = t.frequency;
            fdv = t.firstdate.value;
            if shiftValue < 0
                k = -shiftValue;
                if k >= n
                    r = tse.TSeries(tse.MIT(F, fdv + int64(k)));
                    return
                end
                a = v(k+1:end);
                b = v(1:end-k);
                fd = tse.MIT(F, fdv + int64(k));
            else
                k = shiftValue;
                if k >= n
                    r = tse.TSeries(tse.MIT(F, fdv));
                    return
                end
                a = v(1:end-k);
                b = v(k+1:end);
                fd = tse.MIT(F, fdv);
            end
            r = tse.TSeries(fd, (a - b) ./ b * 100);
        end

        function r = apct(t, islog)
            if nargin < 2, islog = false; end
            F = t.frequency;
            if F < 32
                error('tseries:noMatch', 'apct for frequency %s not implemented.', class(tse.int2freq(F)));
            end
            N = periodsPerYear(F);
            v = t.values;
            if islog, v = exp(v); end
            n = numel(v);
            if n < 2
                r = tse.TSeries(tse.MIT(F, t.firstdate.value + 1));
                return
            end
            a = v(2:end);
            b = v(1:end-1);
            out = ((a ./ b) .^ N - 1) * 100;
            r = tse.TSeries(tse.MIT(F, t.firstdate.value + 1), out);
        end

        function r = ytypct(t)
            F = t.frequency;
            if F < 32
                error('tseries:noMatch', 'ytypct for frequency %s not implemented.', class(tse.int2freq(F)));
            end
            N = periodsPerYear(F);
            v = t.values;
            n = numel(v);
            if N >= n
                r = tse.TSeries(tse.MIT(F, t.firstdate.value + int64(N)));
                return
            end
            a = v(N+1:end);
            b = v(1:end-N);
            out = (a ./ b - 1) * 100;
            r = tse.TSeries(tse.MIT(F, t.firstdate.value + int64(N)), out);
        end

        % ---------- moving ----------

        function r = moving_sum(t, n)
            r = movingSumImpl(t, n, false);
        end

        function r = moving_average(t, n)
            r = movingSumImpl(t, n, true);
        end

        function r = moving(t, n)
            r = movingSumImpl(t, n, true);
        end

        % ---------- conversion ----------

        function v = double(t)
            v = double(t.values);
        end

        function tf = islogical(t)
            tf = islogical(t.values);
        end

        function tf = isnumeric(t)
            tf = isnumeric(t.values);
        end

        function r = copy(t)
            r = t;
        end

        % ---------- linear algebra (delegate to .values) ----------

        function r = ctranspose(t)
            r = t.values';
        end

        function r = transpose(t)
            r = t.values.';
        end

        function r = adjoint(t)
            r = t.values';
        end

        function p = parent(t)
            p = t.values;
        end

        function ax = axes1(t)
            ax = rangeof(t);
        end

        function L = LinearIndices(t)
            L = 1:numel(t.values);
        end

        % ---------- find / isassigned ----------

        function out = find(t, varargin)
            % find(t) returns MITs of nonzero entries.  Pass-through extra
            % args (e.g. n, 'first') falls back to integer indices then
            % converts.
            idx = find(t.values, varargin{:});
            n = numel(idx);
            if n == 0
                out = tse.MIT.empty(1, 0);
                return
            end
            F = t.frequency;
            v0 = t.firstdate.value;
            out = repmat(tse.MIT(F, 0), 1, n);
            for k = 1:n
                out(k) = tse.MIT(F, v0 + int64(idx(k)) - 1);
            end
        end

        function tf = isassigned(t, idx)
            if nargin < 2 || isempty(idx)
                tf = false; return
            end
            if isa(idx, 'tse.MIT')
                % keyboard
                if ~eq(idx.frequency, t.frequency)
                    error('tseries:mixedFreq', ...
                        'isassigned: mixed frequencies.');
                end
                k = double(idx.value - t.firstdate.value) + 1;
                tf = (k >= 1) && (k <= length(t.values));
                return
            end
            if isnumeric(idx) && isscalar(idx)
                tf = (idx >= 1) && (idx <= length(t.values));
                return
            end
            tf = false;
        end
    end

    methods (Static, Access = private)
        function out = doGet(t, idx)
            % Single-dispatch on index type: one class() lookup, no isa() chain.
            switch class(idx)
                case 'tse.MIT'
                    if isscalar(idx)
                        if idx.frequency ~= t.frequency
                            mixed_freq_error(idx.frequency, t.frequency);
                        end
                        k = idx.value - t.firstdate.value + 1;
                        if k < 1 || k > length(t.values)
                            error('tseries:bounds', 'MIT %s is out of range.', char(idx));
                        end
                        out = t.values(k);
                    else
                        out = doMitVecGet(t, idx);
                    end
                case 'tse.MITRange'
                    if idx.frequency ~= t.frequency
                        mixed_freq_error(idx.frequency, t.frequency);
                    end
                    kStart = double(idx.startMIT.value - t.firstdate.value) + 1;
                    kEnd   = double(idx.stopMIT.value  - t.firstdate.value) + 1;
                    if kStart < 1 || kEnd > length(t.values)
                        error('tseries:bounds', 'Range %s is outside %s.', ...
                            char(idx), char(rangeof(t)));
                    end
                    if idx.stepSize == 1
                        out = tse.TSeries();
                        out.firstdate = idx.startMIT;
                        out.values = t.values(kStart:kEnd);
                        out.frequency = t.frequency;
                    else
                        step = double(idx.stepSize);
                        out = t.values(kStart:step:kEnd);
                    end
                case 'tse.TSeries'
                    if ~islogical(idx.values)
                        error('tseries:bounds', 'TSeries index must have logical values.');
                    end
                    if idx.frequency ~= t.frequency
                        mixed_freq_error(idx.frequency, t.frequency);
                    end
                    rng = intersect(rangeof(t), rangeof(idx));
                    if isempty(rng)
                        out = zeros(0, 1, class(t.values));
                        return
                    end
                    kT = double(rng.startMIT.value - t.firstdate.value) + 1;
                    nL = length(rng);
                    kI = double(rng.startMIT.value - idx.firstdate.value) + 1;
                    mask = idx.values(kI : kI + nL - 1);
                    out = t.values(kT - 1 + find(mask));
                case 'char'
                    if strcmp(idx, ':')
                        out = t;
                    else
                        error('tseries:bounds', 'Unsupported char index ''%s''.', idx);
                    end
                case 'logical'
                    if numel(idx) ~= length(t.values)
                        error('tseries:bounds', 'Boolean index length mismatch.');
                    end
                    out = t.values(idx);
                case {'double','single','int8','uint8','int16','uint16', ...
                        'int32','uint32','int64','uint64'}
                    idx = double(idx);
                    if any(idx(:) < 1) || any(idx(:) > length(t.values))
                        error('tseries:bounds', 'Integer index out of range.');
                    end
                    out = t.values(idx);
                otherwise
                    error('tseries:bounds', 'Unsupported TSeries index of type %s.', class(idx));
            end
        end

        function t = doSet(t, idx, val)
            % Single-dispatch on index type.
            switch class(idx)
                case 'tse.MIT'
                    if isscalar(idx)
                        if idx.frequency ~= t.frequency
                            mixed_freq_error(idx.frequency, t.frequency);
                        end
                        if ~ismember(rangeof(t), idx)
                            t = resize(t, tse.rangeof_span(rangeof(t), idx));
                        end
                        k = double(idx.value - t.firstdate.value) + 1;
                        if isa(val, 'tse.TSeries')
                            sub = tse.TSeries.doGet(val, idx);
                            t.values(k) = sub;
                        else
                            t.values(k) = val;
                        end
                    else
                        % Vector of MITs.
                        for kk = 1:numel(idx)
                            m = idx(kk);
                            if m.frequency ~= t.frequency
                                mixed_freq_error(m.frequency, t.frequency);
                            end
                            if ~ismember(rangeof(t), m)
                                t = resize(t, tse.rangeof_span(rangeof(t), m));
                            end
                            pos = double(m.value - t.firstdate.value) + 1;
                            if isscalar(val)
                                t.values(pos) = val;
                            else
                                t.values(pos) = val(kk);
                            end
                        end
                    end
                case 'tse.MITRange'
                    if idx.frequency ~= t.frequency
                        mixed_freq_error(idx.frequency, t.frequency);
                    end
                    if ~issubrange(idx, rangeof(t))
                        t = resize(t, tse.rangeof_span(rangeof(t), idx));
                    end
                    kStart =(idx.startMIT.value - t.firstdate.value) + 1;
                    kEnd   =(idx.stopMIT.value  - t.firstdate.value) + 1;
                    if idx.stepSize == 1
                        if isa(val, 'tse.TSeries')
                            if val.frequency ~= t.frequency
                                mixed_freq_error(val.frequency, t.frequency);
                            end
                            sub = tse.TSeries.doGet(val, idx);
                            t.values(kStart:kEnd) = sub.values;
                        elseif isscalar(val)
                            t.values(kStart:kEnd) = val;
                        else
                            if numel(val) ~= (kEnd - kStart + 1)
                                error('tseries:dimMismatch', ...
                                    'Vector length does not match range length.');
                            end
                            t.values(kStart:kEnd) = val(:);
                        end
                    else
                        step = double(idx.stepSize);
                        if isa(val, 'tse.TSeries')
                            sub = tse.TSeries.doGet(val, idx);
                            t.values(kStart:step:kEnd) = sub;
                        elseif isscalar(val)
                            t.values(kStart:step:kEnd) = val;
                        else
                            t.values(kStart:step:kEnd) = val(:);
                        end
                    end
                case 'tse.TSeries'
                    if ~islogical(idx.values)
                        error('tseries:bounds', 'TSeries index must have logical values.');
                    end
                    if idx.frequency ~= t.frequency
                        mixed_freq_error(idx.frequency, t.frequency);
                    end
                    rng = intersect(rangeof(t), rangeof(idx));
                    kT = double(rng.startMIT.value - t.firstdate.value) + 1;
                    nL = length(rng);
                    kI = double(rng.startMIT.value - idx.firstdate.value) + 1;
                    mask = idx.values(kI : kI + nL - 1);
                    targetIdx = kT - 1 + find(mask);
                    if isscalar(val)
                        t.values(targetIdx) = val;
                    else
                        t.values(targetIdx) = val(:);
                    end
                case 'char'
                    if strcmp(idx, ':')
                        if isscalar(val)
                            t.values(:) = val;
                        else
                            if numel(val) ~= length(t.values)
                                error('tseries:dimMismatch', 'Length mismatch on (:) assignment.');
                            end
                            t.values(:) = val(:);
                        end
                    else
                        error('tseries:bounds', 'Unsupported char index ''%s''.', idx);
                    end
                case 'logical'
                    if numel(idx) ~= length(t.values)
                        error('tseries:bounds', 'Boolean index length mismatch.');
                    end
                    t.values(idx) = val;
                case {'double','single','int8','uint8','int16','uint16', ...
                        'int32','uint32','int64','uint64'}
                    idx = double(idx);
                    if any(idx(:) < 1) || any(idx(:) > length(t.values))
                        error('tseries:bounds', 'Integer index out of range.');
                    end
                    t.values(idx) = val;
                otherwise
                    error('tseries:bounds', 'Unsupported TSeries index of type %s.', class(idx));
            end
        end
    end
end

% ---------- file-local helpers ----------

function tf = isTypeName(s)
    tf = ismember(s, {'double','single','logical', ...
        'int8','uint8','int16','uint16','int32','uint32','int64','uint64'});
end

function [mit_loc, trange, rest] = tsPlotArgs(args)
% Pull 'mit_loc' and 'trange' name-value pairs out of a plot arg list,
% leaving the rest to pass through to the built-in plot.
    mit_loc = 'left';
    trange  = [];
    rest    = {};
    k = 1;
    while k <= numel(args)
        a = args{k};
        if (ischar(a) || isstring(a)) && k < numel(args) && strcmpi(a, 'mit_loc')
            mit_loc = char(args{k+1});
            k = k + 2;
        elseif (ischar(a) || isstring(a)) && k < numel(args) && strcmpi(a, 'trange')
            trange = args{k+1};
            k = k + 2;
        else
            rest{end+1} = a; %#ok<AGROW>
            k = k + 1;
        end
    end
end

function s = lpad(str, n)
    if numel(str) < n
        s = [repmat(' ', 1, n - numel(str)), str];
    else
        s = str;
    end
end

function summary_(t)
    cls = class(t.values);
    et = '';
    if ~strcmp(cls, 'double')
        et = sprintf(',%s', cls);
    end
    Fname = char(int2freq(t.frequency));
    typestr = sprintf('TSeries{%s%s}', Fname, et);
    if isempty(t)
        fprintf('Empty %s starting %s', typestr, char(t.firstdate));
    else
        fprintf('%d-element %s with range %s', length(t.values), typestr, ...
            char(rangeof(t)));
    end
end

function s = summaryStr(t)
    cls = class(t.values);
    et = '';
    if ~strcmp(cls, 'double')
        et = sprintf(',%s', cls);
    end
    Fname = char(int2freq(t.frequency));
    typestr = sprintf('TSeries{%s%s}', Fname, et);
    if isempty(t)
        s = sprintf('Empty %s starting %s', typestr, char(t.firstdate));
    else
        s = sprintf('%d-element %s with range %s', length(t.values), typestr, ...
            char(rangeof(t)));
    end
end

function out = doMitVecGet(t, mits)
    out = zeros(numel(mits), 1, class(t.values));
    for k = 1:numel(mits)
        m = mits(k);
        if ~eq(m.frequency, t.frequency)
            mixed_freq_error(m.frequency, t.frequency);
        end
        ki = double(m.value - t.firstdate.value) + 1;
        if ki < 1 || ki > length(t.values)
            error('tseries:bounds', 'MIT index out of range.');
        end
        out(k) = t.values(ki);
    end
end

function tf = issubrange(child, parent)
    if isa(parent, 'tse.MITRange') && isa(child, 'tse.MITRange')
        tf = (child.startMIT.value >= parent.startMIT.value) && ...
             (child.stopMIT.value  <= parent.stopMIT.value);
    else
        tf = false;
    end
end

% ---------- binary-op alignment helper ----------

function r = binaryOp(a, b, op)
% Apply op element-wise on numeric storage, returning a TSeries when at
% least one input is a TSeries.  Mixed frequencies error.
%
% Performance: this is the hottest path in the package.  It avoids
% materialising MITRange objects, works in int64 bounds throughout, and
% short-circuits when ranges are identical to a single vector op.

    aIsTS = isa(a, 'tse.TSeries');
    bIsTS = isa(b, 'tse.TSeries');

    if aIsTS && bIsTS
        if a.frequency ~= b.frequency
            mixed_freq_error(a.frequency, b.frequency);
        end
        fa = a.firstdate.value;
        fb = b.firstdate.value;
        na = numel(a.values);
        nb = numel(b.values);
        % --- fast path: identical ranges ------------------------------
        if fa == fb && na == nb
            r = a;
            r.values = op(a.values, b.values);
            return
        end
        % --- general path: intersect on int64 -------------------------
        lo = max(fa, fb);
        hi = min(fa + int64(na) - 1, fb + int64(nb) - 1);
        F  = a.frequency;
        if hi < lo
            r = tse.TSeries(tse.MIT(F, lo));
            return
        end
        kA = double(lo - fa) + 1;
        kB = double(lo - fb) + 1;
        nL = double(hi - lo + 1);
        va = a.values(kA : kA + nL - 1);
        vb = b.values(kB : kB + nL - 1);
        r = tse.TSeries(tse.MIT(F, lo), op(va, vb));
        return
    end

    if aIsTS
        va = a.values;
        if isnumeric(b) || islogical(b)
            if isscalar(b)
                r = a;
                r.values = op(va, b);
            elseif numel(b) == numel(va)
                r = a;
                r.values = op(va, b(:));
            else
                error('tseries:dimMismatch', ...
                    'Vector length %d does not match TSeries length %d.', ...
                    numel(b), numel(va));
            end
            return
        end
    end
    if bIsTS
        vb = b.values;
        if isnumeric(a) || islogical(a)
            if isscalar(a)
                r = b;
                r.values = op(a, vb);
            elseif numel(a) == numel(vb)
                r = b;
                r.values = op(a(:), vb);
            else
                error('tseries:dimMismatch', ...
                    'Vector length %d does not match TSeries length %d.', ...
                    numel(a), numel(vb));
            end
            return
        end
    end
    error('tseries:noMatch', 'Unsupported binary operands for TSeries.');
end

function v = tseriesValues(x)
% Helper: extract numeric storage from a TSeries / MVTSeries / plain array.
    if isa(x, 'tse.TSeries') || isa(x, 'tse.MVTSeries')
        v = x.values;
    else
        v = x;
    end
end

function r = movingSumImpl(t, n, avg)
    if ~(isnumeric(n) && isscalar(n) && n ~= 0 && n == fix(n))
        error('tseries:noMatch', 'moving window n must be a non-zero integer.');
    end
    n = double(n);
    an = abs(n);
    len = length(t.values) - an;
    if len < 0
        error('tseries:dimMismatch', 'Window %d is larger than the series length.', an);
    end
    if n > 0
        startDate = t.firstdate + (n - 1);
    else
        startDate = t.firstdate;
    end
    cls = class(t.values);
    out = zeros(len + 1, 1, cls);
    for i = 1:an
        out = out + t.values(i : i + len);
    end
    if avg
        out = out / an;
    end
    r = tse.TSeries(startDate, out);
end

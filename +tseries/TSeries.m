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
    end

    methods
        % ---------- constructors ----------

        function obj = TSeries(varargin)
            if nargin == 0
                obj.firstdate = tseries.MIT(tseries.Unit(), 1);
                obj.values = zeros(0, 1);
                return
            end

            % Form: TSeries(type, ...) where first arg is a numeric type
            if (ischar(varargin{1}) || isstring(varargin{1})) ...
                    && numel(varargin) >= 2 ...
                    && isTypeName(char(varargin{1}))
                T = char(varargin{1});
                obj = tseries.TSeries.fromType(T, varargin(2:end));
                return
            end

            first = varargin{1};
            if isnumeric(first) && isscalar(first) && first >= 0 && first == fix(first)
                % TSeries(n) integer count, Unit frequency
                if nargin > 1
                    error('tseries:noMatch', 'TSeries(n) takes no initializer.');
                end
                obj.firstdate = tseries.MIT(tseries.Unit(), 1);
                obj.values = nan(double(first), 1);
                return
            end

            if isa(first, 'tseries.MIT')
                if nargin == 1
                    obj.firstdate = first;
                    obj.values = zeros(0, 1);
                else
                    second = varargin{2};
                    if isnumeric(second) && ~isscalar(second)
                        obj.firstdate = first;
                        obj.values = second(:);
                    elseif islogical(second) && ~isscalar(second)
                        obj.firstdate = first;
                        obj.values = second(:);
                    else
                        error('tseries:noMatch', ...
                            'TSeries(mit, vec) requires a vector of values.');
                    end
                end
                return
            end

            if isa(first, 'tseries.MITRange')
                obj = tseries.TSeries.fromRange(first, varargin(2:end));
                return
            end

            if isnumeric(first) && ~isscalar(first)
                % Integer range like 1:5 -> Unit-frequency MITRange
                if nargin == 1
                    rng = tseries.MITRange(tseries.MIT(tseries.Unit(),first(1)), ...
                                            tseries.MIT(tseries.Unit(),first(end)));
                    obj = tseries.TSeries(rng);
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
                obj = tseries.TSeries();
                obj.firstdate = rng.startMIT;
                obj.values = nan(length(rng), 1);
                return
            end
            init = more{1};
            obj = tseries.TSeries();
            obj.firstdate = rng.startMIT;
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
            obj = tseries.TSeries();
            if isnumeric(first) && isscalar(first) && first >= 0 && first == fix(first)
                % TSeries(type, n)
                obj.firstdate = tseries.MIT(tseries.Unit(), 1);
                obj.values = repmat(tseries.typenan(T), double(first), 1);
                obj.values = cast(obj.values, T);
                return
            end
            if isa(first, 'tseries.MIT')
                if numel(args) == 1
                    obj.firstdate = first;
                    obj.values = zeros(0, 1, T);
                else
                    second = args{2};
                    if isnumeric(second) || islogical(second)
                        obj.firstdate = first;
                        obj.values = cast(second(:), T);
                    else
                        error('tseries:noMatch', 'Unsupported TSeries(type, mit, ...) signature.');
                    end
                end
                return
            end
            if isa(first, 'tseries.MITRange')
                rng = first;
                n = length(rng);
                obj.firstdate = rng.startMIT;
                if numel(args) == 1
                    obj.values = repmat(tseries.typenan(T), n, 1);
                    obj.values = cast(obj.values, T);
                    return
                end
                init = args{2};
                if isempty(init) || (ischar(init) && strcmpi(init, 'undef')) ...
                        || (isstring(init) && strcmpi(init, 'undef'))
                    obj.values = cast(repmat(tseries.typenan(T), n, 1), T);
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
                    rng = tseries.MITRange(tseries.MIT(tseries.Unit(),first(1)), ...
                                            tseries.MIT(tseries.Unit(),first(end)));
                    obj = tseries.TSeries.fromType(T, {rng});
                    return
                else
                    rng = tseries.MITRange(tseries.MIT(tseries.Unit(),first(1)), ...
                                            tseries.MIT(tseries.Unit(),first(end)));
                    obj = tseries.TSeries.fromType(T, [{rng}, args(2:end)]);
                    return
                end
            end
            error('tseries:noMatch', 'Unsupported TSeries(type, ...) signature.');
        end
    end

    methods
        % ---------- introspection ----------
        % NB: We do not define a method called firstdate(t) because the
        % property of the same name takes that slot.  Use t.firstdate
        % directly or call tseries.firstdate(t).

        function m = lastdate(t)
            m = tseries.lastdate(t);
        end

        function F = frequencyof(t)
            F = t.firstdate.frequency;
        end

        function rng = rangeof(t, varargin)
            rng = tseries.rangeof(t, varargin{:});
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
            if isa(idx, 'tseries.MIT')
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
            if strcmp(S(1).type, '()')
                subs = S(1).subs;
                if numel(subs) ~= 1
                    error('tseries:bounds', ...
                        'TSeries supports 1-D indexing only.');
                end
                idx = subs{1};
                out = tseries.TSeries.doGet(t, idx);
                if numel(S) > 1
                    out = subsref(out, S(2:end));
                end
                varargout = {out};
                return
            elseif strcmp(S(1).type, '.')
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
                t = tseries.TSeries.doSet(t, idx, val);
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
            if isa(rng, 'tseries.MITRange')
                if ~eq(rng.startMIT.frequency, t.firstdate.frequency)
                    mixed_freq_error(rng.startMIT.frequency, t.firstdate.frequency);
                end
                fdNew = rng.startMIT;
                nNew  = length(rng);
                T = class(t.values);
                newVals = repmat(tseries.typenan(T), nNew, 1);
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
                    pad = repmat(tseries.typenan(T), nNew - nOld, 1);
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
    end

    methods (Static, Access = private)
        function out = doGet(t, idx)
            % Dispatcher for t(idx) reads.
            if isa(idx, 'tseries.MIT')
                if isscalar(idx)
                    if ~eq(idx.frequency, t.firstdate.frequency)
                        mixed_freq_error(idx.frequency, t.firstdate.frequency);
                    end
                    k = double(idx.value - t.firstdate.value) + 1;
                    if k < 1 || k > length(t.values)
                        error('tseries:bounds', 'MIT %s is out of range.', char(idx));
                    end
                    out = t.values(k);
                else
                    out = doMitVecGet(t, idx);
                end
                return
            end
            if isa(idx, 'tseries.MITRange')
                if ~eq(idx.startMIT.frequency, t.firstdate.frequency)
                    mixed_freq_error(idx.startMIT.frequency, t.firstdate.frequency);
                end
                kStart = double(idx.startMIT.value - t.firstdate.value) + 1;
                kEnd   = double(idx.stopMIT.value  - t.firstdate.value) + 1;
                if kStart < 1 || kEnd > length(t.values)
                    error('tseries:bounds', 'Range %s is outside %s.', ...
                        char(idx), char(rangeof(t)));
                end
                if idx.stepSize == 1
                    out = tseries.TSeries();
                    out.firstdate = idx.startMIT;
                    out.values = t.values(kStart:kEnd);
                else
                    step = double(idx.stepSize);
                    out = t.values(kStart:step:kEnd);
                end
                return
            end
            if ischar(idx) && strcmp(idx, ':')
                out = t;
                return
            end
            if islogical(idx)
                if numel(idx) ~= length(t.values)
                    error('tseries:bounds', 'Boolean index length mismatch.');
                end
                out = t.values(idx);
                return
            end
            if isnumeric(idx)
                idx = double(idx);
                if any(idx(:) < 1) || any(idx(:) > length(t.values))
                    error('tseries:bounds', 'Integer index out of range.');
                end
                out = t.values(idx);
                return
            end
            error('tseries:bounds', 'Unsupported TSeries index of type %s.', class(idx));
        end

        function t = doSet(t, idx, val)
            % Dispatcher for t(idx) = val writes.
            if isa(idx, 'tseries.MIT')
                if isscalar(idx)
                    if ~eq(idx.frequency, t.firstdate.frequency)
                        mixed_freq_error(idx.frequency, t.firstdate.frequency);
                    end
                    if ~ismember(rangeof(t), idx)
                        t = resize(t, tseries.rangeof_span(rangeof(t), idx));
                    end
                    k = double(idx.value - t.firstdate.value) + 1;
                    if isa(val, 'tseries.TSeries')
                        sub = tseries.TSeries.doGet(val, idx);
                        t.values(k) = sub;
                    else
                        t.values(k) = val;
                    end
                else
                    % Vector of MITs.
                    for kk = 1:numel(idx)
                        m = idx(kk);
                        if ~eq(m.frequency, t.firstdate.frequency)
                            mixed_freq_error(m.frequency, t.firstdate.frequency);
                        end
                        if ~ismember(rangeof(t), m)
                            t = resize(t, tseries.rangeof_span(rangeof(t), m));
                        end
                        pos = double(m.value - t.firstdate.value) + 1;
                        if isscalar(val)
                            t.values(pos) = val;
                        else
                            t.values(pos) = val(kk);
                        end
                    end
                end
                return
            end
            if isa(idx, 'tseries.MITRange')
                if ~eq(idx.startMIT.frequency, t.firstdate.frequency)
                    mixed_freq_error(idx.startMIT.frequency, t.firstdate.frequency);
                end
                if ~issubrange(idx, rangeof(t))
                    t = resize(t, tseries.rangeof_span(rangeof(t), idx));
                end
                kStart = double(idx.startMIT.value - t.firstdate.value) + 1;
                kEnd   = double(idx.stopMIT.value  - t.firstdate.value) + 1;
                if idx.stepSize == 1
                    if isa(val, 'tseries.TSeries')
                        if ~eq(val.firstdate.frequency, t.firstdate.frequency)
                            mixed_freq_error(val.firstdate.frequency, t.firstdate.frequency);
                        end
                        sub = tseries.TSeries.doGet(val, idx);
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
                    if isa(val, 'tseries.TSeries')
                        sub = tseries.TSeries.doGet(val, idx);
                        t.values(kStart:step:kEnd) = sub;
                    elseif isscalar(val)
                        t.values(kStart:step:kEnd) = val;
                    else
                        t.values(kStart:step:kEnd) = val(:);
                    end
                end
                return
            end
            if ischar(idx) && strcmp(idx, ':')
                if isscalar(val)
                    t.values(:) = val;
                else
                    if numel(val) ~= length(t.values)
                        error('tseries:dimMismatch', 'Length mismatch on (:) assignment.');
                    end
                    t.values(:) = val(:);
                end
                return
            end
            if islogical(idx)
                if numel(idx) ~= length(t.values)
                    error('tseries:bounds', 'Boolean index length mismatch.');
                end
                t.values(idx) = val;
                return
            end
            if isnumeric(idx)
                idx = double(idx);
                if any(idx(:) < 1) || any(idx(:) > length(t.values))
                    error('tseries:bounds', 'Integer index out of range.');
                end
                t.values(idx) = val;
                return
            end
            error('tseries:bounds', 'Unsupported TSeries index of type %s.', class(idx));
        end
    end
end

% ---------- file-local helpers ----------

function tf = isTypeName(s)
    tf = ismember(s, {'double','single','logical', ...
        'int8','uint8','int16','uint16','int32','uint32','int64','uint64'});
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
    Fname = char(t.firstdate.frequency);
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
    Fname = char(t.firstdate.frequency);
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
        if ~eq(m.frequency, t.firstdate.frequency)
            mixed_freq_error(m.frequency, t.firstdate.frequency);
        end
        ki = double(m.value - t.firstdate.value) + 1;
        if ki < 1 || ki > length(t.values)
            error('tseries:bounds', 'MIT index out of range.');
        end
        out(k) = t.values(ki);
    end
end

function tf = issubrange(child, parent)
    if isa(parent, 'tseries.MITRange') && isa(child, 'tseries.MITRange')
        tf = (child.startMIT.value >= parent.startMIT.value) && ...
             (child.stopMIT.value  <= parent.stopMIT.value);
    else
        tf = false;
    end
end

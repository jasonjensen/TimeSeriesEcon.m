classdef NDTSeries
    %NDTSERIES  N-dimensional series with a labelled axis per dimension.
    %
    %   An NDTSeries is an N-d array whose dimensions each carry a
    %   tse.Axis: a date range, a list of names or a plain length, in any
    %   order.  A TSeries is the one-axis case (a date range) and an
    %   MVTSeries the two-axis case (dates, then names).  It is the
    %   TimeSeriesEcon.m counterpart of DataEcon's N-d series.
    %
    %   Properties (read-only):
    %     axes    1-by-N tse.Axis array
    %     values  N-d numeric or logical array, size(values, k) == axes(k).length
    %
    %   Construction:
    %     NDTSeries(axes)                      NaN-filled
    %     NDTSeries(axes, scalar)              filled with the scalar
    %     NDTSeries(axes, values)              values of matching size
    %     NDTSeries(axes, @(sz) ...)           values from a function of the size
    %     NDTSeries(type, axes[, init])        typed, e.g. NDTSeries('int64', axes, 0)
    %     NDTSeries(ts)                        from a tse.TSeries
    %     NDTSeries(mvts)                      from a tse.MVTSeries
    %     NDTSeries(arr)                       from a tse.daec.Array
    %
    %   axes is a tse.Axis array, a single tse.MITRange, or a cell array with
    %   one entry per dimension, each anything tse.Axis accepts: a
    %   tse.MITRange, a list of names, or a length.  For example
    %
    %     x = tse.NDTSeries({qq(2020,1):qq(2021,4), ["gdp" "cpi"], 3}, 0);
    %
    %   Time functions work along the date axis.  When a series has more
    %   than one date axis, pass 'dims', k to say which one.
    %
    %   See also tse.Axis, tse.TSeries, tse.MVTSeries.

    properties (SetAccess = private)
        axes = tse.Axis.empty(1, 0)
        values = zeros(0, 1)
    end

    methods
        % ---------- construction ----------

        function x = NDTSeries(varargin)
            if nargin == 0
                return
            end
            a1 = varargin{1};
            if nargin == 1 && isa(a1, 'tse.NDTSeries')
                x = a1;
                return
            end
            if nargin == 1 && (isa(a1, 'tse.TSeries') || isa(a1, 'tse.MVTSeries') ...
                    || isa(a1, 'tse.daec.Array'))
                [ax, v] = fromObject(a1);
                x.axes = ax;
                x.values = v;
                return
            end

            T = '';
            args = varargin;
            if ischar(a1) || isstring(a1)
                if ~isTypeName(a1)
                    error('tseries:noMatch', ...
                        'NDTSeries: unknown type ''%s''. Give the axes as a cell array.', char(a1));
                end
                T = char(a1);
                args = args(2:end);
                if isempty(args)
                    error('tseries:noMatch', 'NDTSeries(type, axes, ...) needs axes.');
                end
            end

            ax = makeAxes(args{1});
            sz = axesSize(ax);
            if numel(args) > 2
                error('tseries:noMatch', 'Too many arguments to NDTSeries.');
            end

            if numel(args) == 1
                if isempty(T), T = 'double'; end
                v = repmat(tse.typenan(T), sz);
            else
                init = args{2};
                if isa(init, 'function_handle')
                    v = init(sz);
                    checkSize(ax, v);
                elseif (isnumeric(init) || islogical(init)) && isscalar(init) && prod(sz) ~= 1
                    v = repmat(init, sz);
                elseif isnumeric(init) || islogical(init)
                    v = init;
                    checkSize(ax, v);
                else
                    error('tseries:noMatch', ...
                        'NDTSeries values must be numeric or logical, not %s.', class(init));
                end
                if ~isempty(T)
                    v = cast(v, T);
                end
            end
            x.axes = ax;
            x.values = reshape(v, sz);
        end

        % ---------- shape ----------

        function n = naxes(x)
            %NAXES  Number of axes.
            n = numel(x.axes);
        end

        function varargout = size(x, varargin)
            sz = axesSize(x.axes);
            if ~isempty(varargin)
                d = [varargin{:}];
                sz(end+1:max(d)) = 1;
                varargout = {sz(d)};
                return
            end
            if nargout <= 1
                varargout = {sz};
                return
            end
            sz(end+1:nargout) = 1;
            out = num2cell(sz(1:nargout));
            out{end} = prod(sz(nargout:end));
            varargout = out;
        end

        function n = ndims(x)
            n = numel(axesSize(x.axes));
        end

        function n = numel(x, varargin)
            n = numel(x.values);
        end

        function n = length(x)
            if isempty(x.values)
                n = 0;
            else
                n = max(axesSize(x.axes));
            end
        end

        function tf = isempty(x)
            tf = isempty(x.values);
        end

        % ---------- axes ----------

        function k = timedim(x, varargin)
            %TIMEDIM  Index of the date axis.
            %
            %   timedim(x) is the index of the only range axis; it is an
            %   error if there is none or more than one.  timedim(x, 'dims', k)
            %   checks that axis k is a range axis and returns k.
            k = pickTimeDim(x, varargin);
        end

        function n = names(x, k)
            %NAMES  Names along a names axis.
            %
            %   names(x) uses the only names axis; names(x, k) uses axis k.
            if nargin < 2
                k = find([x.axes.kind] == "names");
                if numel(k) ~= 1
                    error('tseries:noMatch', ...
                        'names(x) needs exactly one names axis; this series has %d. Use names(x, k).', ...
                        numel(k));
                end
            end
            if x.axes(k).kind ~= "names"
                error('tseries:noMatch', 'Axis %d is not a names axis.', k);
            end
            n = x.axes(k).names;
        end

        function tf = haskey(x, name)
            %HASKEY  True if any names axis contains name.
            tf = false;
            for k = find([x.axes.kind] == "names")
                if any(x.axes(k).names == string(name))
                    tf = true;
                    return
                end
            end
        end

        function rng = rangeof(x, varargin)
            %RANGEOF  Date range of the date axis ('dims', k; 'drop', n).
            [opts, rest] = splitDims(varargin);
            k = pickTimeDim(x, opts);
            rng = x.axes(k).range;
            if ~isempty(rest)
                rng = tse.rangeof(rng, rest{:});
            end
        end

        function m = firstdate(x, varargin)
            k = pickTimeDim(x, varargin);
            m = x.axes(k).range.startMIT;
        end

        function m = lastdate(x, varargin)
            k = pickTimeDim(x, varargin);
            m = x.axes(k).range.startMIT + (x.axes(k).length - 1);
        end

        function F = frequencyof(x, varargin)
            k = pickTimeDim(x, varargin);
            F = tse.frequencyof(x.axes(k).range);
        end

        % ---------- data access ----------

        function v = rawdata(x),    v = x.values; end
        function v = double(x),     v = double(x.values); end
        function tf = isnumeric(x), tf = isnumeric(x.values); end
        function tf = islogical(x), tf = islogical(x.values); end
        function r = copy(x),       r = x; end

        % ---------- reshaping ----------

        function r = permute(x, order)
            %PERMUTE  Reorder the axes, e.g. permute(x, [2 1 3]).
            n = numel(x.axes);
            if ~isequal(sort(order(:)'), 1:n)
                error('tseries:noMatch', 'permute order must be a permutation of 1:%d.', n);
            end
            r = x;
            r.axes = x.axes(order);
            if n > 1
                r.values = permute(x.values, order);
            end
        end

        function r = squeeze(x)
            %SQUEEZE  Drop axes of length 1 (at least one axis is kept).
            keep = [x.axes.length] ~= 1;
            if ~any(keep)
                keep(1) = true;
            end
            r = x;
            r.axes = x.axes(keep);
            r.values = reshape(x.values, axesSize(r.axes));
        end

        % ---------- conversion ----------

        function s = toseries(x)
            %TOSERIES  Convert to a tse.TSeries or tse.MVTSeries.
            %
            %   One range axis gives a TSeries.  A range axis and a names
            %   axis, in either order, give an MVTSeries.  Other layouts are
            %   an error.
            kinds = [x.axes.kind];
            if isequal(kinds, "range")
                s = tse.TSeries(x.axes(1).firstdate(), x.values);
            elseif isequal(kinds, ["range" "names"])
                s = tse.MVTSeries(class(x.values), x.axes(1).firstdate(), x.axes(2).names, x.values);
            elseif isequal(kinds, ["names" "range"])
                s = toseries(permute(x, [2 1]));
            else
                error('tseries:noMatch', ...
                    ['Only a range axis, or a range axis and a names axis, ' ...
                     'converts to a series; this one has axes [%s].'], strjoin(kinds, ' '));
            end
        end

        % ---------- indexing ----------

        function ind = end(x, k, n)
            %END  Last date of a date axis, or the length of another axis.
            if n ~= numel(x.axes)
                % e.g. x.values(end): MATLAB asks the object, so answer
                % for the values array
                if n == 1
                    ind = numel(x.values);
                else
                    ind = size(x.values, k);
                end
                return
            end
            if x.axes(k).kind == "range"
                ind = x.axes(k).range.startMIT + (x.axes(k).length - 1);
            else
                ind = x.axes(k).length;
            end
        end

        function n = numArgumentsFromSubscript(x, S, ctx)
            if strcmp(S(1).type, '.') && any(strcmp(S(1).subs, {'axes', 'values'}))
                n = builtin('numArgumentsFromSubscript', x, S, ctx);
            else
                n = 1;
            end
        end

        function varargout = subsref(x, S)
            if isempty(S)
                varargout = {x};
                return
            end
            switch S(1).type
                case '.'
                    name = S(1).subs;
                    if any(strcmp(name, {'axes', 'values'}))
                        [varargout{1:nargout}] = builtin('subsref', x, S);
                        return
                    end
                    k = namesAxisOf(x, name);
                    if ~isempty(k)
                        keys = repmat({':'}, 1, numel(x.axes));
                        keys{k} = string(name);
                        out = getKeys(x, keys, false);
                        if numel(S) > 1
                            out = subsref(out, S(2:end));
                        end
                        varargout = {out};
                        return
                    end
                    try
                        [varargout{1:nargout}] = builtin('subsref', x, S);
                    catch ME
                        if any(strcmp(ME.identifier, ...
                                {'MATLAB:nonExistentField', 'MATLAB:noSuchMethodOrField'}))
                            error('tseries:bounds', 'Unknown NDTSeries field or name: %s', name);
                        end
                        rethrow(ME);
                    end
                case '()'
                    out = getKeys(x, S(1).subs, keepTypeOption());
                    if numel(S) > 1
                        out = subsref(out, S(2:end));
                    end
                    varargout = {out};
                otherwise
                    error('tseries:bounds', 'NDTSeries does not support {} indexing.');
            end
        end

        function x = subsasgn(x, S, val)
            if isempty(S)
                x = val;
                return
            end
            if strcmp(S(1).type, '.') && strcmp(S(1).subs, 'axes')
                error('tseries:noMatch', 'NDTSeries axes are read-only.');
            end
            if strcmp(S(1).type, '.') && strcmp(S(1).subs, 'values')
                if numel(S) == 1
                    v = val;
                else
                    v = builtin('subsasgn', x.values, S(2:end), val);
                end
                if ~(isnumeric(v) || islogical(v))
                    error('tseries:noMatch', 'NDTSeries values must be numeric or logical.');
                end
                checkSize(x.axes, v);
                x.values = reshape(v, axesSize(x.axes));
                return
            end
            if numel(S) > 1
                % composite, e.g. x.gdp(mit, 1) = v: read, change, write back
                head = subsref(x, S(1));
                head = subsasgn(head, S(2:end), val);
                x = subsasgn(x, S(1), head);
                return
            end
            switch S(1).type
                case '.'
                    name = S(1).subs;
                    k = namesAxisOf(x, name);
                    if isempty(k)
                        error('tseries:bounds', ...
                            'Unknown name %s; assignment cannot add names.', name);
                    end
                    keys = repmat({':'}, 1, numel(x.axes));
                    keys{k} = string(name);
                    x = setKeys(x, keys, val);
                case '()'
                    x = setKeys(x, S(1).subs, val);
                otherwise
                    error('tseries:bounds', 'NDTSeries does not support {} assignment.');
            end
        end

        function r = resize(x, rng, varargin)
            %RESIZE  Change the range of the date axis, padding with NaN
            %   (or the type's missing value).  resize(x, rng, 'dims', k)
            %   for a series with several date axes.
            k = pickTimeDim(x, varargin);
            r = resizeAxis(x, k, rng);
        end

        function L = LinearIndices(x)
            L = 1:numel(x.values);
        end

        function varargout = find(x, varargin)
            %FIND  Like find on the values array.
            [varargout{1:max(1, nargout)}] = find(x.values, varargin{:});
        end

        function tf = isassigned(x, varargin)
            %ISASSIGNED  True if the keys (one per axis) select stored values.
            if numel(varargin) ~= numel(x.axes)
                tf = false;
                return
            end
            try
                resolveAll(x, varargin, false);
                tf = true;
            catch
                tf = false;
            end
        end

        % ---------- comparison ----------

        function tf = isequal(a, b)
            tf = isa(a, 'tse.NDTSeries') && isa(b, 'tse.NDTSeries') ...
                && isequal(a.axes, b.axes) ...
                && strcmp(class(a.values), class(b.values)) ...
                && isequal(a.values, b.values);
        end

        function tf = isequaln(a, b)
            tf = isa(a, 'tse.NDTSeries') && isa(b, 'tse.NDTSeries') ...
                && isequal(a.axes, b.axes) ...
                && strcmp(class(a.values), class(b.values)) ...
                && isequaln(a.values, b.values);
        end

        function tf = compare(a, b, varargin)
            tf = tse.compare(a, b, varargin{:});
        end

        % ---------- display ----------

        function disp(x)
            showImpl(x, 5, 40);
        end

        function showall(x)
            showImpl(x, Inf, Inf);
        end

        function dispall(x)
            showImpl(x, Inf, Inf);
        end

        function summary(x)
            printHeader(x);
        end
    end
end

% ======================================================================
% local functions
% ======================================================================

function tf = isTypeName(s)
    tf = any(strcmp(char(s), {'double', 'single', 'logical', 'int8', 'int16', ...
        'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64'}));
end

function ax = makeAxes(spec)
    if isa(spec, 'tse.Axis')
        ax = reshape(spec, 1, []);
    elseif isa(spec, 'tse.MITRange')
        ax = tse.Axis(spec);
    elseif iscell(spec)
        ax = tse.Axis.empty(1, 0);
        for k = 1:numel(spec)
            if isa(spec{k}, 'tse.Axis')
                ax(k) = spec{k};
            else
                ax(k) = tse.Axis(spec{k});
            end
        end
    else
        error('tseries:noMatch', ['NDTSeries axes must be a tse.Axis array, a ' ...
            'tse.MITRange, or a cell array with one entry per dimension.']);
    end
    if isempty(ax)
        error('tseries:noMatch', 'An NDTSeries needs at least one axis.');
    end
end

function sz = axesSize(ax)
    sz = [ax.length];
    if numel(sz) == 1
        sz = [sz 1];
    elseif isempty(sz)
        sz = [0 1];
    end
end

function checkSize(ax, v)
    lens = [ax.length];
    if numel(lens) == 1
        if ~(isvector(v) || isempty(v)) || numel(v) ~= lens
            error('tseries:noMatch', ...
                'Axis length %d does not match %d values.', lens, numel(v));
        end
        return
    end
    sz = size(v);
    sz(end+1:numel(lens)) = 1;
    if numel(sz) > numel(lens) || ~isequal(sz, lens)
        error('tseries:noMatch', 'Axis lengths [%s] do not match values of size [%s].', ...
            num2str(lens), num2str(size(v)));
    end
end

function [ax, v] = fromObject(obj)
    if isa(obj, 'tse.TSeries')
        ax = tse.Axis(obj.firstdate, size(obj.values, 1));
        v = obj.values(:);
    elseif isa(obj, 'tse.MVTSeries')
        ax = [tse.Axis(obj.firstdate, size(obj.values, 1)), tse.Axis(obj.colnames)];
        v = obj.values;
    else   % tse.daec.Array
        ax = obj.axes;
        v = obj.values;
        if ~(isnumeric(v) || islogical(v))
            error('tseries:noMatch', ...
                'NDTSeries values must be numeric or logical, not %s.', class(v));
        end
        v = reshape(v, axesSize(ax));
    end
end

function [dimsOpt, rest] = splitDims(args)
    dimsOpt = {};
    rest = {};
    k = 1;
    while k <= numel(args)
        if (ischar(args{k}) || isstring(args{k})) && strcmpi(args{k}, 'dims') && k < numel(args)
            dimsOpt = args(k:k+1);
            k = k + 2;
        else
            rest{end+1} = args{k}; %#ok<AGROW>
            k = k + 1;
        end
    end
end

function k = pickTimeDim(x, args)
    if ~isempty(args)
        if numel(args) ~= 2 || ~(ischar(args{1}) || isstring(args{1})) ...
                || ~strcmpi(args{1}, 'dims')
            error('tseries:noMatch', 'Expected ''dims'', k.');
        end
        k = args{2};
        if ~isnumeric(k) || ~isscalar(k) || k < 1 || k > numel(x.axes) || k ~= fix(k)
            error('tseries:noMatch', 'dims must be an axis number from 1 to %d.', numel(x.axes));
        end
        if x.axes(k).kind ~= "range"
            error('tseries:noMatch', 'Axis %d is a %s axis, not a date axis.', k, x.axes(k).kind);
        end
        return
    end
    k = find([x.axes.kind] == "range");
    if isempty(k)
        error('tseries:noMatch', 'This NDTSeries has no date axis.');
    elseif numel(k) > 1
        error('tseries:noMatch', ...
            'This NDTSeries has %d date axes (%s); pass ''dims'', k to pick one.', ...
            numel(k), num2str(k));
    end
end

% ---------- indexing helpers ----------

function tf = keepTypeOption()
    tf = logical(tse.getoption('slicing_keeps_type'));
end

function k = namesAxisOf(x, name)
    % the names axis holding name; empty if none; error if ambiguous
    k = [];
    if ~(ischar(name) || isstring(name))
        return
    end
    for j = find([x.axes.kind] == "names")
        if any(x.axes(j).names == string(name))
            k(end+1) = j; %#ok<AGROW>
        end
    end
    if numel(k) > 1
        error('tseries:bounds', ...
            'Name %s is on more than one axis (%s); index with x(...) instead.', ...
            char(name), num2str(k));
    end
end

function tf = isColon(key)
    tf = ischar(key) && strcmp(key, ':');
end

function r = resolveKey(ax, key, k, forAssign)
    % r.idx   positions along the axis (row vector)
    % r.drop  true for a single key (the axis is dropped when reading)
    % r.lo, r.hi  for a range axis: the positions asked for, which can lie
    %             outside 1..length when assigning (the axis then grows)
    r = struct('idx', [], 'drop', false, 'lo', 1, 'hi', ax.length);
    n = ax.length;
    if isColon(key)
        r.idx = 1:n;
        return
    end
    switch ax.kind
        case "range"
            first = ax.range.startMIT;
            if isa(key, 'tse.MIT')
                checkFreq(key, first);
                pos = double([key.value]) - double(first.value) + 1;
                if isscalar(key)
                    r.drop = true;
                elseif any(diff(pos) ~= 1)
                    error('tseries:bounds', ...
                        'Dates on axis %d must be consecutive and increasing.', k);
                end
            elseif isa(key, 'tse.MITRange')
                checkFreq(key.startMIT, first);
                if key.stepSize ~= 1 && length(key) > 1
                    error('tseries:bounds', ...
                        'Index axis %d with a step-1 range; strided and reversed ranges are not supported.', k);
                end
                pos = double(key.startMIT.value) - double(first.value) + (1:length(key));
            else
                error('tseries:bounds', ...
                    'Axis %d is a date axis: index it with an MIT, an MITRange or :.', k);
            end
            if ~isempty(pos)
                r.lo = pos(1);
                r.hi = pos(end);
            end
            if ~forAssign && ~isempty(pos) && (pos(1) < 1 || pos(end) > n)
                error('tseries:bounds', 'Dates on axis %d are outside %s.', k, describe(ax));
            end
            r.idx = pos;
        case "names"
            if ischar(key) || (isstring(key) && isscalar(key))
                j = find(ax.names == string(key), 1);
                if isempty(j)
                    error('tseries:bounds', 'Unknown name %s on axis %d.', char(string(key)), k);
                end
                r.idx = j;
                r.drop = true;
            elseif isstring(key) || iscellstr(key)
                key = string(key);
                r.idx = zeros(1, numel(key));
                for j = 1:numel(key)
                    jj = find(ax.names == key(j), 1);
                    if isempty(jj)
                        error('tseries:bounds', 'Unknown name %s on axis %d.', char(key(j)), k);
                    end
                    r.idx(j) = jj;
                end
            else
                r = positional(r, key, n, k);
            end
        otherwise
            if ischar(key) || isstring(key) || iscell(key) || isa(key, 'tse.MIT') ...
                    || isa(key, 'tse.MITRange')
                error('tseries:bounds', 'Axis %d is a plain axis: index it with numbers.', k);
            end
            r = positional(r, key, n, k);
    end
end

function r = positional(r, key, n, k)
    if islogical(key)
        if numel(key) ~= n
            error('tseries:bounds', 'Logical index for axis %d needs %d elements.', k, n);
        end
        r.idx = find(key(:)');
    elseif isnumeric(key) && all(key(:) == fix(key(:)))
        if any(key(:) < 1 | key(:) > n)
            error('tseries:bounds', 'Index on axis %d is outside 1:%d.', k, n);
        end
        r.idx = double(key(:)');
        r.drop = isscalar(key);
    else
        error('tseries:bounds', 'Unsupported index of class %s on axis %d.', class(key), k);
    end
end

function checkFreq(m, first)
    if ~eq(m.frequency, first.frequency)
        mixed_freq_error(m.frequency, first.frequency);
    end
end

function R = resolveAll(x, keys, forAssign)
    n = numel(x.axes);
    if numel(keys) ~= n
        error('tseries:bounds', 'An NDTSeries with %d axes needs %d indices, got %d.', ...
            n, n, numel(keys));
    end
    R = cell(1, n);
    for k = 1:n
        R{k} = resolveKey(x.axes(k), keys{k}, k, forAssign);
    end
end

function ax = subAxis(ax, idx)
    % the axis restricted to positions idx (already validated)
    switch ax.kind
        case "range"
            if isempty(idx)
                ax = tse.Axis(ax.range.startMIT, 0);
            else
                ax = tse.Axis(ax.range.startMIT + (idx(1) - 1), numel(idx));
            end
        case "names"
            ax = tse.Axis(ax.names(idx));
        otherwise
            ax = tse.Axis(numel(idx));
    end
end

function out = getKeys(x, keys, keepType)
    R = resolveAll(x, keys, false);
    n = numel(R);
    idx = cellfun(@(r) r.idx, R, 'UniformOutput', false);
    drop = cellfun(@(r) r.drop, R);
    v = x.values(idx{:});
    if all(drop)
        out = v;
        return
    end
    keepAx = ~drop | keepType;
    ax = tse.Axis.empty(1, 0);
    for k = find(keepAx)
        if isColon(keys{k})
            ax(end+1) = x.axes(k); %#ok<AGROW>
        else
            ax(end+1) = subAxis(x.axes(k), idx{k}); %#ok<AGROW>
        end
    end
    if n == 1
        v = v(:);
    end
    out = handBack(ax, reshape(v, axesSize(ax)), keepType);
end

function out = handBack(ax, v, keepType)
    kinds = [ax.kind];
    if ~keepType && isequal(kinds, "range") && (isnumeric(v) || islogical(v))
        out = tse.TSeries(ax(1).firstdate(), v(:));
    elseif ~keepType && isequal(kinds, ["range" "names"])
        out = tse.MVTSeries(class(v), ax(1).firstdate(), ax(2).names, v);
    else
        out = tse.NDTSeries(ax, v);
    end
end

function x = resizeAxis(x, k, rng)
    ax = x.axes(k);
    if ~isa(rng, 'tse.MITRange') || (rng.stepSize ~= 1 && length(rng) > 1)
        error('tseries:noMatch', 'resize needs a step-1 MITRange.');
    end
    checkFreq(rng.startMIT, ax.range.startMIT);
    newAx = tse.Axis(rng.startMIT, length(rng));
    off = double(ax.range.startMIT.value) - double(rng.startMIT.value);   % old pos 1 -> new pos 1+off
    T = class(x.values);
    sz = axesSize(x.axes);
    sz(k) = newAx.length;
    if numel(x.axes) == 1
        sz = [newAx.length 1];
    end
    newVals = repmat(cast(tse.typenan(T), T), sz);
    oldPos = 1:ax.length;
    newPos = oldPos + off;
    ok = newPos >= 1 & newPos <= newAx.length;
    src = repmat({':'}, 1, numel(sz));
    dst = src;
    src{k} = oldPos(ok);
    dst{k} = newPos(ok);
    newVals(dst{:}) = x.values(src{:});
    x.axes(k) = newAx;
    x.values = newVals;
end

function x = setKeys(x, keys, val)
    R = resolveAll(x, keys, true);
    % grow date axes for dates outside the stored range
    for k = 1:numel(R)
        if x.axes(k).kind == "range" && ~isColon(keys{k}) && ~isempty(R{k}.idx)
            lo = min(R{k}.lo, 1);
            hi = max(R{k}.hi, x.axes(k).length);
            if lo < 1 || hi > x.axes(k).length
                first = x.axes(k).range.startMIT + (lo - 1);
                x = resizeAxis(x, k, tse.MITRange(first, first + (hi - lo)));
                R{k}.idx = R{k}.idx - (lo - 1);
            end
        end
    end
    idx = cellfun(@(r) r.idx, R, 'UniformOutput', false);
    selSz = cellfun(@numel, idx);
    if isa(val, 'tse.TSeries') || isa(val, 'tse.MVTSeries')
        % align on dates when exactly one date axis is selected by a range
        tk = find([x.axes.kind] == "range" & selSz > 0);
        if isscalar(tk) && selSz(tk) > 1
            rngSel = tse.MITRange(x.axes(tk).range.startMIT + (idx{tk}(1) - 1), ...
                x.axes(tk).range.startMIT + (idx{tk}(end) - 1));
            val = val(rngSel);
        end
        val = val.values;
    elseif isa(val, 'tse.NDTSeries')
        val = val.values;
    end
    if ~(isnumeric(val) || islogical(val))
        error('tseries:noMatch', 'Cannot assign a %s to an NDTSeries.', class(val));
    end
    if isscalar(val)
        x.values(idx{:}) = val;
    elseif numel(val) == prod(selSz)
        if numel(selSz) == 1
            x.values(idx{:}) = val(:);
        else
            x.values(idx{:}) = reshape(val, selSz);
        end
    else
        error('tseries:dimMismatch', ...
            'Assignment of %d values into a selection of %d.', numel(val), prod(selSz));
    end
end

% ---------- display helpers ----------

function printHeader(x)
    if isempty(x.axes)
        fprintf('  empty NDTSeries\n');
        return
    end
    sz = [x.axes.length];
    fprintf('  %s NDTSeries of %s\n', char(strjoin(string(sz), "×")), class(x.values));
    for k = 1:numel(x.axes)
        fprintf('    axis %d: %-6s %s\n', k, x.axes(k).kind, describe(x.axes(k)));
    end
end

function showImpl(x, maxSlices, maxRows)
    printHeader(x);
    if isempty(x.axes)
        return
    end
    if isempty(x.values)
        fprintf('\n');
        return
    end
    n = numel(x.axes);
    if n == 1
        fprintf('\n');
        printGrid(labels(x.axes(1)), "", x.values(:), maxRows);
        fprintf('\n');
        return
    end
    L1 = labels(x.axes(1));
    L2 = labels(x.axes(2));
    if n == 2
        fprintf('\n');
        printGrid(L1, L2, x.values, maxRows);
        fprintf('\n');
        return
    end
    trail = [x.axes(3:end).length];
    nslices = prod(trail);
    shown = min(nslices, maxSlices);
    v = reshape(x.values, x.axes(1).length, x.axes(2).length, nslices);
    for s = 1:shown
        subs = cell(1, numel(trail));
        [subs{:}] = ind2sub([trail 1], s);
        lab = strings(1, numel(trail));
        for j = 1:numel(trail)
            Lj = labels(x.axes(2 + j));
            lab(j) = Lj(subs{j});
        end
        fprintf('\n  (:, :, %s)\n', strjoin(lab, ', '));
        printGrid(L1, L2, v(:, :, s), maxRows);
    end
    if nslices > shown
        fprintf('\n  ... %d more slices (showall(x) prints them all)\n', nslices - shown);
    end
    fprintf('\n');
end

function printGrid(rowLabels, colLabels, M, maxRows)
    nr = size(M, 1);
    nc = size(M, 2);
    if nr > maxRows
        top = ceil(maxRows / 2);
        rows = [1:top, NaN, (nr - (maxRows - top) + 1):nr];
    else
        rows = 1:nr;
    end
    cells = strings(numel(rows), nc);
    for i = 1:numel(rows)
        if isnan(rows(i))
            cells(i, :) = repmat("⋮", 1, nc);
        else
            for j = 1:nc
                cells(i, j) = fmtValue(M(rows(i), j));
            end
        end
    end
    rl = strings(numel(rows), 1);
    for i = 1:numel(rows)
        if isnan(rows(i))
            rl(i) = "⋮";
        else
            rl(i) = rowLabels(rows(i));
        end
    end
    lw = max(strlength(rl));
    if isequal(colLabels, "")
        colLabels = strings(1, nc);
    end
    cw = max([strlength(colLabels); strlength(cells)], [], 1);
    if any(colLabels ~= "")
        line = blanks(2 + lw);
        for j = 1:nc
            line = [line '  ' char(pad(colLabels(j), cw(j), 'left'))]; %#ok<AGROW>
        end
        fprintf('%s\n', line);
    end
    for i = 1:numel(rows)
        line = ['  ' char(pad(rl(i), lw, 'right'))];
        for j = 1:nc
            line = [line '  ' char(pad(cells(i, j), cw(j), 'left'))]; %#ok<AGROW>
        end
        fprintf('%s\n', line);
    end
end

function s = fmtValue(v)
    if islogical(v)
        if v, s = "true"; else, s = "false"; end
    elseif isinteger(v)
        s = string(sprintf('%d', v));
    else
        s = string(sprintf('%.6g', v));
    end
end

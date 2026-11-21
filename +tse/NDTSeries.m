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

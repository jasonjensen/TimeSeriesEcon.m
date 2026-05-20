classdef MVTSeries
    %MVTSERIES  Multivariate time series indexed by MIT (rows) and column
    %name (cols).
    %
    %   An MVTSeries has:
    %     firstdate : MIT of row 1
    %     colnames  : 1xN string array of column names
    %     values    : numeric matrix of size (nrows × N)
    %
    %   Construction:
    %     MVTSeries()                                       % (0,0)
    %     MVTSeries(mit)                                    % (0,0) starting at mit
    %     MVTSeries(mit, names)                             % (0,N)
    %     MVTSeries(range, names)                           % NaN-filled (len×N)
    %     MVTSeries(range, names, undef)                    % alias for default
    %     MVTSeries(range, names, scalar)                   % filled with scalar
    %     MVTSeries(range, names, matrix)                   % len×N matrix
    %     MVTSeries(mit,   names, matrix)                   % len inferred from rows
    %     MVTSeries(mit,   names, vector)                   % single-column reshape
    %     MVTSeries(type,  range, names[, init])            % typed
    %     MVTSeries(range, name=value, name=value, ...)     % via TSeries args
    %     MVTSeries(name=value, name=value, ...)            % range = span(args)
    %
    %   Indexing:
    %     x.name           column TSeries
    %     x(mit, name)     scalar
    %     x(mit, names)    row vector (numeric)
    %     x(rng, name)     TSeries
    %     x(rng, names)    sub MVTSeries
    %     x(mit)           row vector
    %     x(rng)           sub MVTSeries (all columns)
    %     x(name)          TSeries (single column)
    %     x(names)         MVTSeries (selected columns)
    %     x.name(mit) = v  composite: writes value into the right cell
    %                      (grows the MVTSeries if mit is outside the range)

    properties
        firstdate
        colnames
        values
    end

    methods
        % ---------- constructors ----------

        function obj = MVTSeries(varargin)
            if nargin == 0
                obj.firstdate = tseries.MIT(tseries.Unit(), 1);
                obj.colnames  = strings(1, 0);
                obj.values    = zeros(0, 0);
                return
            end

            % MVTSeries(type, range, names, ...) with type as char/string
            if (ischar(varargin{1}) || isstring(varargin{1})) ...
                    && numel(varargin) >= 2 ...
                    && isTypeName(char(varargin{1}))
                T = char(varargin{1});
                obj = tseries.MVTSeries.fromType(T, varargin(2:end));
                return
            end

            first = varargin{1};

            if isa(first, 'tseries.MIT')
                obj = tseries.MVTSeries.fromMIT(first, varargin(2:end), 'double');
                return
            end

            if isa(first, 'tseries.MITRange')
                obj = tseries.MVTSeries.fromRange(first, varargin(2:end), 'double');
                return
            end

            error('tseries:noMatch', 'Unsupported MVTSeries() argument signature.');
        end
    end

    methods (Static, Hidden)
        function obj = fromMIT(fd, args, T)
            obj = tseries.MVTSeries();
            obj.firstdate = fd;
            if isempty(args)
                obj.colnames = strings(1, 0);
                obj.values   = zeros(0, 0, T);
                return
            end
            names = normalizeNames(args{1});
            obj.colnames = names;
            N = numel(names);
            if numel(args) == 1
                obj.values = zeros(0, N, T);
                return
            end
            data = args{2};
            if isnumeric(data) || islogical(data)
                if isvector(data) && numel(data) ~= N
                    data = reshape(data, [], 1);
                    if N > 1
                        error('tseries:noMatch', ...
                            'Vector data needs single column for %d names.', N);
                    end
                end
                if size(data, 2) ~= N
                    error('tseries:noMatch', ...
                        'Number of names (%d) and matrix columns (%d) do not match.', ...
                        N, size(data, 2));
                end
                obj.values = cast(data, T);
            else
                error('tseries:noMatch', 'Unsupported MVTSeries(mit, names, data) signature.');
            end
        end

        function obj = fromRange(rng, args, T)
            obj = tseries.MVTSeries();
            obj.firstdate = rng.startMIT;
            n = length(rng);

            if isempty(args)
                obj.colnames = strings(1, 0);
                obj.values   = zeros(n, 0, T);
                return
            end

            % MVTSeries(range; name=val, name=val) style via name-value pairs.
            % MATLAB doesn't have keyword args like Julia.  If the second
            % position is text-and-value pairs (cell or struct), build from
            % TSeries args.
            if numel(args) >= 1 && isStructLike(args{1})
                obj = tseries.MVTSeries.fromTSeriesPairs(rng, args{1}, T);
                return
            end

            names = normalizeNames(args{1});
            obj.colnames = names;
            N = numel(names);

            if numel(args) == 1
                obj.values = cast(repmat(tseries.typenan(T), n, N), T);
                return
            end

            init = args{2};
            if isempty(init) || (ischar(init) && strcmpi(init, 'undef')) ...
                    || (isstring(init) && strcmpi(init, 'undef'))
                obj.values = cast(repmat(tseries.typenan(T), n, N), T);
            elseif isa(init, 'function_handle')
                obj.values = cast(init(n, N), T);
            elseif isnumeric(init) && isscalar(init)
                obj.values = cast(repmat(init, n, N), T);
            elseif islogical(init) && isscalar(init)
                obj.values = cast(repmat(init, n, N), T);
            elseif isa(init, 'tseries.TSeries')
                % Fill every column from the given TSeries (aligning ranges).
                rngInter = intersect(rng, tseries.rangeof(init));
                if isempty(rngInter)
                    obj.values = cast(repmat(tseries.typenan(T), n, N), T);
                else
                    kInit  = double(rngInter.startMIT.value - init.firstdate.value) + 1;
                    nL     = length(rngInter);
                    kObj   = double(rngInter.startMIT.value - rng.startMIT.value) + 1;
                    col    = cast(init.values(kInit : kInit + nL - 1), T);
                    out    = cast(repmat(tseries.typenan(T), n, N), T);
                    out(kObj : kObj + nL - 1, :) = repmat(col, 1, N);
                    obj.values = out;
                end
            elseif (isnumeric(init) || islogical(init)) && ~isscalar(init)
                if isvector(init) && N == 1
                    init = reshape(init, [], 1);
                end
                if size(init, 1) ~= n || size(init, 2) ~= N
                    error('tseries:dimMismatch', ...
                        'Data size (%dx%d) does not match (%dx%d).', ...
                        size(init,1), size(init,2), n, N);
                end
                obj.values = cast(init, T);
            else
                error('tseries:noMatch', 'Unsupported MVTSeries init.');
            end
        end

        function obj = fromType(T, args)
            if isempty(args)
                error('tseries:noMatch', 'MVTSeries(type, ...) needs more args.');
            end
            first = args{1};
            if isa(first, 'tseries.MIT')
                obj = tseries.MVTSeries.fromMIT(first, args(2:end), T);
            elseif isa(first, 'tseries.MITRange')
                obj = tseries.MVTSeries.fromRange(first, args(2:end), T);
            else
                error('tseries:noMatch', 'Unsupported MVTSeries(type, ...) signature.');
            end
        end

        function obj = fromTSeriesPairs(rng, pairs, T)
            % `pairs` is a struct mapping name -> TSeries/vector/scalar.
            obj = tseries.MVTSeries();
            obj.firstdate = rng.startMIT;
            names = string(fieldnames(pairs)).';
            N = numel(names);
            n = length(rng);
            obj.colnames = names;
            obj.values   = cast(repmat(tseries.typenan(T), n, N), T);
            for k = 1:N
                val = pairs.(names(k));
                if isa(val, 'tseries.TSeries')
                    rngInter = intersect(rng, tseries.rangeof(val));
                    if isempty(rngInter), continue, end
                    kSrc = double(rngInter.startMIT.value - val.firstdate.value) + 1;
                    kDst = double(rngInter.startMIT.value - rng.startMIT.value) + 1;
                    nL   = length(rngInter);
                    obj.values(kDst : kDst + nL - 1, k) = ...
                        cast(val.values(kSrc : kSrc + nL - 1), T);
                elseif (isnumeric(val) || islogical(val)) && isscalar(val)
                    obj.values(:, k) = cast(val, T);
                elseif (isnumeric(val) || islogical(val)) && isvector(val)
                    if numel(val) ~= n
                        error('tseries:dimMismatch', ...
                            'Vector length %d does not match range length %d.', ...
                            numel(val), n);
                    end
                    obj.values(:, k) = cast(val(:), T);
                else
                    error('tseries:noMatch', ...
                        'Unsupported value for column %s.', names(k));
                end
            end
        end
    end

    methods
        % ---------- introspection ----------

        function m = lastdate(x)
            n = size(x.values, 1);
            if n == 0
                m = x.firstdate - 1;
            else
                m = x.firstdate + (int64(n) - 1);
            end
        end

        function F = frequencyof(x)
            F = x.firstdate.frequency;
        end

        function F = frequency(x)
            F = x.firstdate.frequency;
        end

        function rng = rangeof(x, varargin)
            n = size(x.values, 1);
            if n == 0
                rng = tseries.MITRange(x.firstdate, x.firstdate - 1);
            else
                rng = tseries.MITRange(x.firstdate, x.firstdate + (int64(n) - 1));
            end
            if ~isempty(varargin)
                rng = tseries.rangeof(rng, varargin{:});
            end
        end

        function rng = range(x, varargin)
            rng = rangeof(x, varargin{:});
        end

        function names = colnames(x)
            names = x.colnames;
        end

        function v = rawdata(x)
            v = x.values;
        end

        function c = columns(x)
            % Return a struct mapping name -> TSeries (built from views).
            c = struct();
            for k = 1:numel(x.colnames)
                c.(x.colnames(k)) = tseries.TSeries(x.firstdate, x.values(:, k));
            end
        end

        function n = length(x)
            n = size(x.values, 1);
        end

        function n = numel(x)
            n = numel(x.values);
        end

        function s = size(x, varargin)
            s = size(x.values, varargin{:});
        end

        function tf = isempty(x)
            tf = isempty(x.values);
        end

        function n = numArgumentsFromSubscript(~, ~, ~)
            n = 1;
        end

        function ind = end(x, k, n)
            if k == 1
                ind = lastdate(x);
            elseif k == 2
                ind = size(x.values, 2);
            else
                ind = size(x.values, k);
            end
        end

        % ---------- indexing ----------

        function varargout = subsref(x, S)
            if isempty(S)
                varargout = {x}; return
            end
            if strcmp(S(1).type, '.')
                name = S(1).subs;
                if any(strcmp({'firstdate','colnames','values'}, name))
                    out = builtin('subsref', x, S(1));
                elseif any(strcmp(string(name), x.colnames))
                    out = colTSeries(x, string(name));
                else
                    % Could be a method call (e.g. x.rangeof)
                    try
                        out = builtin('subsref', x, S(1));
                    catch
                        error('tseries:bounds', 'Unknown MVTSeries field: %s', name);
                    end
                end
                if numel(S) > 1
                    out = subsref(out, S(2:end));
                end
                varargout = {out};
                return
            end

            if strcmp(S(1).type, '()')
                subs = S(1).subs;
                if isscalar(subs)
                    out = singleIndex(x, subs{1});
                elseif numel(subs) == 2
                    out = pairIndex(x, subs{1}, subs{2});
                else
                    error('tseries:bounds', 'MVTSeries supports 1- or 2-arg indexing.');
                end
                if numel(S) > 1
                    out = subsref(out, S(2:end));
                end
                varargout = {out};
                return
            end

            varargout = {builtin('subsref', x, S)};
        end

        function x = subsasgn(x, S, val)
            if isempty(S)
                x = val; return
            end
            if numel(S) > 1
                % Composite assignment.  Decompose: read the head, modify,
                % write back.  E.g. x.a(mit) = v.
                head = subsref(x, S(1));
                head = subsasgn(head, S(2:end), val);
                x = subsasgn(x, S(1), head);
                return
            end
            if strcmp(S(1).type, '.')
                name = string(S(1).subs);
                if any(strcmp({'firstdate','colnames','values'}, char(name)))
                    x = builtin('subsasgn', x, S, val);
                    return
                end
                k = colIndexOf(x, name);
                if isempty(k)
                    error('tseries:bounds', ...
                        'Cannot append new column via dot-assignment. Use hcat(x, %s=val).', name);
                end
                if isa(val, 'tseries.TSeries')
                    if ~eq(val.firstdate.frequency, x.firstdate.frequency)
                        mixed_freq_error(val.firstdate.frequency, x.firstdate.frequency);
                    end
                    rngObj = rangeof(x);
                    rngVal = tseries.rangeof(val);
                    rngHit = intersect(rngObj, rngVal);
                    rngGrown = tseries.rangeof_span(rngObj, rngVal);
                    if ~isequal(rngGrown, rngObj)
                        x = resizeRange(x, rngGrown);
                    end
                    kObj = double(rngHit.startMIT.value - x.firstdate.value) + 1;
                    kSrc = double(rngHit.startMIT.value - val.firstdate.value) + 1;
                    nL   = length(rngHit);
                    if nL > 0
                        x.values(kObj : kObj + nL - 1, k) = ...
                            cast(val.values(kSrc : kSrc + nL - 1), class(x.values));
                    end
                elseif isnumeric(val) && isscalar(val)
                    x.values(:, k) = val;
                elseif (isnumeric(val) || islogical(val)) && isvector(val)
                    if numel(val) ~= size(x.values, 1)
                        error('tseries:dimMismatch', ...
                            'Vector length %d does not match column length %d.', ...
                            numel(val), size(x.values, 1));
                    end
                    x.values(:, k) = val(:);
                else
                    error('tseries:noMatch', 'Unsupported column assignment.');
                end
                return
            end
            if strcmp(S(1).type, '()')
                subs = S(1).subs;
                if isscalar(subs)
                    x = singleIndexSet(x, subs{1}, val);
                elseif numel(subs) == 2
                    x = pairIndexSet(x, subs{1}, subs{2}, val);
                else
                    error('tseries:bounds', 'MVTSeries supports 1- or 2-arg assignment.');
                end
                return
            end
            error('tseries:bounds', 'Unsupported MVTSeries assignment.');
        end

        function x = resizeRange(x, newRng)
            if ~eq(newRng.startMIT.frequency, x.firstdate.frequency)
                mixed_freq_error(newRng.startMIT.frequency, x.firstdate.frequency);
            end
            T = class(x.values);
            oldRng = rangeof(x);
            n = length(newRng);
            N = size(x.values, 2);
            newVals = cast(repmat(tseries.typenan(T), n, N), T);
            inter = intersect(oldRng, newRng);
            if ~isempty(inter)
                srcStart = double(inter.startMIT.value - oldRng.startMIT.value) + 1;
                dstStart = double(inter.startMIT.value - newRng.startMIT.value) + 1;
                nL = length(inter);
                newVals(dstStart : dstStart + nL - 1, :) = ...
                    x.values(srcStart : srcStart + nL - 1, :);
            end
            x.firstdate = newRng.startMIT;
            x.values = newVals;
        end

        % ---------- hcat / vcat ----------

        function r = horzcat(varargin)
            % Concatenate MVTSeries column-wise (union of columns).
            mvts = {};
            for k = 1:numel(varargin)
                if isa(varargin{k}, 'tseries.MVTSeries')
                    mvts{end+1} = varargin{k}; %#ok<AGROW>
                else
                    error('tseries:noMatch', 'horzcat needs MVTSeries args.');
                end
            end
            if isempty(mvts), r = tseries.MVTSeries(); return, end

            F = mvts{1}.firstdate.frequency;
            for k = 2:numel(mvts)
                if ~eq(mvts{k}.firstdate.frequency, F)
                    mixed_freq_error(F, mvts{k}.firstdate.frequency);
                end
            end
            % Span union of ranges
            rngList = cellfun(@tseries.rangeof, mvts, 'UniformOutput', false);
            rng = tseries.rangeof_span(rngList{:});
            T = class(mvts{1}.values);
            for k = 2:numel(mvts)
                T = promoteClass(T, class(mvts{k}.values));
            end

            % Concatenated column names
            allNames = strings(1, 0);
            for k = 1:numel(mvts)
                allNames = [allNames, mvts{k}.colnames]; %#ok<AGROW>
            end

            n = length(rng);
            N = numel(allNames);
            data = cast(repmat(tseries.typenan(T), n, N), T);
            col = 0;
            for k = 1:numel(mvts)
                m = mvts{k};
                nm = numel(m.colnames);
                dStart = double(m.firstdate.value - rng.startMIT.value) + 1;
                data(dStart : dStart + length(m) - 1, col + 1 : col + nm) = ...
                    cast(m.values, T);
                col = col + nm;
            end
            r = tseries.MVTSeries(rng, allNames, data);
        end

        function r = vertcat(x, varargin)
            % Append rows.  Caller is responsible for date continuity.
            data = x.values;
            for k = 1:numel(varargin)
                v = varargin{k};
                if isa(v, 'tseries.MVTSeries')
                    if ~eq(v.firstdate.frequency, x.firstdate.frequency)
                        mixed_freq_error(x.firstdate.frequency, v.firstdate.frequency);
                    end
                    data = [data; v.values]; %#ok<AGROW>
                elseif isnumeric(v) || islogical(v)
                    if size(v, 2) ~= size(x.values, 2)
                        error('tseries:dimMismatch', ...
                            'vertcat: column count mismatch.');
                    end
                    data = [data; v]; %#ok<AGROW>
                else
                    error('tseries:noMatch', 'vertcat: unsupported argument.');
                end
            end
            r = tseries.MVTSeries(x.firstdate, x.colnames, data);
        end

        % ---------- column renaming ----------

        function x = rename_columns(x, varargin)
            % rename_columns(x, newNames)       - Vector of new names
            % rename_columns(x, struct/map)     - Mapping old -> new
            % rename_columns(x, 'prefix', s)    - Add prefix
            % rename_columns(x, 'suffix', s)    - Add suffix
            % rename_columns(x, 'replace', {old,new})
            if isempty(varargin)
                return
            end
            arg1 = varargin{1};
            if numel(varargin) == 1
                if iscell(arg1) || isstring(arg1) || ischar(arg1)
                    newNames = normalizeNames(arg1);
                    if numel(newNames) ~= numel(x.colnames)
                        error('tseries:noMatch', ...
                            'rename_columns: expected %d names, got %d.', ...
                            numel(x.colnames), numel(newNames));
                    end
                    x.colnames = newNames;
                    return
                elseif isstruct(arg1)
                    out = x.colnames;
                    for k = 1:numel(out)
                        if isfield(arg1, char(out(k)))
                            out(k) = string(arg1.(char(out(k))));
                        end
                    end
                    x.colnames = out;
                    return
                end
            end
            % parse name-value form
            p = inputParser;
            addParameter(p, 'prefix', '');
            addParameter(p, 'suffix', '');
            addParameter(p, 'replace', {});
            parse(p, varargin{:});
            out = x.colnames;
            r = p.Results.replace;
            if ~isempty(r)
                if iscell(r) && numel(r) == 2
                    pairs = {r};
                elseif iscell(r) && all(cellfun(@iscell, r))
                    pairs = r;
                else
                    pairs = {r};
                end
                for j = 1:numel(out)
                    sname = char(out(j));
                    for kk = 1:numel(pairs)
                        sname = strrep(sname, pairs{kk}{1}, pairs{kk}{2});
                    end
                    out(j) = string(sname);
                end
            end
            prefix = char(string(p.Results.prefix));
            suffix = char(string(p.Results.suffix));
            for j = 1:numel(out)
                out(j) = string([prefix char(out(j)) suffix]);
            end
            x.colnames = out;
        end

        % ---------- display ----------

        function disp(x)
            cls = class(x.values);
            et = '';
            if ~strcmp(cls, 'double'), et = sprintf(',%s', cls); end
            Fname = char(x.firstdate.frequency);
            n = size(x.values, 1);
            N = size(x.values, 2);
            fprintf('%dx%d MVTSeries{%s%s} with range %s', n, N, Fname, et, char(rangeof(x)));
            if N == 0
                fprintf(' and no variables\n');
            elseif N <= 5
                fprintf(' and variables (%s)\n', strjoin(cellstr(x.colnames), ', '));
            else
                fprintf(' and variables (%s, ...)\n', strjoin(cellstr(x.colnames(1:3)), ', '));
            end
            if N == 0 || n == 0, return; end

            mits = collect(rangeof(x));
            maxLabel = 0;
            for k = 1:n
                s = char(mits(k));
                if numel(s) > maxLabel, maxLabel = numel(s); end
            end
            header = repmat(' ', 1, maxLabel + 3);
            for k = 1:N
                s = char(x.colnames(k));
                if numel(s) > 10, s = s(1:10); end
                header = [header sprintf('%-12s', s)];  %#ok<AGROW>
            end
            fprintf('%s\n', header);
            limit = 22;
            if n <= limit
                rows = 1:n;
                printRows(x, mits, rows, maxLabel);
            else
                top = floor(limit/2);
                bot = n - (limit - top) + 1;
                printRows(x, mits, 1:top, maxLabel);
                fprintf('%s...\n', repmat(' ', 1, maxLabel + 3));
                printRows(x, mits, bot:n, maxLabel);
            end
        end

        % ---------- arithmetic ----------

        function r = plus(a, b),    r = mvBinaryOp(a, b, @plus);    end
        function r = minus(a, b),   r = mvBinaryOp(a, b, @minus);   end
        function r = times(a, b),   r = mvBinaryOp(a, b, @times);   end
        function r = rdivide(a, b), r = mvBinaryOp(a, b, @rdivide); end
        function r = ldivide(a, b), r = mvBinaryOp(a, b, @ldivide); end
        function r = power(a, b),   r = mvBinaryOp(a, b, @power);   end

        function r = uminus(x), r = x; r.values = -x.values; end
        function r = uplus(x),  r = x; end

        function r = mtimes(a, b)
            if isa(a, 'tseries.MVTSeries') && isnumeric(b) && isscalar(b)
                r = a; r.values = a.values * b; return
            end
            if isa(b, 'tseries.MVTSeries') && isnumeric(a) && isscalar(a)
                r = b; r.values = a * b.values; return
            end
            va = mvValues(a); vb = mvValues(b);
            r = va * vb;
        end

        function r = mrdivide(a, b)
            if isa(a, 'tseries.MVTSeries') && isnumeric(b) && isscalar(b)
                r = a; r.values = a.values / b; return
            end
            r = mvValues(a) / mvValues(b);
        end

        function r = mldivide(a, b)
            if isa(b, 'tseries.MVTSeries') && isnumeric(a) && isscalar(a)
                r = b; r.values = a \ b.values; return
            end
            r = mvValues(a) \ mvValues(b);
        end

        % ---------- comparison (element-wise) ----------

        function r = eq(a, b), r = mvBinaryOp(a, b, @eq); end
        function r = ne(a, b), r = mvBinaryOp(a, b, @ne); end
        function r = lt(a, b), r = mvBinaryOp(a, b, @lt); end
        function r = le(a, b), r = mvBinaryOp(a, b, @le); end
        function r = gt(a, b), r = mvBinaryOp(a, b, @gt); end
        function r = ge(a, b), r = mvBinaryOp(a, b, @ge); end

        function tf = isequal(a, b)
            tf = isa(a,'tseries.MVTSeries') && isa(b,'tseries.MVTSeries') ...
                && eq(a.firstdate, b.firstdate) ...
                && isequal(a.colnames, b.colnames) ...
                && isequal(a.values, b.values);
        end

        function tf = isequaln(a, b)
            tf = isa(a,'tseries.MVTSeries') && isa(b,'tseries.MVTSeries') ...
                && eq(a.firstdate, b.firstdate) ...
                && isequal(a.colnames, b.colnames) ...
                && isequaln(a.values, b.values);
        end

        % ---------- reductions ----------
        % dims=1 -> reduce rows, return 1xN row vector (numeric)
        % dims=2 -> reduce cols, return length-nrows TSeries
        % dims missing or () -> reduce to scalar
        % dims=3 (or higher) -> identity (return matrix)

        function r = sum(x, varargin),     r = mvReduce(x, @sum,     varargin{:}); end
        function r = prod(x, varargin),    r = mvReduce(x, @prod,    varargin{:}); end
        function r = mean(x, varargin),    r = mvReduce(x, @mean,    varargin{:}); end
        function r = median(x, varargin),  r = mvReduce(x, @median,  varargin{:}); end
        function r = std(x, varargin),     r = mvReduce(x, @std,     varargin{:}); end
        function r = var(x, varargin),     r = mvReduce(x, @var,     varargin{:}); end
        function r = min(x, varargin),     r = mvReduce(x, @min,     varargin{:}); end
        function r = max(x, varargin),     r = mvReduce(x, @max,     varargin{:}); end
        function r = any(x, varargin),     r = mvReduce(x, @any,     varargin{:}); end
        function r = all(x, varargin),     r = mvReduce(x, @all,     varargin{:}); end

        % ---------- cumulative / difference ----------

        function r = cumsum(x, varargin)
            if isempty(varargin), varargin = {1}; end
            r = x; r.values = cumsum(x.values, varargin{:});
        end

        function r = cumprod(x, varargin)
            if isempty(varargin), varargin = {1}; end
            r = x; r.values = cumprod(x.values, varargin{:});
        end

        function r = diff_ts(x, k)
            if nargin < 2, k = -1; end
            r = x - lag(x, -k);
        end

        % ---------- shift family ----------

        function r = shift(x, k)
            r = x;
            r.firstdate = x.firstdate - k;
        end

        function r = lag(x, k)
            if nargin < 2, k = 1; end
            r = shift(x, -k);
        end

        function r = lead(x, k)
            if nargin < 2, k = 1; end
            r = shift(x, k);
        end

        % ---------- percent change ----------

        function r = pct(x, shiftValue, varargin)
            if nargin < 2, shiftValue = -1; end
            p = inputParser; addParameter(p, 'islog', false);
            parse(p, varargin{:});
            if p.Results.islog
                a = x; a.values = exp(x.values);
            else
                a = x;
            end
            b = shift(a, shiftValue);
            r = times(minus(a, b), rdivide(1, b)) * 100;
        end

        function r = apct(x, islog)
            if nargin < 2, islog = false; end
            F = x.firstdate.frequency;
            if ~isa(F, 'tseries.YPFrequency')
                error('tseries:noMatch', 'apct for frequency %s not implemented.', class(F));
            end
            N = double(F.PeriodsPerYear);
            if islog, a = x; a.values = exp(x.values); else, a = x; end
            b = shift(a, -1);
            r = (power(rdivide(a, b), N) - 1) * 100;
        end

        function r = ytypct(x)
            F = x.firstdate.frequency;
            if ~isa(F, 'tseries.YPFrequency')
                error('tseries:noMatch', 'ytypct for frequency %s not implemented.', class(F));
            end
            N = double(F.PeriodsPerYear);
            r = (rdivide(x, shift(x, -N)) - 1) * 100;
        end

        % ---------- moving ----------

        function r = moving_sum(x, n),     r = mvMovingImpl(x, n, false); end
        function r = moving_average(x, n), r = mvMovingImpl(x, n, true);  end
        function r = moving(x, n),         r = mvMovingImpl(x, n, true);  end

        % ---------- mapslices ----------

        function r = mapslices(x, f, varargin)
            % mapslices(x, f, 'dims', d)
            p = inputParser; addParameter(p, 'dims', 1);
            parse(p, varargin{:});
            res = builtin_mapslices(x.values, f, p.Results.dims);
            if isequal(size(res), size(x))
                r = tseries.MVTSeries(x.firstdate, x.colnames, res);
            elseif isequal(size(res), [size(x,1), 1])
                r = tseries.TSeries(x.firstdate, res(:));
            else
                r = res;
            end
        end

        % ---------- misc ----------

        function r = copy(x), r = x; end
        function v = double(x), v = double(x.values); end
        function tf = isnumeric(x), tf = isnumeric(x.values); end
        function tf = islogical(x), tf = islogical(x.values); end
        function tf = haskey(x, name), tf = ~isempty(colIndexOf(x, string(name))); end
        function ks = keys(x), ks = cellstr(x.colnames); end
    end
end

% ---------- file-local helpers ----------

function names = normalizeNames(arg)
    if ischar(arg)
        names = string(arg);
    elseif isstring(arg)
        names = arg(:).';
    elseif iscell(arg)
        names = string(arg);
        names = names(:).';
    elseif isa(arg, 'tseries.MIT')
        error('tseries:noMatch', 'Expected column-name argument, got MIT.');
    else
        error('tseries:noMatch', 'Unsupported names argument of class %s.', class(arg));
    end
end

function tf = isTypeName(s)
    tf = ismember(s, {'double','single','logical', ...
        'int8','uint8','int16','uint16','int32','uint32','int64','uint64'});
end

function tf = isStructLike(arg)
    tf = isstruct(arg);
end

function ts = colTSeries(x, name)
    k = colIndexOf(x, name);
    if isempty(k)
        error('tseries:bounds', 'Unknown column: %s', name);
    end
    ts = tseries.TSeries(x.firstdate, x.values(:, k));
end

function k = colIndexOf(x, name)
    k = find(x.colnames == string(name), 1);
end

function ks = colIndicesOf(x, names)
    ks = zeros(1, numel(names));
    for j = 1:numel(names)
        kk = find(x.colnames == string(names(j)), 1);
        if isempty(kk)
            error('tseries:bounds', 'Unknown column: %s', string(names(j)));
        end
        ks(j) = kk;
    end
end

function c = promoteClass(a, b)
    if strcmp(a, b), c = a; return, end
    order = {'logical','uint8','int8','uint16','int16','uint32','int32', ...
             'uint64','int64','single','double'};
    ia = find(strcmp(order, a), 1);
    ib = find(strcmp(order, b), 1);
    if isempty(ia) || isempty(ib)
        c = 'double';
    else
        c = order{max(ia, ib)};
    end
end

function out = singleIndex(x, idx)
    if isa(idx, 'tseries.MIT')
        if ~eq(idx.frequency, x.firstdate.frequency)
            mixed_freq_error(idx.frequency, x.firstdate.frequency);
        end
        k = double(idx.value - x.firstdate.value) + 1;
        if k < 1 || k > size(x.values, 1)
            error('tseries:bounds', 'MIT %s is out of range.', char(idx));
        end
        out = x.values(k, :);
        out = out(:);          % return as column vector to match Julia row-slice
        return
    end
    if isa(idx, 'tseries.MITRange')
        if ~eq(idx.startMIT.frequency, x.firstdate.frequency)
            mixed_freq_error(idx.startMIT.frequency, x.firstdate.frequency);
        end
        kStart = double(idx.startMIT.value - x.firstdate.value) + 1;
        kEnd   = double(idx.stopMIT.value  - x.firstdate.value) + 1;
        if kStart < 1 || kEnd > size(x.values, 1)
            error('tseries:bounds', 'Range %s is outside %s.', char(idx), char(rangeof(x)));
        end
        out = tseries.MVTSeries(idx, x.colnames, x.values(kStart:kEnd, :));
        return
    end
    if (ischar(idx) || (isstring(idx) && isscalar(idx))) && ~isequal(idx, ':')
        out = colTSeries(x, string(idx));
        return
    end
    if (isstring(idx) && ~isscalar(idx)) || iscell(idx)
        names = normalizeNames(idx);
        ks = colIndicesOf(x, names);
        out = tseries.MVTSeries(x.firstdate, names, x.values(:, ks));
        return
    end
    if ischar(idx) && strcmp(idx, ':')
        out = x;
        return
    end
    if islogical(idx)
        out = x.values(idx);
        return
    end
    if isnumeric(idx)
        out = x.values(idx);
        return
    end
    error('tseries:bounds', 'Unsupported MVTSeries index of type %s.', class(idx));
end

function out = pairIndex(x, rowIdx, colIdx)
    rowSel = expandRowIndex(x, rowIdx);
    colSel = expandColIndex(x, colIdx);
    if islogical(colSel)
        ks = find(colSel);
    else
        ks = colSel;
    end
    if isa(rowIdx, 'tseries.MIT') && isscalar(rowIdx)
        out = x.values(rowSel, ks);
        out = out(:);
        return
    end
    if isa(rowIdx, 'tseries.MITRange') ...
            || (ischar(rowIdx) && strcmp(rowIdx, ':')) ...
            || (isnumeric(rowIdx) && ~isscalar(rowIdx)) ...
            || islogical(rowIdx)
        % Range row + single column => TSeries; range row + multi cols => MVTSeries
        if isscalar(ks) && (isa(rowIdx, 'tseries.MITRange') ...
                || (ischar(rowIdx) && strcmp(rowIdx, ':')))
            if isa(rowIdx, 'tseries.MITRange')
                fd = rowIdx.startMIT;
            else
                fd = x.firstdate;
            end
            out = tseries.TSeries(fd, x.values(rowSel, ks));
            return
        end
        if isa(rowIdx, 'tseries.MITRange')
            fd = rowIdx.startMIT;
            out = tseries.MVTSeries(fd, x.colnames(ks), x.values(rowSel, ks));
            return
        end
        if ischar(rowIdx) && strcmp(rowIdx, ':')
            out = tseries.MVTSeries(x.firstdate, x.colnames(ks), x.values(rowSel, ks));
            return
        end
        out = x.values(rowSel, ks);
        return
    end
    out = x.values(rowSel, ks);
end

function sel = expandRowIndex(x, idx)
    if ischar(idx) && strcmp(idx, ':')
        sel = ':';
        return
    end
    if isa(idx, 'tseries.MIT')
        if ~isscalar(idx)
            sel = arrayfun(@(m) double(m.value - x.firstdate.value) + 1, idx);
        else
            sel = double(idx.value - x.firstdate.value) + 1;
        end
        if any(sel < 1) || any(sel > size(x.values, 1))
            error('tseries:bounds', 'MIT row index out of range.');
        end
        return
    end
    if isa(idx, 'tseries.MITRange')
        kStart = double(idx.startMIT.value - x.firstdate.value) + 1;
        kEnd   = double(idx.stopMIT.value  - x.firstdate.value) + 1;
        if kStart < 1 || kEnd > size(x.values, 1)
            error('tseries:bounds', 'Range %s is outside %s.', char(idx), char(rangeof(x)));
        end
        sel = kStart:kEnd;
        return
    end
    if islogical(idx) || isnumeric(idx)
        sel = idx;
        return
    end
    error('tseries:bounds', 'Unsupported row index of type %s.', class(idx));
end

function sel = expandColIndex(x, idx)
    if ischar(idx) && strcmp(idx, ':')
        sel = 1:size(x.values, 2);
        return
    end
    if ischar(idx) || isstring(idx)
        if isscalar(string(idx))
            sel = colIndexOf(x, string(idx));
            if isempty(sel)
                error('tseries:bounds', 'Unknown column: %s', char(string(idx)));
            end
        else
            sel = colIndicesOf(x, string(idx));
        end
        return
    end
    if iscell(idx)
        sel = colIndicesOf(x, string(idx));
        return
    end
    if islogical(idx) || isnumeric(idx)
        sel = idx;
        return
    end
    error('tseries:bounds', 'Unsupported column index of type %s.', class(idx));
end

function x = singleIndexSet(x, idx, val)
    if isa(idx, 'tseries.MIT')
        if ~eq(idx.frequency, x.firstdate.frequency)
            mixed_freq_error(idx.frequency, x.firstdate.frequency);
        end
        k = double(idx.value - x.firstdate.value) + 1;
        if k < 1 || k > size(x.values, 1)
            error('tseries:bounds', 'MIT %s is out of range.', char(idx));
        end
        if isscalar(val)
            x.values(k, :) = val;
        else
            if numel(val) ~= size(x.values, 2)
                error('tseries:dimMismatch', ...
                    'Row length %d does not match column count %d.', ...
                    numel(val), size(x.values, 2));
            end
            x.values(k, :) = val(:).';
        end
        return
    end
    if isa(idx, 'tseries.MITRange')
        if ~eq(idx.startMIT.frequency, x.firstdate.frequency)
            mixed_freq_error(idx.startMIT.frequency, x.firstdate.frequency);
        end
        kStart = double(idx.startMIT.value - x.firstdate.value) + 1;
        kEnd   = double(idx.stopMIT.value  - x.firstdate.value) + 1;
        if kStart < 1 || kEnd > size(x.values, 1)
            error('tseries:bounds', 'Range %s is outside %s.', char(idx), char(rangeof(x)));
        end
        if isa(val, 'tseries.MVTSeries')
            x = pairIndexSet(x, idx, x.colnames, val);
        elseif isnumeric(val) || islogical(val)
            data = val;
            if isvector(data) && numel(data) == (kEnd - kStart + 1) * size(x.values, 2)
                data = reshape(data, kEnd - kStart + 1, size(x.values, 2));
            end
            if size(data, 1) ~= (kEnd - kStart + 1) || size(data, 2) ~= size(x.values, 2)
                error('tseries:dimMismatch', 'Range/data size mismatch.');
            end
            x.values(kStart:kEnd, :) = data;
        else
            error('tseries:noMatch', 'Unsupported value type for range-assignment.');
        end
        return
    end
    if (ischar(idx) || isstring(idx)) && ~isequal(idx, ':')
        k = colIndexOf(x, string(idx));
        if isempty(k)
            error('tseries:bounds', 'Unknown column: %s', char(string(idx)));
        end
        if isa(val, 'tseries.TSeries')
            rngObj = rangeof(x);
            rngVal = tseries.rangeof(val);
            rngHit = intersect(rngObj, rngVal);
            kObj = double(rngHit.startMIT.value - x.firstdate.value) + 1;
            kSrc = double(rngHit.startMIT.value - val.firstdate.value) + 1;
            nL   = length(rngHit);
            if nL > 0
                x.values(kObj : kObj + nL - 1, k) = ...
                    cast(val.values(kSrc : kSrc + nL - 1), class(x.values));
            end
        elseif isnumeric(val) && isscalar(val)
            x.values(:, k) = val;
        elseif isvector(val) && (isnumeric(val) || islogical(val))
            if numel(val) ~= size(x.values, 1)
                error('tseries:dimMismatch', 'Vector length %d vs column length %d.', ...
                    numel(val), size(x.values, 1));
            end
            x.values(:, k) = val(:);
        else
            error('tseries:noMatch', 'Unsupported value type for column-assignment.');
        end
        return
    end
    if iscell(idx) || (isstring(idx) && ~isscalar(idx))
        ks = colIndicesOf(x, normalizeNames(idx));
        if isnumeric(val) || islogical(val)
            x.values(:, ks) = val;
        else
            error('tseries:noMatch', 'Unsupported value for multi-column assignment.');
        end
        return
    end
    if islogical(idx) || isnumeric(idx)
        x.values(idx) = val;
        return
    end
    error('tseries:bounds', 'Unsupported MVTSeries index of type %s.', class(idx));
end

function x = pairIndexSet(x, rowIdx, colIdx, val)
    colSel = expandColIndex(x, colIdx);
    if islogical(colSel), ks = find(colSel); else, ks = colSel; end

    if isa(rowIdx, 'tseries.MIT') && isscalar(rowIdx)
        if ~eq(rowIdx.frequency, x.firstdate.frequency)
            mixed_freq_error(rowIdx.frequency, x.firstdate.frequency);
        end
        k = double(rowIdx.value - x.firstdate.value) + 1;
        if k < 1 || k > size(x.values, 1)
            error('tseries:bounds', 'MIT %s is out of range.', char(rowIdx));
        end
        if isscalar(val) && isscalar(ks)
            x.values(k, ks) = val;
        elseif isscalar(val)
            x.values(k, ks) = val;
        else
            if numel(val) ~= numel(ks)
                error('tseries:dimMismatch', ...
                    'Value length %d does not match column count %d.', numel(val), numel(ks));
            end
            x.values(k, ks) = val(:).';
        end
        return
    end

    rowSel = expandRowIndex(x, rowIdx);

    if isa(val, 'tseries.MVTSeries')
        if ~eq(val.firstdate.frequency, x.firstdate.frequency)
            mixed_freq_error(val.firstdate.frequency, x.firstdate.frequency);
        end
        rngHit = intersect(rangeof(x), rangeof(val));
        if isempty(rngHit), return, end
        kObj = double(rngHit.startMIT.value - x.firstdate.value) + 1;
        kSrc = double(rngHit.startMIT.value - val.firstdate.value) + 1;
        nL   = length(rngHit);
        % Only copy columns that exist in val
        for j = 1:numel(ks)
            colName = x.colnames(ks(j));
            srcK = colIndexOf(val, colName);
            if isempty(srcK), continue, end
            x.values(kObj : kObj + nL - 1, ks(j)) = ...
                cast(val.values(kSrc : kSrc + nL - 1, srcK), class(x.values));
        end
        return
    end

    if isa(val, 'tseries.TSeries')
        if ~eq(val.firstdate.frequency, x.firstdate.frequency)
            mixed_freq_error(val.firstdate.frequency, x.firstdate.frequency);
        end
        if isa(rowIdx, 'tseries.MITRange')
            rngRow = rowIdx;
        else
            rngRow = rangeof(x);
        end
        rngHit = intersect(rngRow, tseries.rangeof(val));
        if isempty(rngHit)
            return
        end
        kObj = double(rngHit.startMIT.value - x.firstdate.value) + 1;
        kSrc = double(rngHit.startMIT.value - val.firstdate.value) + 1;
        nL   = length(rngHit);
        slice = cast(val.values(kSrc : kSrc + nL - 1), class(x.values));
        x.values(kObj : kObj + nL - 1, ks) = repmat(slice, 1, numel(ks));
        return
    end

    if isnumeric(val) || islogical(val)
        x.values(rowSel, ks) = val;
        return
    end

    error('tseries:noMatch', 'Unsupported value type for pair-assignment.');
end

function printRows(x, mits, rows, maxLabel)
    for r = rows
        label = char(mits(r));
        pad = maxLabel - numel(label);
        fprintf('%s%s : ', repmat(' ', 1, pad), label);
        for c = 1:size(x.values, 2)
            fprintf('%-12g', double(x.values(r, c)));
        end
        fprintf('\n');
    end
end

% ---------- binary-op alignment ----------

function r = mvBinaryOp(a, b, op)
% Align two operands (numeric / TSeries / MVTSeries / scalar) and apply
% op element-wise, returning an MVTSeries when at least one operand is.

    if isa(a, 'tseries.MVTSeries') && isa(b, 'tseries.MVTSeries')
        if ~eq(a.firstdate.frequency, b.firstdate.frequency)
            mixed_freq_error(a.firstdate.frequency, b.firstdate.frequency);
        end
        rngA = rangeof(a); rngB = rangeof(b);
        rng = intersect(rngA, rngB);
        common = intersectColnames(a.colnames, b.colnames);
        if isempty(common) || isempty(rng)
            r = tseries.MVTSeries(rng.startMIT, common, ...
                zeros(length(rng), numel(common), class(a.values)));
            return
        end
        kA = double(rng.startMIT.value - a.firstdate.value) + 1;
        nL = length(rng);
        kB = double(rng.startMIT.value - b.firstdate.value) + 1;
        ksA = colIndicesOf(a, common);
        ksB = colIndicesOf(b, common);
        va = a.values(kA : kA + nL - 1, ksA);
        vb = b.values(kB : kB + nL - 1, ksB);
        r = tseries.MVTSeries(rng.startMIT, common, op(va, vb));
        return
    end

    if isa(a, 'tseries.MVTSeries') && isa(b, 'tseries.TSeries')
        if ~eq(a.firstdate.frequency, b.firstdate.frequency)
            mixed_freq_error(a.firstdate.frequency, b.firstdate.frequency);
        end
        rng = intersect(rangeof(a), tseries.rangeof(b));
        if isempty(rng)
            r = tseries.MVTSeries(rng.startMIT, a.colnames, ...
                zeros(0, numel(a.colnames), class(a.values)));
            return
        end
        kA = double(rng.startMIT.value - a.firstdate.value) + 1;
        nL = length(rng);
        kB = double(rng.startMIT.value - b.firstdate.value) + 1;
        va = a.values(kA : kA + nL - 1, :);
        vb = b.values(kB : kB + nL - 1);
        r = tseries.MVTSeries(rng.startMIT, a.colnames, op(va, vb));
        return
    end

    if isa(a, 'tseries.TSeries') && isa(b, 'tseries.MVTSeries')
        r = mvBinaryOp(b, a, @(x,y) op(y, x));
        return
    end

    if isa(a, 'tseries.MVTSeries')
        if isnumeric(b) || islogical(b)
            r = a;
            r.values = op(a.values, b);
            return
        end
    end

    if isa(b, 'tseries.MVTSeries')
        if isnumeric(a) || islogical(a)
            r = b;
            r.values = op(a, b.values);
            return
        end
    end

    error('tseries:noMatch', 'Unsupported binary operands for MVTSeries.');
end

function v = mvValues(x)
    if isa(x, 'tseries.MVTSeries') || isa(x, 'tseries.TSeries')
        v = x.values;
    else
        v = x;
    end
end

function common = intersectColnames(a, b)
% Preserve the order in `a`.
    [~, ia] = ismember(a, b);
    keep = ia > 0;
    common = a(keep);
end

% ---------- reductions ----------

function r = mvReduce(x, op, varargin)
    p = inputParser;
    addParameter(p, 'dims', []);
    pos = {};
    kw  = {};
    for k = 1:numel(varargin)
        if (ischar(varargin{k}) || isstring(varargin{k})) && strcmpi(varargin{k}, 'dims')
            kw = varargin(k:end); break
        else
            pos{end+1} = varargin{k}; %#ok<AGROW>
        end
    end
    parse(p, kw{:});
    dims = p.Results.dims;

    if isempty(dims)
        r = op(x.values, pos{:});
        if isnumeric(r) && ~isscalar(r)
            r = op(r(:), pos{:});
        end
        return
    end

    if dims == 1
        r = op(x.values, pos{:}, 1);
        return
    end
    if dims == 2
        rv = op(x.values, pos{:}, 2);
        r = tseries.TSeries(x.firstdate, rv(:));
        return
    end
    if dims >= 3
        r = x.values;
        return
    end
    error('tseries:noMatch', 'Unsupported dims value: %s', num2str(dims));
end

% ---------- moving ----------

function r = mvMovingImpl(x, n, avg)
    if ~(isnumeric(n) && isscalar(n) && n ~= 0 && n == fix(n))
        error('tseries:noMatch', 'moving window n must be a non-zero integer.');
    end
    n = double(n);
    an = abs(n);
    len = size(x.values, 1) - an;
    if len < 0
        error('tseries:dimMismatch', 'Window %d is larger than the series length.', an);
    end
    if n > 0
        startDate = x.firstdate + (n - 1);
    else
        startDate = x.firstdate;
    end
    out = zeros(len + 1, size(x.values, 2), class(x.values));
    for i = 1:an
        out = out + x.values(i : i + len, :);
    end
    if avg
        out = out / an;
    end
    r = tseries.MVTSeries(startDate, x.colnames, out);
end

% ---------- mapslices (minimal builtin-style impl) ----------

function out = builtin_mapslices(A, f, dims)
% Apply f to each "slice" of A indexed along orthogonal dims.
    if isscalar(dims), dims = [dims]; end
    sz = size(A);
    otherDims = setdiff(1:ndims(A), dims);
    if isempty(otherDims)
        out = f(A);
        return
    end
    iterSz = sz(otherDims);
    n = prod(iterSz);
    sliceIdx = repmat({':'}, 1, ndims(A));
    out = [];
    for k = 1:n
        sub = cell(1, numel(otherDims));
        [sub{:}] = ind2sub(iterSz, k);
        for kk = 1:numel(otherDims)
            sliceIdx{otherDims(kk)} = sub{kk};
        end
        chunk = f(A(sliceIdx{:}));
        if isempty(out)
            chunkSz = size(chunk);
            outSz = sz;
            outSz(dims) = chunkSz(1:numel(dims));
            out = zeros(outSz, class(chunk));
        end
        out(sliceIdx{:}) = chunk;
    end
end

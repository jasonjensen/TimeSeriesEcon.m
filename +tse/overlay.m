function r = overlay(varargin)
%OVERLAY  Combine series so each observation is the first valid argument.
%
%   r = tse.overlay(t1, t2, ...)
%   r = tse.overlay(rng, t1, t2, ...)
%
%   The first form spans the union of input ranges.  The second
%   restricts to the explicit range.  At each observation, the first
%   argument that is not "not-a-number" (per tse.istypenan) wins.
%
%   Also works on bare values: overlay(NaN, 5) -> 5; overlay(1,2) -> 1.
%
%   When all arguments are structs (workspace-like), overlay is applied
%   field-by-field across the union of field names.

    if isempty(varargin)
        error('tseries:noMatch', 'overlay requires at least one argument.');
    end

    % Struct overlay (workspace-like): all args are structs.
    if isstruct(varargin{1})
        r = overlayStructs(varargin{:});
        return
    end

    % Multivariate overlay: every arg is an MVTSeries (with optional MITRange first).
    if isa(varargin{1}, 'tse.MVTSeries') ...
            || (isa(varargin{1}, 'tse.MITRange') ...
                && numel(varargin) >= 2 && isa(varargin{2}, 'tse.MVTSeries'))
        r = overlayMVTSeries(varargin{:});
        return
    end

    % Scalar/array overlay (everything that's not a TSeries)
    if ~isa(varargin{1}, 'tse.MITRange') && ~isa(varargin{1}, 'tse.TSeries')
        head = varargin{1};
        if tse.istypenan(head)
            if numel(varargin) == 1
                r = head;
            else
                r = tse.overlay(varargin{2:end});
            end
        else
            r = head;
        end
        return
    end

    % First arg is the range
    if isa(varargin{1}, 'tse.MITRange')
        rng = varargin{1};
        tseries_args = varargin(2:end);
    else
        % Range spans all TSeries arguments
        rngs = cellfun(@tse.rangeof, varargin, 'UniformOutput', false);
        rng = tse.rangeof_span(rngs{:});
        tseries_args = varargin;
    end

    if isempty(tseries_args)
        error('tseries:noMatch', 'overlay requires at least one TSeries.');
    end

    % Promote element type across all arguments
    cls = class(tseries_args{1}.values);
    for k = 2:numel(tseries_args)
        cls = sumtype(cls, class(tseries_args{k}.values));
    end

    F = tseries_args{1}.frequency;
    n = length(rng);
    out = repmat(tse.typenan(cls), n, 1);
    out = cast(out, cls);
    filled = false(n, 1);
    rngFirst = rng.startMIT.value;
    isFloat = strcmp(cls, 'double') || strcmp(cls, 'single');

    for k = 1:numel(tseries_args)
        ts = tseries_args{k};
        if ts.frequency ~= F
            mixed_freq_error(F, ts.frequency);
        end
        v = ts.values;
        nts = numel(v);
        if nts == 0, continue, end
        tsFirst = ts.firstdate.value;

        % Vectorised mask of target positions for this series.
        positions = (1:nts) + double(tsFirst - rngFirst);   % 1..N -> rng-pos
        inRange   = positions >= 1 & positions <= n;
        if isFloat
            valid = inRange & ~isnan(v(:)).';
        elseif strcmp(cls, 'logical')
            valid = inRange;
        else
            sentinel = tse.typenan(cls);
            valid = inRange & (v(:) ~= sentinel).';
        end
        if ~any(valid), continue, end

        pos = positions(valid);
        srcIdx = find(valid);
        % Drop positions already filled by an earlier argument.
        unfilled = ~filled(pos);
        if ~any(unfilled), continue, end
        pos    = pos(unfilled);
        srcIdx = srcIdx(unfilled);

        out(pos) = v(srcIdx);
        filled(pos) = true;
        if all(filled)
            break
        end
    end

    r = tse.TSeries(rng.startMIT, out);
end

function c = sumtype(a, b)
% Pick the "wider" numeric/logical type between two classes.
    if strcmp(a, b)
        c = a; return
    end
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

function r = overlayMVTSeries(varargin)
% Overlay multiple MVTSeries onto a common range and column-union.

    if isa(varargin{1}, 'tse.MITRange')
        rng = varargin{1};
        mvtsArgs = varargin(2:end);
    else
        rngs = cellfun(@tse.rangeof, varargin, 'UniformOutput', false);
        rng = tse.rangeof_span(rngs{:});
        mvtsArgs = varargin;
    end

    if isempty(mvtsArgs)
        r = tse.MVTSeries();
        return
    end

    F = mvtsArgs{1}.frequency;
    for k = 2:numel(mvtsArgs)
        if ~eq(mvtsArgs{k}.frequency, F)
            mixed_freq_error(F, mvtsArgs{k}.frequency);
        end
    end

    % Ordered union of column names
    allNames = mvtsArgs{1}.colnames;
    for k = 2:numel(mvtsArgs)
        for j = 1:numel(mvtsArgs{k}.colnames)
            nm = mvtsArgs{k}.colnames(j);
            if ~any(allNames == nm)
                allNames = [allNames, nm]; %#ok<AGROW>
            end
        end
    end

    % Element type
    cls = class(mvtsArgs{1}.values);
    for k = 2:numel(mvtsArgs)
        cls = sumtype(cls, class(mvtsArgs{k}.values));
    end

    nrows = length(rng);
    out = repmat(tse.typenan(cls), nrows, numel(allNames));
    out = cast(out, cls);
    r = tse.MVTSeries(rng, allNames, out);

    for c = 1:numel(allNames)
        nm = allNames(c);
        % Collect TSeries for this column across all args that have it.
        cols = {};
        for k = 1:numel(mvtsArgs)
            if any(mvtsArgs{k}.colnames == nm)
                cols{end+1} = mvtsArgs{k}.(char(nm)); %#ok<AGROW>
            end
        end
        ts = tse.overlay(rng, cols{:});
        r.(char(nm)) = ts;
    end
end

function r = overlayStructs(varargin)
% Overlay multiple structs field-by-field (like Julia Workspace overlay).
% For fields that appear in multiple structs, overlay is applied recursively.
    allFields = fieldnames(varargin{1});
    for k = 2:numel(varargin)
        if ~isstruct(varargin{k})
            error('tseries:noMatch', 'overlay: all arguments must be structs when the first is a struct.');
        end
        fk = fieldnames(varargin{k});
        for j = 1:numel(fk)
            if ~any(strcmp(allFields, fk{j}))
                allFields{end+1} = fk{j}; %#ok<AGROW>
            end
        end
    end

    r = struct();
    for fi = 1:numel(allFields)
        fname = allFields{fi};
        vals = {};
        for k = 1:numel(varargin)
            if isfield(varargin{k}, fname)
                vals{end+1} = varargin{k}.(fname); %#ok<AGROW>
            end
        end
        if numel(vals) == 1
            r.(fname) = vals{1};
        else
            r.(fname) = tse.overlay(vals{:});
        end
    end
end

function tf = compare_ts(a, b, varargin)
%COMPARE_TS  Compare two TSeries (or scalar / array values) under
%isapprox-style tolerance.  Returns a scalar logical.
%
%   compare_ts(a, b, 'atol', val, 'rtol', val, 'nans', true|false,
%              'ignoreMissing', true|false, 'trange', MITRange,
%              'quiet', true|false)
%
%   ignoreMissing=true causes ranges that exist in one operand but not
%   the other to be ignored (intersection is compared).

    p = inputParser;
    addParameter(p, 'atol', 0);
    addParameter(p, 'rtol', []);
    addParameter(p, 'nans', false);
    addParameter(p, 'ignoreMissing', false);
    addParameter(p, 'trange', []);
    addParameter(p, 'quiet', true);
    parse(p, varargin{:});

    atol = p.Results.atol;
    rtol = p.Results.rtol;
    if isempty(rtol)
        if atol > 0
            rtol = 0;
        else
            rtol = sqrt(eps);
        end
    end
    nansEqual    = p.Results.nans;
    ignoreMissing = p.Results.ignoreMissing;
    trange       = p.Results.trange;

    % Struct (workspace) comparison: field-by-field.
    if isstruct(a) && isstruct(b)
        tf = compareStructs(a, b, atol, rtol, nansEqual, ignoreMissing, trange, p.Results.quiet);
        return
    end

    if isa(a, 'tse.TSeries') && isa(b, 'tse.TSeries')
        if ~eq(a.frequency, b.frequency)
            tf = false; return
        end
        rngA = tse.rangeof(a);
        rngB = tse.rangeof(b);
        if ~isempty(trange) && isa(trange, 'tse.MITRange') ...
                && eq(trange.frequency, a.frequency)
            rngA = intersect(trange, rngA);
            rngB = intersect(trange, rngB);
        end
        if ignoreMissing
            trng = intersect(rngA, rngB);
        else
            if isequal(rngA, rngB)
                trng = rngA;
            else
                tf = false; return
            end
        end
        if isempty(trng)
            tf = true; return
        end
        va = a(trng).values;
        vb = b(trng).values;
        tf = approxScalarOrArray(va, vb, atol, rtol, nansEqual);
        return
    end

    if isa(a, 'tse.MVTSeries') && isa(b, 'tse.MVTSeries')
        if ~eq(a.frequency, b.frequency)
            tf = false; return
        end
        % column-name handling
        if ignoreMissing
            cols = intersect_strings(a.colnames, b.colnames);
        else
            if ~isequal(a.colnames, b.colnames)
                tf = false; return
            end
            cols = a.colnames;
        end
        rngA = tse.rangeof(a);
        rngB = tse.rangeof(b);
        if ~isempty(trange) && isa(trange, 'tse.MITRange') ...
                && eq(trange.frequency, a.frequency)
            rngA = intersect(trange, rngA);
            rngB = intersect(trange, rngB);
        end
        if ignoreMissing
            trng = intersect(rngA, rngB);
        else
            if isequal(rngA, rngB)
                trng = rngA;
            else
                tf = false; return
            end
        end
        if isempty(trng) || isempty(cols)
            tf = true; return
        end
        va = a(trng, cols).values;
        vb = b(trng, cols).values;
        tf = approxScalarOrArray(va, vb, atol, rtol, nansEqual);
        return
    end

    if isnumeric(a) && isnumeric(b)
        tf = approxScalarOrArray(a, b, atol, rtol, nansEqual);
        return
    end

    tf = isequal(a, b);
end

function out = intersect_strings(a, b)
% Preserve order in `a`.
    [~, ia] = ismember(a, b);
    out = a(ia > 0);
end

function tf = approxScalarOrArray(x, y, atol, rtol, nansEqual)
    if numel(x) ~= numel(y)
        tf = false; return
    end
    if nansEqual
        nanX = isnan(x);
        nanY = isnan(y);
        if any(nanX ~= nanY)
            tf = false; return
        end
        x(nanX) = 0;
        y(nanX) = 0;
    end
    if any(isnan(x(:))) || any(isnan(y(:)))
        tf = false; return
    end
    diffArr = abs(x(:) - y(:));
    refArr  = max(abs(x(:)), abs(y(:)));
    tf = all(diffArr <= atol + rtol * refArr);
end

function tf = compareStructs(a, b, atol, rtol, nansEqual, ignoreMissing, trange, quiet)
% Compare two structs field-by-field (workspace comparison).
    fieldsA = fieldnames(a);
    fieldsB = fieldnames(b);

    if ignoreMissing
        fields = intersect(fieldsA, fieldsB);
    else
        if ~isequal(sort(fieldsA), sort(fieldsB))
            tf = false;
            if ~quiet
                fprintf('compare_ts: struct fields differ.\n');
            end
            return
        end
        fields = fieldsA;
    end

    tf = true;
    for k = 1:numel(fields)
        fname = fields{k};
        result = tse.compare_ts(a.(fname), b.(fname), ...
            'atol', atol, 'rtol', rtol, 'nans', nansEqual, ...
            'ignoreMissing', ignoreMissing, 'trange', trange, 'quiet', quiet);
        if ~result
            tf = false;
            if ~quiet
                fprintf('compare_ts: field "%s" differs.\n', fname);
            end
            return
        end
    end
end

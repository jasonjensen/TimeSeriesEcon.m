function s = x13write(spec, varargin)
%X13WRITE  Serialise an X13 spec object into the .spc text X13-ARIMA-SEATS reads.
%
%   s = tse.x13.x13write(spec, 'test', true)   returns the spec string
%   tse.x13.x13write(spec, 'outfolder', dir)   writes dir/spec.spc
%
%   In test mode the print/save/savelog fields are omitted (matching the Julia
%   x13write), so this is the form used by the spec round-trip tests.  Lines are
%   wrapped to the X13 length limit via tse.x13.impose_line_length.
%
%   See also: tse.x13.impose_line_length, tse.x13.run.
    p = struct('test', false, 'outfolder', tse.x13.X13default());
    p = tse.x13.getopts(p, varargin);
    test = logical(p.test);
    outfolder = p.outfolder;

    if ~isa(spec, 'tse.x13.X13spec')
        error('tseries:noMatch', 'x13write expects an X13spec.');
    end

    if ~test && tse.x13.isdefault(outfolder)
        outfolder = tse.x13.x13tempdir();   % no bundled mktempdir; caller may override
        spec.folder = outfolder;
    end

    tse.x13.validateX13spec(spec);

    parts = {};
    parts{end+1} = local_series(spec.series, test); %#ok<*AGROW>
    order = {'arima','estimate','transform','regression','automdl','x11', ...
        'x11regression','check','forecast','force','pickmdl','history', ...
        'metadata','identify','outlier','seats','slidingspans','spectrum'};
    for k = 1:numel(order)
        v = spec.(order{k});
        if ~tse.x13.isdefault(v)
            parts{end+1} = local_subspec(v, test, outfolder);
        end
    end
    spec.string = strjoin(parts, newline);

    if test
        s = spec.string;
        return
    end

    fid = fopen(fullfile(char(outfolder), 'spec.spc'), 'w');
    if fid < 0
        error('tseries:noMatch', 'Could not open spec.spc for writing in %s.', char(outfolder));
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s\n', spec.string);
    s = spec.string;
end

% ------------------------------------------------------------------ series ----
function out = local_series(obj, test)
    s = {};
    props = properties(obj);
    for i = 1:numel(props)
        key = props{i};
        if test && any(strcmp(key, {'print','save','savelog'}))
            continue
        end
        v = obj.(key);
        if tse.x13.isdefault(v)
            continue
        end
        if strcmp(key, 'print')
            s{end+1} = ['print = ' local_plus(v)];
            continue
        end
        s{end+1} = [key ' = ' local_fieldval('X13series', key, v)];
    end
    s = tse.x13.impose_line_length(s);
    out = ['series {' newline '        ' strjoin(s, [newline '        ']) newline '}'];
end

% --------------------------------------------------------------- metadata ----
function out = local_metadata(obj)
    e = obj.entries;
    s = {};
    if size(e, 1) == 1
        s{end+1} = ['key = "' e{1,1} '"'];
        s{end+1} = ['value = "' e{1,2} '"'];
    else
        s{end+1} = 'key = (';
        for i = 1:size(e, 1)
            s{end+1} = ['        "' e{i,1} '"'];
        end
        s{end+1} = ')';
        s{end+1} = 'value = (';
        for i = 1:size(e, 1)
            s{end+1} = ['        "' e{i,2} '"'];
        end
        s{end+1} = ')';
    end
    s = tse.x13.impose_line_length(s);
    out = ['metadata {' newline '        ' strjoin(s, [newline '        ']) newline '}'];
end

% ------------------------------------------------------ generic subspec ----
function out = local_subspec(obj, test, outfolder)
    cls = regexprep(class(obj), '.*\.', '');
    if strcmp(cls, 'X13series')
        out = local_series(obj, test);
        return
    end
    if strcmp(cls, 'X13metadata')
        out = local_metadata(obj);
        return
    end
    specname = local_specname(cls);

    s = {};
    keysAtEnd = {};
    props = properties(obj);
    for i = 1:numel(props)
        key = props{i};
        if test && any(strcmp(key, {'print','save','savelog'}))
            continue
        end
        if any(strcmp(key, {'fixar','fixma','fixb'}))
            continue
        end
        v = obj.(key);
        if tse.x13.isdefault(v)
            continue
        end
        if strcmp(key, 'func')
            s{end+1} = ['function = ' local_fieldval(cls, key, v)];
            continue
        elseif any(strcmp(key, {'printphtrf','tabtables'}))
            s{end+1} = [key ' = ' local_alt(v)];
            continue
        elseif strcmp(key, 'print')
            s{end+1} = ['print = ' local_plus(v)];
            continue
        elseif strcmp(cls, 'X13pickmdl') && strcmp(key, 'models')
            if ~tse.x13.isdefault(outfolder) && ~isempty(char(outfolder))
                mdl = [local_arimamodels(v) newline];
                fp = fullfile(char(outfolder), 'pickmdl.mdl');
                fid = fopen(fp, 'w');
                if fid >= 0
                    fprintf(fid, '%s', mdl);
                    fclose(fid);
                end
                s{end+1} = ['file = "' fp '"'];
            else
                s{end+1} = ['models = ' local_arimamodels(v)];
            end
            continue
        elseif any(strcmp(key, {'ma','ar','b','aictest'}))
            keysAtEnd{end+1} = key;
            continue
        end
        s{end+1} = [key ' = ' local_fieldval(cls, key, v)];
    end
    for j = 1:numel(keysAtEnd)
        key = keysAtEnd{j};
        v = obj.(key);
        if any(strcmp(key, {'ma','ar','b'}))
            s{end+1} = [key ' = ' local_fixedvals(obj, key, v)];
        else
            s{end+1} = [key ' = ' local_fieldval(cls, key, v)];
        end
    end

    s = tse.x13.impose_line_length(s);
    if ~isempty(s)
        out = [specname ' {' newline '        ' strjoin(s, [newline '        ']) newline '}'];
    else
        out = [specname ' { }'];
    end
end

% --------------------------------------------------------- value helpers ----
function out = local_fieldval(cls, key, v)
    if any(strcmp(key, local_stringfields(cls)))
        out = local_stringval(v);
        return
    end
    out = local_val(v, any(strcmp(key, local_floatfields(cls))));
end

function out = local_val(v, isFloat)
    if isa(v, 'tse.x13.Span') || isa(v, 'tse.x13.X13var') ...
            || isa(v, 'tse.x13.ArimaModel')
        out = v.x13str();
    elseif isa(v, 'tse.x13.ArimaSpec')
        if isscalar(v), out = v.x13str(); else, out = local_arimaspecs(v); end
    elseif isa(v, 'tse.x13.FPConst')
        out = v.bare();
    elseif isa(v, 'tse.MIT')
        out = tse.x13.mitstr(v);
    elseif isa(v, 'tse.MITRange')
        out = ['(' tse.x13.mitstr(first(v)) ', ' tse.x13.mitstr(last(v)) ')'];
    elseif isa(v, 'tse.TSeries')
        out = local_tsvals(v);
    elseif isa(v, 'tse.MVTSeries')
        out = local_mvtvals(v);
    elseif islogical(v)
        out = local_bool(v);
    elseif isnumeric(v)
        if isscalar(v)
            out = local_num(v, isFloat);
        else
            parts = arrayfun(@(x) local_num(x, isFloat), v(:).', 'UniformOutput', false);
            out = ['(' strjoin(parts, ', ') ')'];
        end
    elseif iscell(v)
        parts = cellfun(@local_tok, v, 'UniformOutput', false);
        out = ['(' strjoin(parts, ' ') ')'];
    elseif isstring(v) && ~isscalar(v)
        parts = arrayfun(@(e) ['"' char(e) '"'], v, 'UniformOutput', false);
        out = ['(' strjoin(parts, [newline '        ']) ')'];
    elseif ischar(v) || isstring(v)
        out = char(v);
    else
        error('tseries:noMatch', 'x13write cannot format a value of class %s.', class(v));
    end
end

function out = local_tok(e)
    if ischar(e) || isstring(e)
        out = char(e);
    elseif isa(e, 'tse.x13.X13var')
        out = e.x13str();
    else
        out = local_val(e, false);
    end
end

function out = local_num(x, isFloat)
    if isnan(x)
        out = '';
    elseif isFloat
        out = tse.x13.juliafloat(x);
    else
        out = sprintf('%d', round(double(x)));
    end
end

function out = local_bool(v)
    if v, out = 'yes'; else, out = 'no'; end
end

function out = local_stringval(v)
    if (ischar(v) || (isstring(v) && isscalar(v)))
        out = ['"' char(v) '"'];
    elseif iscell(v)
        parts = cellfun(@(e) ['"' char(e) '"'], v, 'UniformOutput', false);
        out = ['(' strjoin(parts, [newline '        ']) ')'];
    elseif isstring(v)
        parts = arrayfun(@(e) ['"' char(e) '"'], v, 'UniformOutput', false);
        out = ['(' strjoin(parts, [newline '        ']) ')'];
    else
        out = ['"' char(v) '"'];
    end
end

function out = local_tsvals(ts)
    v = double(ts.values(:).');
    if all(v == floor(v) & isfinite(v))
        parts = arrayfun(@(x) sprintf('%d', x), v, 'UniformOutput', false);
    else
        parts = arrayfun(@(x) tse.x13.juliafloat(x), v, 'UniformOutput', false);
    end
    out = ['(' strjoin(parts, ' ') ')'];
end

function out = local_mvtvals(mv)
    names = cellstr(mv.colnames);
    if numel(names) == 1
        out = local_tsvals(mv.(names{1}));
        return
    end
    M = mv.values;
    rows = cell(1, size(M, 1));
    for r = 1:size(M, 1)
        vr = M(r, :);
        if all(vr == floor(vr) & isfinite(vr))
            cells = arrayfun(@(x) sprintf('%d', x), vr, 'UniformOutput', false);
        else
            cells = arrayfun(@(x) tse.x13.juliafloat(x), vr, 'UniformOutput', false);
        end
        rows{r} = strjoin(cells, '        ');
    end
    out = ['(        ' strjoin(rows, [newline '        ']) '        )'];
end

function out = local_plus(v)
    if iscell(v)
        out = ['(' strjoin(cellfun(@char, v, 'UniformOutput', false), ' + ') ')'];
    elseif ischar(v) || isstring(v)
        out = char(v);
    else
        out = local_val(v, false);
    end
end

function out = local_alt(v)
    if islogical(v)
        if v, out = '1'; else, out = '0'; end
    elseif iscell(v)
        out = ['"' strjoin(cellfun(@char, v, 'UniformOutput', false), ',') '"'];
    else
        out = char(v);
    end
end

function out = local_arimaspecs(specs)
    parts = arrayfun(@(sp) sp.x13str(), specs, 'UniformOutput', false);
    out = strjoin(parts, '');
end

function out = local_arimamodels(models)
    n = numel(models);
    parts = cell(1, n);
    for i = 1:n-1
        if isequal(models(i).default, true), suff = ' *'; else, suff = ' X'; end
        parts{i} = [models(i).x13str() suff];
    end
    parts{n} = models(n).x13str();
    out = strjoin(parts, newline);
end

function out = local_fixedvals(obj, key, v)
    fixed = obj.(['fix' key]);
    if tse.x13.isdefault(fixed)
        out = local_val(v, true);
    else
        parts = cell(1, numel(v));
        for i = 1:numel(v)
            if iscell(v), vi = v{i}; else, vi = v(i); end
            if isnan(vi), token = ''; else, token = tse.x13.juliafloat(vi); end
            if i <= numel(fixed) && logical(fixed(i)), token = [token 'f']; end
            parts{i} = token;
        end
        out = ['(' strjoin(parts, ',') ')'];
    end
end

% ------------------------------------------------------------ metadata maps ----
function name = local_specname(cls)
    map = struct( ...
        'X13arima','arima', 'X13automdl','automdl', 'X13check','check', ...
        'X13estimate','estimate', 'X13force','force', 'X13forecast','forecast', ...
        'X13history','history', 'X13identify','identify', 'X13outlier','outlier', ...
        'X13pickmdl','pickmdl', 'X13regression','regression', 'X13seats','seats', ...
        'X13slidingspans','slidingspans', 'X13spectrum','spectrum', ...
        'X13transform','transform', 'X13x11','x11', 'X13x11regression','x11regression', ...
        'X13series','series', 'X13metadata','metadata');
    name = map.(cls);
end

function f = local_floatfields(cls)
    switch cls
        case 'X13series',        f = {'compwt','missingcode','missingval'};
        case 'X13arima',         f = {'ar','ma'};
        case 'X13automdl',       f = {'ljungboxlimit','armalimit','reducecv','urfinal'};
        case 'X13check',         f = {'acflimit','qlimit'};
        case 'X13estimate',      f = {'tol'};
        case 'X13force',         f = {'lambda','rho'};
        case 'X13forecast',      f = {'probability'};
        case 'X13outlier',       f = {'critical','almost','tcrate'};
        case 'X13pickmdl',       f = {'overdiff'};
        case 'X13regression',    f = {'aicdiff','chi2testcv','pvaictest','tlimit','b','tcrate'};
        case 'X13seats',         f = {'epsiv','rmod','xl'};
        case 'X13slidingspans',  f = {'cutchng','cutseas','cuttd'};
        case 'X13transform',     f = {'aicdiff','power','constant'};
        case 'X13x11',           f = {'sigmalim','trendic'};
        case 'X13x11regression', f = {'aicdiff','critical','sigma','tdprior','almost','b'};
        otherwise,               f = {};
    end
end

function f = local_stringfields(cls)
    switch cls
        case 'X13series',        f = {'file','format','name','title'};
        case 'X13arima',         f = {'title'};
        case 'X13estimate',      f = {'file'};
        case 'X13pickmdl',       f = {'file'};
        case 'X13regression',    f = {'file','format'};
        case 'X13transform',     f = {'file','format','title'};
        case 'X13x11',           f = {'title'};
        case 'X13x11regression', f = {'file','format','umfile','umformat','umname'};
        otherwise,               f = {};
    end
end

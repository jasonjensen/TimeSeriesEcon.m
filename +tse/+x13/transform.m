function out = transform(varargin)
%TRANSFORM  Build (or set on a spec) the transform spec.
%
%   tse.x13.transform('func', 'log')
%   tse.x13.transform('power', 0.5)
%   tse.x13.transform(spec, ...)      sets spec.transform
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('adjust',D,'aicdiff',D,'data',D,'file',D,'format',D,'func',D, ...
        'mode',D,'power',D,'precision',D,'print',D,'save',D,'start',D, ...
        'title',D,'type',D,'constant',D,'trimzero',D);
    d.name = D;
    d.savelog = 'autotransform';
    o = tse.x13.getopts(d, args);

    % start and name are derived from data (mirrors the Julia constructor)
    o.start = D;
    o.name = D;
    if ~tse.x13.isdefault(o.data)
        o.start = first(tse.rangeof(o.data));
        if isa(o.data, 'tse.MVTSeries')
            names = cellstr(o.data.colnames);
            if numel(names) == 1, o.name = names{1}; else, o.name = names; end
        end
    end

    if ~tse.x13.isdefault(o.func) && ~tse.x13.isdefault(o.power)
        error('tseries:noMatch', 'Either power or func can be specified, but not both.');
    end
    if ~tse.x13.isdefault(o.adjust) && strcmp(char(o.adjust), 'lpyear')
        if ~tse.x13.isdefault(o.power) && o.power ~= 0.0
            error('tseries:noMatch', 'adjust=lpyear is only allowed with a log transform (power=0.0).');
        elseif ~tse.x13.isdefault(o.func) && ~strcmp(char(o.func), 'log')
            error('tseries:noMatch', 'adjust=lpyear is only allowed with a log transform (func=log).');
        end
    end
    if iscell(o.mode)
        if numel(o.mode) > 2
            error('tseries:noMatch', 'Only up to two values can be included in mode. Received %d.', numel(o.mode));
        end
        if ismember('diff', o.mode) && (ismember('ratio', o.mode) || ismember('percent', o.mode))
            error('tseries:noMatch', 'The diff mode is not compatible with the ratio or percent modes.');
        end
    end
    if (ischar(o.title) || isstring(o.title)) && strlength(string(o.title)) > 79
        warning('Transform title truncated to 79 characters. Full title: %s', char(o.title));
        tt = char(o.title); o.title = tt(1:79);
    end
    if ~tse.x13.isdefault(o.type)
        if tse.x13.isdefault(o.data)
            error('tseries:noMatch', 'A user-defined prior-adjustment type is specified, but no data has been provided.');
        end
        ncols = 1;
        if isa(o.data, 'tse.MVTSeries'), ncols = numel(cellstr(o.data.colnames)); end
        if isa(o.data, 'tse.TSeries') && iscell(o.type) && numel(o.type) > 1
            error('tseries:noMatch', 'The number of prior-adjustment types must match the number of data series (1).');
        elseif isa(o.data, 'tse.MVTSeries') && iscell(o.type) && numel(o.type) ~= ncols
            error('tseries:noMatch', 'The number of prior-adjustment types must match the number of data series (%d).', ncols);
        elseif isa(o.data, 'tse.MVTSeries') && (ischar(o.type) || isstring(o.type)) && ncols ~= 1
            error('tseries:noMatch', 'The number of prior-adjustment types (1) must match the number of data series (%d).', ncols);
        end
    end

    o.print = tse.x13.expandall(o.print, {'aictransform','seriesconstant','seriesconstantplot', ...
        'prior','permprior','tempprior','prioradjusted','permprioradjusted','prioradjustedptd', ...
        'permprioradjustedptd','transformed'});
    o.save = tse.x13.expandall(o.save, {'seriesconstant','prior','permprior','tempprior', ...
        'prioradjusted','permprioradjusted','prioradjustedptd','permprioradjustedptd','transformed'});

    obj = tse.x13.X13transform();
    obj.adjust = o.adjust; obj.aicdiff = o.aicdiff; obj.data = o.data; obj.file = o.file;
    obj.format = o.format; obj.func = o.func; obj.mode = o.mode; obj.name = o.name;
    obj.power = o.power; obj.precision = o.precision; obj.print = o.print; obj.save = o.save;
    obj.savelog = o.savelog; obj.start = o.start; obj.title = o.title; obj.type = o.type;
    obj.constant = o.constant; obj.trimzero = o.trimzero;

    out = tse.x13.specfinish(spec, 'transform', obj);
end

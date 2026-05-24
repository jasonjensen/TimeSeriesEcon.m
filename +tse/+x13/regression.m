function out = regression(varargin)
%REGRESSION  Build (or set on a spec) the regression spec.
%
%   tse.x13.regression('variables', {'const', 'seasonal'})
%   tse.x13.regression('variables', {tse.x13.ao(2007Q1), 'td'})
%   tse.x13.regression('data', mvts)        user regressors from an MVTSeries
%   tse.x13.regression(spec, ...)           sets spec.regression
%
%   See also: tse.x13.ao, tse.x13.ls, tse.x13.td.
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('aicdiff',D,'aictest',D,'chi2test',D,'chi2testcv',D,'data',D, ...
        'file',D,'format',D,'print',D,'save',D,'pvaictest',D,'start',D, ...
        'testalleaster',D,'tlimit',D,'user',D,'usertype',D,'variables',D, ...
        'b',D,'fixb',D,'centeruser',D,'eastermeans',D,'noapply',D,'tcrate',D);
    d.savelog = {'aictest','chi2test'};
    o = tse.x13.getopts(d, args);

    % start and user are always derived from data (mirrors the Julia constructor)
    o.start = D;
    o.user = D;
    if ~tse.x13.isdefault(o.data)
        o.start = first(tse.rangeof(o.data));
        names = cellstr(o.data.colnames);
        if numel(names) == 1
            o.user = names{1};
        else
            o.user = names;
        end
    end

    if ~tse.x13.isdefault(o.aicdiff) && ~tse.x13.isdefault(o.pvaictest)
        error('tseries:noMatch', 'aicdiff cannot be used in the same regression spec as pvaictest.');
    end

    if ~tse.x13.isdefault(o.usertype)
        utAllowed = {'constant','seasonal','td','lom','loq','lpyear','ao','ls','so', ...
            'transitory','user','holiday','holiday2','holiday3','holiday4','holiday5'};
        ut = o.usertype;
        if iscell(ut)
            if iscell(o.user) && numel(ut) > 1 && numel(ut) ~= numel(o.user)
                error('tseries:noMatch', 'usertype must match the number of user series (%d).', numel(o.user));
            end
            if any(~ismember(ut, utAllowed))
                error('tseries:noMatch', 'usertype contains an invalid value.');
            end
        elseif (ischar(ut) || isstring(ut)) && ~ismember(char(ut), utAllowed)
            error('tseries:noMatch', 'usertype contains an invalid value.');
        end
    end

    vars = local_varcell(o.variables);
    if ~isempty(vars)
        allAos = {}; allLss = {};
        for i = 1:numel(vars)
            v = vars{i};
            local_rangecheck(v, 'tdstock', 1, 31);
            local_rangecheck(v, 'easter', 0, 25);
            local_rangecheck(v, 'labor', 1, 25);
            local_rangecheck(v, 'thank', -8, 17);
            local_rangecheck(v, 'sceaster', 1, 24);
            local_rangecheck(v, 'easterstock', 1, 25);
            if isa(v, 'tse.x13.aos'), allAos{end+1} = v; end %#ok<AGROW>
            if isa(v, 'tse.x13.lss'), allLss{end+1} = v; end %#ok<AGROW>
        end
        local_overlapwarn(allAos, 'aos');
        local_overlapwarn(allLss, 'lss');
    end

    aicAllowed = {'td','tdnolpyear','tdstock','td1coef','td1nolpyear','tdstock1coef', ...
        'lom','loq','lpyear','easter','easterstock','user'};
    local_aictestcheck(o.aictest, aicAllowed);

    o.print = tse.x13.expandall(o.print, {'regressionmatrix','aictest','outlier', ...
        'aoutlier','levelshift','seasonaloutlier','transitory','temporarychange', ...
        'tradingday','holiday','regseasonal','userdef','chi2test','dailyweights'});
    o.save = tse.x13.expandall(o.save, {'regressionmatrix','outlier','aoutlier', ...
        'levelshift','seasonaloutlier','transitory','temporarychange','tradingday', ...
        'holiday','regseasonal','userdef'});

    obj = tse.x13.X13regression();
    obj.aicdiff = o.aicdiff; obj.aictest = o.aictest; obj.chi2test = o.chi2test;
    obj.chi2testcv = o.chi2testcv; obj.data = o.data; obj.file = o.file; obj.format = o.format;
    obj.print = o.print; obj.save = o.save; obj.savelog = o.savelog; obj.pvaictest = o.pvaictest;
    obj.start = o.start; obj.testalleaster = o.testalleaster; obj.tlimit = o.tlimit;
    obj.user = o.user; obj.usertype = o.usertype; obj.variables = o.variables;
    obj.b = o.b; obj.fixb = o.fixb; obj.centeruser = o.centeruser;
    obj.eastermeans = o.eastermeans; obj.noapply = o.noapply; obj.tcrate = o.tcrate;

    out = tse.x13.specfinish(spec, 'regression', obj);
end

function c = local_varcell(v)
    if tse.x13.isdefault(v)
        c = {};
    elseif iscell(v)
        c = v;
    else
        c = {v};
    end
end

function local_rangecheck(v, kind, lo, hi)
    if isa(v, ['tse.x13.' kind]) && (v.n < lo || v.n > hi)
        error('tseries:noMatch', '%s variables must have a value between %d and %d. Received: %d.', ...
            kind, lo, hi, v.n);
    end
end

function local_overlapwarn(list, kind)
    for a = 1:numel(list)
        for b = 1:numel(list)
            if a ~= b
                if list{a}.mit1 <= list{b}.mit2 && list{b}.mit1 <= list{a}.mit2
                    warning('The variables argument has overlapping %s specifications.', kind);
                    return
                end
            end
        end
    end
end

function local_aictestcheck(aictest, allowed)
    if iscell(aictest)
        if any(~ismember(aictest, allowed))
            error('tseries:noMatch', 'aictest contains an invalid value.');
        end
    elseif ischar(aictest) || isstring(aictest)
        if ~ismember(char(aictest), allowed)
            error('tseries:noMatch', 'aictest contains an invalid value.');
        end
    end
end

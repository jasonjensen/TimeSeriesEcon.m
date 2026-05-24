function out = x11regression(varargin)
%X11REGRESSION  Build (or set on a spec) the x11regression spec.
%
%   tse.x13.x11regression('variables', {'td'}, 'aictest', 'td')
%   tse.x13.x11regression(spec, ...)      sets spec.x11regression
%
%   See also: tse.x13.x11, tse.x13.regression.
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('aicdiff',D,'aictest',D,'critical',D,'data',D,'file',D,'format',D, ...
        'outliermethod',D,'outlierspan',D,'print',D,'save',D,'prior',D,'sigma',D, ...
        'span',D,'tdprior',D,'usertype',D,'variables',D,'almost',D,'b',D,'fixb',D, ...
        'centeruser',D,'eastermeans',D,'forcecal',D,'noapply',D,'reweight',D, ...
        'umdata',D,'umfile',D,'umformat',D,'umprecision',D,'umtrimzero',D);
    d.savelog = 'aictest';
    d.start = D; d.user = D; d.umstart = D; d.umname = D;
    o = tse.x13.getopts(d, args);

    o.start = D; o.user = D;
    if ~tse.x13.isdefault(o.data)
        o.start = first(tse.rangeof(o.data));
        names = cellstr(o.data.colnames);
        if numel(names) == 1, o.user = names{1}; else, o.user = names; end
    end
    o.umstart = D; o.umname = D;
    if ~tse.x13.isdefault(o.umdata)
        o.umstart = first(tse.rangeof(o.umdata));
        umnames = cellstr(o.umdata.colnames);
        if numel(umnames) == 1, o.umname = umnames{1}; else, o.umname = umnames; end
    end

    tdset = {'td','tdstock','td1coef','tdstock1coef'};
    if ~tse.x13.isdefault(o.variables) && ~tse.x13.isdefault(o.aictest)
        if iscell(o.variables), vars = o.variables; else, vars = {o.variables}; end
        if iscell(o.aictest), aics = o.aictest; else, aics = {char(o.aictest)}; end
        typesUsed = cellfun(@tse.x13.regvartype, vars, 'UniformOutput', false);
        if any(ismember(aics, tdset)) && any(ismember(typesUsed, tdset))
            for i = 1:numel(aics)
                if ismember(aics{i}, tdset) && ~ismember(aics{i}, typesUsed)
                    error('tseries:noMatch', ...
                        'Trading-day regressors in aictest must correspond to td regressors in variables.');
                end
            end
        end
    end

    aicAllowed = {'td','tdstock','td1coef','tdstock1coef','easter','user'};
    if iscell(o.aictest)
        if any(~ismember(o.aictest, aicAllowed))
            error('tseries:noMatch', 'aictest contains an invalid value.');
        end
    elseif ischar(o.aictest) || isstring(o.aictest)
        if ~ismember(char(o.aictest), aicAllowed)
            error('tseries:noMatch', 'aictest contains an invalid value.');
        end
    end

    if ~tse.x13.isdefault(o.sigma) && o.sigma <= 0.0
        error('tseries:noMatch', 'sigma must be greater than 0. Received: %g.', o.sigma);
    end
    if ~tse.x13.isdefault(o.tdprior)
        if numel(o.tdprior) ~= 7
            error('tseries:noMatch', 'tdprior must have a length of exactly 7. Received %d.', numel(o.tdprior));
        end
        if any(o.tdprior < 0.0)
            error('tseries:noMatch', 'tdprior values must all be greater than or equal to 0.');
        end
    end
    if ~tse.x13.isdefault(o.usertype)
        utAllowed = {'td','holiday','user'};
        if iscell(o.usertype)
            if iscell(o.user) && numel(o.usertype) > 1 && numel(o.usertype) ~= numel(o.user)
                error('tseries:noMatch', 'usertype must match the number of user series (%d).', numel(o.user));
            end
            if any(~ismember(o.usertype, utAllowed))
                error('tseries:noMatch', 'usertype contains an invalid value.');
            end
        elseif (ischar(o.usertype) || isstring(o.usertype)) && ~ismember(char(o.usertype), utAllowed)
            error('tseries:noMatch', 'usertype contains an invalid value.');
        end
    end
    if isa(o.outlierspan, 'tse.x13.Span') && o.outlierspan.hasFuzzyEnd()
        error('tseries:noMatch', 'Spans with a fuzzy ending time are not allowed in the outlierspan argument.');
    end

    o.print = tse.x13.expandall(o.print, {'priortd','extremeval','x11reg','tradingday', ...
        'combtradingday','holiday','calendar','combcalendar','outlierhdr','xaictest', ...
        'extremevalb','x11regb','tradingdayb','combtradingdayb','holidayb','calendarb', ...
        'combcalendarb','outlieriter','outliertests','xregressionmatrix','xregressioncmatrix'});
    o.save = tse.x13.expandall(o.save, {'priortd','extremeval','tradingday','combtradingday', ...
        'holiday','calendar','combcalendar','extremevalb','tradingdayb','combtradingdayb', ...
        'holidayb','calendarb','combcalendarb','outlieriter','xregressionmatrix','xregressioncmatrix'});

    obj = tse.x13.X13x11regression();
    obj.aicdiff = o.aicdiff; obj.aictest = o.aictest; obj.critical = o.critical;
    obj.data = o.data; obj.file = o.file; obj.format = o.format;
    obj.outliermethod = o.outliermethod; obj.outlierspan = o.outlierspan;
    obj.print = o.print; obj.save = o.save; obj.savelog = o.savelog; obj.prior = o.prior;
    obj.sigma = o.sigma; obj.span = o.span; obj.start = o.start; obj.tdprior = o.tdprior;
    obj.user = o.user; obj.usertype = o.usertype; obj.variables = o.variables;
    obj.almost = o.almost; obj.b = o.b; obj.fixb = o.fixb; obj.centeruser = o.centeruser;
    obj.eastermeans = o.eastermeans; obj.forcecal = o.forcecal; obj.noapply = o.noapply;
    obj.reweight = o.reweight; obj.umdata = o.umdata; obj.umfile = o.umfile;
    obj.umformat = o.umformat; obj.umname = o.umname; obj.umprecision = o.umprecision;
    obj.umstart = o.umstart; obj.umtrimzero = o.umtrimzero;

    out = tse.x13.specfinish(spec, 'x11regression', obj);
end

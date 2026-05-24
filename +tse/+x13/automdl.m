function out = automdl(varargin)
%AUTOMDL  Build (or set on a spec) the automdl spec for automatic model choice.
%
%   tse.x13.automdl('maxorder', [3 1], 'maxdiff', [1 1])
%   tse.x13.automdl(spec, ...)      sets spec.automdl
%
%   Use NaN for a "missing" entry in maxorder/maxdiff.
%
%   See also: tse.x13.arima, tse.x13.pickmdl.
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('diff',D,'acceptdefault',D,'checkmu',D,'ljungboxlimit',D, ...
        'maxorder',D,'maxdiff',D,'mixed',D,'armalimit',D,'balanced',D, ...
        'exactdiff',D,'fcstlim',D,'hrinitial',D,'reducecv',D,'rejectfcst',D,'urfinal',D);
    d.print = {'autochoice','autochoicemdl','autodefaulttests','autofinaltests', ...
        'autoljungboxtest','bestfivemdl','header','unitroottest','unitroottestmdl'};
    d.savelog = 'alldiagnostics';
    o = tse.x13.getopts(d, args);

    if ~tse.x13.isdefault(o.diff)
        if numel(o.diff) ~= 2
            error('tseries:noMatch', 'The diff argument of the automdl spec must contain exactly two values.');
        end
        if ~ismember(o.diff(1), [0 1 2])
            error('tseries:noMatch', 'Acceptable regular differencing orders of automdl are 0, 1, 2. Received: %d.', o.diff(1));
        end
        if ~ismember(o.diff(2), [0 1])
            error('tseries:noMatch', 'Acceptable seasonal differencing orders of automdl are 0 and 1. Received: %d.', o.diff(2));
        end
        if ~tse.x13.isdefault(o.maxdiff)
            warning('The diff argument of the automdl spec will be ignored because a maxdiff argument is specified.');
        end
    end
    if ~tse.x13.isdefault(o.maxdiff)
        if numel(o.maxdiff) ~= 2
            error('tseries:noMatch', 'The maxdiff argument of the automdl spec must contain exactly two values.');
        end
        if ~isnan(o.maxdiff(1)) && ~ismember(o.maxdiff(1), [0 1 2])
            error('tseries:noMatch', 'Acceptable regular maximum differencing orders of automdl are 1 and 2. Received: %d.', o.maxdiff(1));
        end
        if ~isnan(o.maxdiff(1)) && ~ismember(o.maxdiff(2), [0 1])
            error('tseries:noMatch', 'The only acceptable seasonal maximum differencing order of automdl is 1. Received: %d.', o.maxdiff(2));
        end
    end
    if ~tse.x13.isdefault(o.maxorder)
        if numel(o.maxorder) ~= 2
            error('tseries:noMatch', 'The maxorder argument of the automdl spec must contain exactly two values.');
        end
        if ~isnan(o.maxorder(1)) && ~ismember(o.maxorder(1), [1 2 3 4])
            error('tseries:noMatch', 'The maximum regular ARMA order must be between 1 and 4. Received: %d.', o.maxorder(1));
        end
        if ~isnan(o.maxorder(2)) && ~ismember(o.maxorder(2), [1 2])
            error('tseries:noMatch', 'The maximum seasonal ARMA order can be 1 or 2. Received: %d.', o.maxorder(2));
        end
    end
    if ~tse.x13.isdefault(o.armalimit) && o.armalimit <= 0.0
        error('tseries:noMatch', 'armalimit should be greater than zero. Received: %g.', o.armalimit);
    end
    if ~tse.x13.isdefault(o.fcstlim) && (o.fcstlim < 0 || o.fcstlim > 100)
        error('tseries:noMatch', 'fcstlim must be between 0 and 100. Received: %g.', o.fcstlim);
    end
    if ~tse.x13.isdefault(o.reducecv) && (o.reducecv < 0.0 || o.reducecv > 1.0)
        error('tseries:noMatch', 'reducecv should be between 0 and 1. Received: %g.', o.reducecv);
    end
    if ~tse.x13.isdefault(o.urfinal) && o.urfinal < 1.0
        error('tseries:noMatch', 'urfinal should be greater than 1. Received: %g.', o.urfinal);
    end

    o.print = tse.x13.expandall(o.print, {'autochoice','autochoicemdl', ...
        'autodefaulttests','autofinaltests','autoljungboxtest','bestfivemdl', ...
        'header','unitroottest','unitroottestmdl'});

    obj = tse.x13.X13automdl();
    obj.diff = o.diff; obj.acceptdefault = o.acceptdefault; obj.checkmu = o.checkmu;
    obj.ljungboxlimit = o.ljungboxlimit; obj.maxorder = o.maxorder; obj.maxdiff = o.maxdiff;
    obj.mixed = o.mixed; obj.print = o.print; obj.savelog = o.savelog;
    obj.armalimit = o.armalimit; obj.balanced = o.balanced; obj.exactdiff = o.exactdiff;
    obj.fcstlim = o.fcstlim; obj.hrinitial = o.hrinitial; obj.reducecv = o.reducecv;
    obj.rejectfcst = o.rejectfcst; obj.urfinal = o.urfinal;

    out = tse.x13.specfinish(spec, 'automdl', obj);
end

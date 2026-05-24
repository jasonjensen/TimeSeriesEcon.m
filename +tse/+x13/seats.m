function out = seats(varargin)
%SEATS  Build (or set on a spec) the seats spec for SEATS seasonal adjustment.
%
%   tse.x13.seats('noadmiss', true)
%   tse.x13.seats(spec, ...)      sets spec.seats
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('appendfcst',D,'finite',D,'hpcycle',D,'noadmiss',D, ...
        'print',D,'save',D,'printphtrf',D,'qmax',D,'statseas',D,'tabtables',D, ...
        'bias',D,'epsiv',D,'epsphi',D,'hplan',D,'imean',D,'maxit',D,'rmod',D,'xl',D);
    d.out = 0;
    d.savelog = D;
    o = tse.x13.getopts(d, args);

    if ~tse.x13.isdefault(o.epsiv) && o.epsiv <= 0.0
        error('tseries:noMatch', 'epsiv should be a small positive number. Received: %g.', o.epsiv);
    end
    if ~tse.x13.isdefault(o.hpcycle) && ~tse.x13.isdefault(o.hplan) && isequal(o.hpcycle, false)
        warning('Hodrick-Prescott filters will be used even though hpcycle is false because hplan was specified.');
    end

    % matches the Julia constructor, which clears savelog unconditionally
    o.savelog = D;

    saveAll = {'trend','seasonal','irregular','seasonaladj','transitory','adjustfac', ...
        'adjustmentratio','trendfcstdecomp','seasonalfcstdecomp','ofd','seasonaladjfcstdecomp', ...
        'transitoryfcstdecomp','seasadjconst','trendconst','totaladjustment','difforiginal', ...
        'diffseasonaladj','difftrend','seasonalsum','cycle','longtermtrend','componentmodels', ...
        'filtersaconc','filtersasym','filtertrendconc','filtertrendsym','squaredgainsaconc', ...
        'squaredgainsasym','squaredgaintrendconc','squaredgaintrendsym','timeshiftsaconc', ...
        'timeshifttrendconc','wkendfilter','seasonalpct','irregularpct','transitorypct','adjustfacpct'};
    if (ischar(o.print) && strcmp(o.print, 'all')) || ...
            (iscell(o.print) && isscalar(o.print) && strcmp(o.print{1}, 'all'))
        warning('The print=all option is not available for the seats spec.');
        o.print = D;
    end
    if (ischar(o.save) && strcmp(o.save, 'all')) || ...
            (iscell(o.save) && isscalar(o.save) && strcmp(o.save{1}, 'all'))
        o.save = saveAll;
        o.out = 0;
    end

    obj = tse.x13.X13seats();
    obj.appendfcst = o.appendfcst; obj.finite = o.finite; obj.hpcycle = o.hpcycle;
    obj.noadmiss = o.noadmiss; obj.out = o.out; obj.print = o.print; obj.save = o.save;
    obj.savelog = o.savelog; obj.printphtrf = o.printphtrf; obj.qmax = o.qmax;
    obj.statseas = o.statseas; obj.tabtables = o.tabtables; obj.bias = o.bias;
    obj.epsiv = o.epsiv; obj.epsphi = o.epsphi; obj.hplan = o.hplan; obj.imean = o.imean;
    obj.maxit = o.maxit; obj.rmod = o.rmod; obj.xl = o.xl;

    out = tse.x13.specfinish(spec, 'seats', obj);
end

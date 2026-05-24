function out = force(varargin)
%FORCE  Build (or set on a spec) the force spec for forcing yearly totals.
%
%   tse.x13.force('type', 'regress', 'rho', 0.8, 'start', tse.x13.M(10))
%   tse.x13.force(spec, ...)      sets spec.force
%
%   start may be a month/quarter marker (tse.x13.M(n)/Q(n)) or a char symbol.
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('lambda',D,'mode',D,'print',D,'save',D,'rho',D,'round',D, ...
        'start',D,'target',D,'type',D,'usefcst',D,'indforce',D);
    o = tse.x13.getopts(d, args);

    if ~tse.x13.isdefault(o.rho) && (o.rho < 0.0 || o.rho > 1.0)
        error('tseries:noMatch', 'rho must be between 0 and 1. Received: %g.', o.rho);
    end

    o.print = tse.x13.expandall(o.print, {'seasadjtot','saround','revsachanges','rndsachanges'});
    o.save = tse.x13.expandall(o.save, {'seasadjtot','saround','revsachanges', ...
        'rndsachanges','revsachangespct','rndsachangespct'});

    obj = tse.x13.X13force();
    obj.lambda = o.lambda; obj.mode = o.mode; obj.print = o.print; obj.save = o.save;
    obj.rho = o.rho; obj.round = o.round; obj.start = o.start; obj.target = o.target;
    obj.type = o.type; obj.usefcst = o.usefcst; obj.indforce = o.indforce;

    out = tse.x13.specfinish(spec, 'force', obj);
end

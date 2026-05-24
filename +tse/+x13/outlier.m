function out = outlier(varargin)
%OUTLIER  Build (or set on a spec) the outlier spec for automatic detection.
%
%   tse.x13.outlier('critical', 4.0, 'types', 'ao')
%   tse.x13.outlier('critical', [3.0 4.5 4.0], 'types', 'all')
%   tse.x13.outlier(spec, ...)      sets spec.outlier
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('critical',D,'lsrun',D,'method',D,'print',D,'save',D, ...
        'span',D,'types',D,'almost',D,'tcrate',D);
    d.savelog = 'identified';
    o = tse.x13.getopts(d, args);

    if isnumeric(o.critical) && ~isscalar(o.critical) && numel(o.critical) > 3
        error('tseries:noMatch', 'critical can contain up to three values. Received %d.', numel(o.critical));
    end
    if ~tse.x13.isdefault(o.lsrun) && (o.lsrun < 0 || o.lsrun > 5)
        error('tseries:noMatch', 'lsrun can take values from 0 to 5. Received: %d.', o.lsrun);
    end
    if ~tse.x13.isdefault(o.almost) && o.almost < 0.0
        error('tseries:noMatch', 'almost must have a value greater than zero. Received: %g.', o.almost);
    end
    if ~tse.x13.isdefault(o.tcrate) && (o.tcrate <= 0.0 || o.tcrate >= 1.0)
        error('tseries:noMatch', 'tcrate must be greater than zero and less than one. Received: %g.', o.tcrate);
    end
    if isa(o.span, 'tse.x13.Span') && o.span.hasFuzzyEnd()
        error('tseries:noMatch', 'Spans with a fuzzy ending time are not allowed in the span argument of the outlier spec.');
    end

    o.print = tse.x13.expandall(o.print, {'header','iterations','tests','temporaryls','finaltests'});
    o.save = tse.x13.expandall(o.save, {'iterations','finaltests'});

    obj = tse.x13.X13outlier();
    obj.critical = o.critical; obj.lsrun = o.lsrun; obj.method = o.method;
    obj.print = o.print; obj.save = o.save; obj.savelog = o.savelog; obj.span = o.span;
    obj.types = o.types; obj.almost = o.almost; obj.tcrate = o.tcrate;

    out = tse.x13.specfinish(spec, 'outlier', obj);
end

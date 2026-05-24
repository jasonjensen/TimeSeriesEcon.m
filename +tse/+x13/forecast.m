function out = forecast(varargin)
%FORECAST  Build (or set on a spec) the forecast spec.
%
%   tse.x13.forecast('maxlead', 15, 'exclude', 10, 'probability', 0.9)
%   tse.x13.forecast(spec, ...)      sets spec.forecast
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('exclude',D,'lognormal',D,'maxback',D,'maxlead',D,'print',D, ...
        'save',D,'probability',D);
    o = tse.x13.getopts(d, args);

    o.print = tse.x13.expandall(o.print, {'transformed','variances','forecasts','transformedbcst','backcasts'});
    o.save = tse.x13.expandall(o.save, {'transformed','variances','forecasts','transformedbcst','backcasts'});

    obj = tse.x13.X13forecast();
    obj.exclude = o.exclude; obj.lognormal = o.lognormal; obj.maxback = o.maxback;
    obj.maxlead = o.maxlead; obj.print = o.print; obj.save = o.save; obj.probability = o.probability;

    out = tse.x13.specfinish(spec, 'forecast', obj);
end

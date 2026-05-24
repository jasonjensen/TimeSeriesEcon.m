function out = spectrum(varargin)
%SPECTRUM  Build (or set on a spec) the spectrum spec.
%
%   tse.x13.spectrum('type', 'periodogram')
%   tse.x13.spectrum(spec, ...)      sets spec.spectrum
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('logqs',D,'print',D,'save',D,'qcheck',D,'start',D,'tukey120',D, ...
        'decibel',D,'difference',D,'maxar',D,'peakwidth',D,'series',D,'siglevel',D,'type',D);
    d.savelog = 'alldiagnostics';
    o = tse.x13.getopts(d, args);

    o.print = tse.x13.expandall(o.print, {'qcheck','qs','specorig','specsa','specirr', ...
        'specseatssa','specseatsirr','specextresiduals','specresidual','speccomposite', ...
        'specindirr','specindsa','tukeypeaks'});
    o.save = tse.x13.expandall(o.save, {'specorig','specsa','specirr','specseatssa', ...
        'specseatsirr','specextresiduals','specresidual','speccomposite','specindirr','specindsa'});

    obj = tse.x13.X13spectrum();
    obj.logqs = o.logqs; obj.print = o.print; obj.save = o.save; obj.savelog = o.savelog;
    obj.qcheck = o.qcheck; obj.start = o.start; obj.tukey120 = o.tukey120;
    obj.decibel = o.decibel; obj.difference = o.difference; obj.maxar = o.maxar;
    obj.peakwidth = o.peakwidth; obj.series = o.series; obj.siglevel = o.siglevel; obj.type = o.type;

    out = tse.x13.specfinish(spec, 'spectrum', obj);
end

function out = slidingspans(varargin)
%SLIDINGSPANS  Build (or set on a spec) the slidingspans spec.
%
%   tse.x13.slidingspans('length', 60, 'numspans', 4)
%   tse.x13.slidingspans(spec, ...)      sets spec.slidingspans
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('cutchng',D,'cutseas',D,'cuttd',D,'fixmdl',D,'fixreg',D, ...
        'length',D,'numspans',D,'outlier',D,'print',D,'save',D,'start',D, ...
        'additivesa',D,'fixx11reg',D,'x11outlier',D);
    d.savelog = 'percents';
    o = tse.x13.getopts(d, args);

    if ~tse.x13.isdefault(o.fixmdl) && ~tse.x13.isdefault(o.fixreg) && isequal(o.fixmdl, true)
        warning('fixreg will be ignored because fixmdl is set to true.');
    end

    o.print = tse.x13.expandall(o.print, {'header','ssftest','factormeans','percent', ...
        'summary','yysummary','indfactormeans','indpercent','indsummary','yypercent', ...
        'sfspans','chngspans','saspans','ychngspans','tdspans','indyypercent', ...
        'indyysummary','indsfspans','indchngspans','indsaspans','indychngspans'});
    o.save = tse.x13.expandall(o.save, {'sfspans','chngspans','saspans','ychngspans', ...
        'tdspans','indsfspans','indchngspans','indsaspans','indychngspans'});

    obj = tse.x13.X13slidingspans();
    obj.cutchng = o.cutchng; obj.cutseas = o.cutseas; obj.cuttd = o.cuttd;
    obj.fixmdl = o.fixmdl; obj.fixreg = o.fixreg; obj.length = o.length;
    obj.numspans = o.numspans; obj.outlier = o.outlier; obj.print = o.print;
    obj.save = o.save; obj.savelog = o.savelog; obj.start = o.start;
    obj.additivesa = o.additivesa; obj.fixx11reg = o.fixx11reg; obj.x11outlier = o.x11outlier;

    out = tse.x13.specfinish(spec, 'slidingspans', obj);
end

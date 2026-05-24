function out = identify(varargin)
%IDENTIFY  Build (or set on a spec) the identify spec (ACF/PACF tables).
%
%   tse.x13.identify('diff', [0 1], 'sdiff', [0 1], 'maxlag', 12)
%   tse.x13.identify(spec, ...)      sets spec.identify
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('diff',D,'sdiff',D,'maxlag',D,'print',D,'save',D);
    o = tse.x13.getopts(d, args);

    o.print = tse.x13.expandall(o.print, {'acf','acfplot','pacf','pacfplot','regcoefficients'});
    o.save = tse.x13.expandall(o.save, {'acf','pacf'});

    obj = tse.x13.X13identify();
    obj.diff = o.diff; obj.sdiff = o.sdiff; obj.maxlag = o.maxlag;
    obj.print = o.print; obj.save = o.save;

    out = tse.x13.specfinish(spec, 'identify', obj);
end

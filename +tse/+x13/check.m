function out = check(varargin)
%CHECK  Build (or set on a spec) the check spec for residual diagnostics.
%
%   tse.x13.check('maxlag', 12, 'qtype', 'ljungbox')
%   tse.x13.check(spec, ...)      sets spec.check
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('maxlag',D,'qtype',D,'print',D,'save',D,'acflimit',D,'qlimit',D);
    d.savelog = 'alldiagnostics';
    o = tse.x13.getopts(d, args);

    o.print = tse.x13.expandall(o.print, {'acf','acfplot','pacf','pacfplot', ...
        'acfsquared','acfsquaredplot','normalitytest','durbinwatson','friedmantest','histogram'});
    o.save = tse.x13.expandall(o.save, {'acf','pacf','acfsquared'});

    obj = tse.x13.X13check();
    obj.maxlag = o.maxlag; obj.qtype = o.qtype; obj.print = o.print;
    obj.save = o.save; obj.savelog = o.savelog; obj.acflimit = o.acflimit; obj.qlimit = o.qlimit;

    out = tse.x13.specfinish(spec, 'check', obj);
end

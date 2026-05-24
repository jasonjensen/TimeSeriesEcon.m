function out = estimate(varargin)
%ESTIMATE  Build (or set on a spec) the estimate spec.
%
%   tse.x13.estimate('exact', 'ma', 'maxiter', 100, 'tol', 1e-4)
%   tse.x13.estimate(spec, ...)      sets spec.estimate
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('exact',D,'maxiter',D,'outofsample',D,'print',D,'save',D, ...
        'tol',D,'file',D,'fix',D);
    d.savelog = 'alldiagnostics';
    o = tse.x13.getopts(d, args);

    o.print = tse.x13.expandall(o.print, {'options','model','estimates','averagefcsterr', ...
        'lkstats','iterations','iterationerrors','regcmatrix','armacmatrix','lformulas', ...
        'roots','regressioneffects','regressionresiduals','residuals'});
    o.save = tse.x13.expandall(o.save, {'model','estimates','lkstats','iterations', ...
        'regcmatrix','armacmatrix','roots','regressioneffects','regressionresiduals','residuals'});

    obj = tse.x13.X13estimate();
    obj.exact = o.exact; obj.maxiter = o.maxiter; obj.outofsample = o.outofsample;
    obj.print = o.print; obj.save = o.save; obj.savelog = o.savelog;
    obj.tol = o.tol; obj.file = o.file; obj.fix = o.fix;

    out = tse.x13.specfinish(spec, 'estimate', obj);
end

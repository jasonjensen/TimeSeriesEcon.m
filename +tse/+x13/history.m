function out = history(varargin)
%HISTORY  Build (or set on a spec) the history spec for revisions analysis.
%
%   tse.x13.history('estimates', {'sadj','trend'}, 'fstep', [1 12])
%   tse.x13.history(spec, ...)      sets spec.history
    [spec, args] = tse.x13.specsplit(varargin{:});
    D = tse.x13.X13default();
    d = struct('endtable',D,'estimates',D,'fixmdl',D,'fixreg',D,'fstep',D, ...
        'print',D,'save',D,'sadjlags',D,'start',D,'target',D,'trendlags',D, ...
        'fixx11reg',D,'outlier',D,'outlierwin',D,'refresh',D,'transformfcst',D,'x11outlier',D);
    d.savelog = {'alldiagnostics'};
    o = tse.x13.getopts(d, args);

    if isnumeric(o.fstep) && ~isscalar(o.fstep)
        if numel(o.fstep) > 4
            error('tseries:noMatch', 'fstep can contain up to four forecast leads. Received %d.', numel(o.fstep));
        end
        if any(o.fstep < 1)
            error('tseries:noMatch', 'fstep values cannot be less than one.');
        end
    elseif isnumeric(o.fstep) && isscalar(o.fstep) && o.fstep < 1
        error('tseries:noMatch', 'fstep cannot be less than one. Received: %d.', o.fstep);
    end
    if isnumeric(o.sadjlags) && ~isscalar(o.sadjlags)
        if numel(o.sadjlags) > 5
            error('tseries:noMatch', 'sadjlags can contain up to five revision lags. Received %d.', numel(o.sadjlags));
        end
        if any(o.sadjlags < 1)
            error('tseries:noMatch', 'sadjlags values cannot be less than one.');
        end
    elseif isnumeric(o.sadjlags) && isscalar(o.sadjlags) && o.sadjlags < 1
        error('tseries:noMatch', 'sadjlags cannot be less than one. Received: %d.', o.sadjlags);
    end

    o.print = tse.x13.expandall(o.print, {'header','outlierhistory','sarevisions', ...
        'sasummary','chngrevisions','chngsummary','indsarevisions','indsasummary', ...
        'trendrevisions','trendsummary','trendchngrevisions','trendchngsummary', ...
        'sfrevisions','sfsummary','lkhdhistory','fcsterrors','armahistory','tdhistory', ...
        'sfilterhistory','saestimates','chngestimates','indsaestimates','trendestimates', ...
        'trendchngestimates','sfestimates','fcsthistory'});
    o.save = tse.x13.expandall(o.save, {'outlierhistory','sarevisions','chngrevisions', ...
        'indsarevisions','trendrevisions','trendchngrevisions','sfrevisions','lkhdhistory', ...
        'fcsterrors','armahistory','tdhistory','sfilterhistory','saestimates','chngestimates', ...
        'indsaestimates','trendestimates','trendchngestimates','sfestimates','fcsthistory'});

    obj = tse.x13.X13history();
    obj.endtable = o.endtable; obj.estimates = o.estimates; obj.fixmdl = o.fixmdl;
    obj.fixreg = o.fixreg; obj.fstep = o.fstep; obj.print = o.print; obj.save = o.save;
    obj.savelog = o.savelog; obj.sadjlags = o.sadjlags; obj.start = o.start;
    obj.target = o.target; obj.trendlags = o.trendlags; obj.fixx11reg = o.fixx11reg;
    obj.outlier = o.outlier; obj.outlierwin = o.outlierwin; obj.refresh = o.refresh;
    obj.transformfcst = o.transformfcst; obj.x11outlier = o.x11outlier;

    out = tse.x13.specfinish(spec, 'history', obj);
end

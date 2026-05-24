function out = arima(varargin)
%ARIMA  Build (or set on a spec) the arima spec.
%
%   tse.x13.arima(tse.x13.ArimaModel(0,1,1))
%   tse.x13.arima(spec1, spec2, ...)         from ArimaSpec objects
%   tse.x13.arima(spec, model, 'title', "ARIMA Model")   sets spec.arima
%
%   See also: tse.x13.ArimaModel, tse.x13.ArimaSpec.
    [spec, args] = tse.x13.specsplit(varargin{:});
    [pos, nv] = tse.x13.poscut(args);

    if numel(pos) == 1 && isa(pos{1}, 'tse.x13.ArimaModel')
        model = pos{1};
    elseif ~isempty(pos) && all(cellfun(@(a) isa(a, 'tse.x13.ArimaSpec'), pos))
        model = tse.x13.ArimaModel([pos{:}]);
    else
        error('tseries:noMatch', 'arima requires an ArimaModel or one or more ArimaSpec objects.');
    end

    D = tse.x13.X13default();
    o = tse.x13.getopts(struct('title',D,'ar',D,'ma',D,'fixar',D,'fixma',D), nv);

    if ~tse.x13.isdefault(o.fixar)
        nar = 0; if ~tse.x13.isdefault(o.ar), nar = numel(o.ar); end
        if numel(o.fixar) ~= nar
            error('tseries:noMatch', 'fixar must have the same length as ar.');
        end
    end
    if ~tse.x13.isdefault(o.fixma)
        nma = 0; if ~tse.x13.isdefault(o.ma), nma = numel(o.ma); end
        if numel(o.fixma) ~= nma
            error('tseries:noMatch', 'fixma must have the same length as ma.');
        end
    end
    if (ischar(o.title) || isstring(o.title)) && strlength(string(o.title)) > 79
        warning('Arima title truncated to 79 characters. Full title: %s', char(o.title));
        tt = char(o.title); o.title = tt(1:79);
    end

    obj = tse.x13.X13arima();
    obj.model = model; obj.title = o.title;
    obj.ar = o.ar; obj.ma = o.ma; obj.fixar = o.fixar; obj.fixma = o.fixma;

    out = tse.x13.specfinish(spec, 'arima', obj);
end

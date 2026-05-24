function out = pickmdl(varargin)
%PICKMDL  Build (or set on a spec) the pickmdl spec for automatic model selection.
%
%   tse.x13.pickmdl([m1, m2, m3])           from a vector of ArimaModel objects
%   tse.x13.pickmdl(m1, m2)                  from ArimaModel objects
%   tse.x13.pickmdl('file', "models.mdl")    from a model file
%   tse.x13.pickmdl(spec, models, ...)       sets spec.pickmdl
%
%   See also: tse.x13.ArimaModel.
    [spec, args] = tse.x13.specsplit(varargin{:});
    [pos, nv] = tse.x13.poscut(args);

    models = tse.x13.X13default();
    if ~isempty(pos)
        if all(cellfun(@(a) isa(a, 'tse.x13.ArimaModel'), pos))
            models = [pos{:}];
        else
            error('tseries:noMatch', 'pickmdl positional arguments must be ArimaModel objects.');
        end
    end

    D = tse.x13.X13default();
    d = struct('bcstlim',D,'fcstlim',D,'identify',D,'method',D,'mode',D, ...
        'outofsample',D,'overdiff',D,'print',D,'qlim',D,'file',D);
    d.savelog = 'automodel';
    o = tse.x13.getopts(d, nv);

    if ~tse.x13.isdefault(o.bcstlim) && (o.bcstlim < 0 || o.bcstlim > 100)
        error('tseries:noMatch', 'bcstlim must be between 0 and 100. Received: %d.', o.bcstlim);
    end
    if ~tse.x13.isdefault(o.fcstlim) && (o.fcstlim < 0 || o.fcstlim > 100)
        error('tseries:noMatch', 'fcstlim must be between 0 and 100. Received: %d.', o.fcstlim);
    end
    if ~tse.x13.isdefault(o.qlim) && (o.qlim < 0 || o.qlim > 100)
        error('tseries:noMatch', 'qlim must be between 0 and 100. Received: %d.', o.qlim);
    end
    if ~tse.x13.isdefault(o.overdiff)
        if o.overdiff > 1.0
            error('tseries:noMatch', 'overdiff must not be greater than 1. Received: %g.', o.overdiff);
        end
        if o.overdiff < 0.9
            error('tseries:noMatch', 'overdiff should not be less than 0.9. Received: %g.', o.overdiff);
        end
    end
    if ~tse.x13.isdefault(models)
        if numel(models) < 2
            error('tseries:noMatch', 'pickmdl must be given at least two candidate models. Received %d.', numel(models));
        end
        ndef = sum(arrayfun(@(m) isequal(m.default, true), models));
        if ndef > 1
            error('tseries:noMatch', 'pickmdl can only have one model flagged as a default; %d were.', ndef);
        end
    end
    if tse.x13.isdefault(models) && tse.x13.isdefault(o.file)
        error('tseries:noMatch', 'pickmdl must be given either a vector of ArimaModels or the file argument.');
    end

    o.print = tse.x13.expandall(o.print, {'pickmdlchoice','header','usermodels'});

    obj = tse.x13.X13pickmdl();
    obj.bcstlim = o.bcstlim; obj.fcstlim = o.fcstlim; obj.models = models;
    obj.identify = o.identify; obj.method = o.method; obj.mode = o.mode;
    obj.outofsample = o.outofsample; obj.overdiff = o.overdiff; obj.print = o.print;
    obj.savelog = o.savelog; obj.qlim = o.qlim; obj.file = o.file;

    out = tse.x13.specfinish(spec, 'pickmdl', obj);
end

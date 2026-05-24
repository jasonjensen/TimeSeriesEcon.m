function [spec, args] = specsplit(varargin)
%SPECSPLIT  Peel a leading X13spec off an argument list.
%
%   If the first argument is a tse.x13.X13spec it is returned as SPEC (and the
%   remaining arguments as ARGS); otherwise SPEC is [] and ARGS is everything.
%   This lets each spec constructor double as its Julia "name!" mutating form:
%   tse.x13.arima(spec, model) mutates SPEC, tse.x13.arima(model) builds one.
    args = varargin;
    spec = [];
    if ~isempty(args) && isa(args{1}, 'tse.x13.X13spec')
        spec = args{1};
        args(1) = [];
    end
end

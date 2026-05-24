classdef ArimaModel
%ARIMAMODEL  A complete ARIMA model: one or more ArimaSpec factors.
%
%   tse.x13.ArimaModel(p, d, q)
%   tse.x13.ArimaModel(p, d, q, period)
%   tse.x13.ArimaModel(p, d, q, P, D, Q)
%   tse.x13.ArimaModel(spec1, spec2, ...)         from ArimaSpec objects
%   tse.x13.ArimaModel(specArray)                 from a 1xN ArimaSpec array
%
%   Append the name-value pair 'default', true to mark the model as the default
%   choice in a pickmdl list (it is written with a trailing " *").
%
%   See also: tse.x13.ArimaSpec, tse.x13.arima, tse.x13.pickmdl.
    properties
        specs
        default = false
    end
    methods
        function obj = ArimaModel(varargin)
            args = varargin;
            obj.default = false;
            % pull out a trailing 'default', tf name-value pair
            for i = 1:numel(args)-1
                if (ischar(args{i}) || (isstring(args{i}) && isscalar(args{i}))) ...
                        && strcmpi(char(args{i}), 'default')
                    obj.default = logical(args{i+1});
                    args(i:i+1) = [];
                    break
                end
            end

            if isempty(args)
                error('tseries:noMatch', 'ArimaModel requires at least one argument.');
            end

            isspec = cellfun(@(a) isa(a, 'tse.x13.ArimaSpec'), args);
            if all(isspec)
                obj.specs = [args{:}];
            elseif numel(args) == 3
                obj.specs = tse.x13.ArimaSpec(args{1}, args{2}, args{3});
            elseif numel(args) == 4
                obj.specs = tse.x13.ArimaSpec(args{1}, args{2}, args{3}, args{4});
            elseif numel(args) == 6
                obj.specs = tse.x13.ArimaSpec(args{1}, args{2}, args{3}, args{4}, args{5}, args{6});
            else
                error('tseries:noMatch', ...
                    'Unsupported ArimaModel arguments. Provide orders, a period, or ArimaSpec objects.');
            end
        end

        function s = x13str(obj)
            parts = arrayfun(@(sp) sp.x13str(), obj.specs, 'UniformOutput', false);
            s = strjoin(parts, '');
        end
    end
end

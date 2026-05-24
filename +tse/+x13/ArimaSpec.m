classdef ArimaSpec
%ARIMASPEC  One factor of an ARIMA model: orders (p, d, q) and a period.
%
%   tse.x13.ArimaSpec(p, d, q)         period defaults to 0
%   tse.x13.ArimaSpec(p, d, q, period)
%   tse.x13.ArimaSpec(p, d, q, P, D, Q)   returns a 1x2 array of two specs
%   tse.x13.ArimaSpec(p)  / (p, d)        trailing orders default to 0
%
%   p, d and q are normally orders (scalars), e.g. ArimaSpec(2,1,0) -> "(2 1 0)".
%   An operator with explicit (missing) lags is given as a CELL or a numeric
%   vector with more than one element, e.g. ArimaSpec({2},1,0) -> "([2] 1 0)"
%   and ArimaSpec([2 3],0,0) -> "([2, 3] 0 0)".  (A bare 2 and [2] are identical
%   in MATLAB, so the single-lag form must use a cell.)
%
%   See also: tse.x13.ArimaModel, tse.x13.arima.
    properties
        p = 0
        d = 0
        q = 0
        period = 0
    end
    properties (Hidden)
        pExplicit = false
        dExplicit = false
        qExplicit = false
    end
    methods
        function obj = ArimaSpec(varargin)
            if nargin == 6
                obj = [tse.x13.ArimaSpec(varargin{1:3}), ...
                       tse.x13.ArimaSpec(varargin{4:6})];
                return
            end
            obj.p = 0; obj.d = 0; obj.q = 0; obj.period = 0;
            obj.pExplicit = false; obj.dExplicit = false; obj.qExplicit = false;
            if nargin >= 1, [obj.p, obj.pExplicit] = tse.x13.ArimaSpec.normcomp(varargin{1}); end
            if nargin >= 2, [obj.d, obj.dExplicit] = tse.x13.ArimaSpec.normcomp(varargin{2}); end
            if nargin >= 3, [obj.q, obj.qExplicit] = tse.x13.ArimaSpec.normcomp(varargin{3}); end
            if nargin >= 4, obj.period = double(varargin{4}); end
        end

        function s = x13str(obj)
            body = ['(' tse.x13.ArimaSpec.compstr(obj.p, obj.pExplicit) ' ' ...
                        tse.x13.ArimaSpec.compstr(obj.d, obj.dExplicit) ' ' ...
                        tse.x13.ArimaSpec.compstr(obj.q, obj.qExplicit) ')'];
            if obj.period ~= 0
                s = [body sprintf('%d', double(obj.period))];
            else
                s = body;
            end
        end
    end
    methods (Static)
        function [v, ex] = normcomp(x)
            if iscell(x)
                v = double([x{:}]); v = v(:).'; ex = true;
            elseif isnumeric(x) && ~isscalar(x)
                v = double(x(:).'); ex = true;
            else
                v = double(x); ex = false;
            end
        end
        function s = compstr(v, ex)
            if ex
                parts = arrayfun(@(z) sprintf('%d', z), v(:).', 'UniformOutput', false);
                s = ['[' strjoin(parts, ', ') ']'];
            else
                s = sprintf('%d', double(v));
            end
        end
    end
end

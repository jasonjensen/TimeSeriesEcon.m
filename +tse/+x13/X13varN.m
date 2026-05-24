classdef (Abstract) X13varN < tse.x13.X13var
%X13VARN  Abstract base for bracketed-count regression variables
%   (tdstock, tdstock1coef, easter, labor, thank, sceaster, easterstock).
    properties
        n
    end
    methods
        function obj = X13varN(n)
            if nargin > 0
                obj.n = n;
            end
        end
        function s = x13str(obj)
            s = sprintf('%s[%d]', obj.shortname(), double(obj.n));
        end
    end
end

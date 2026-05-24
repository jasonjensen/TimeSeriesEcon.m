classdef (Abstract) X13varMIT < tse.x13.X13var
%X13VARMIT  Abstract base for single-date regression variables (ao, ls, tc, so).
    properties
        mit
    end
    methods
        function obj = X13varMIT(mit)
            if nargin > 0
                obj.mit = mit;
            end
        end
        function s = x13str(obj)
            s = [obj.shortname() tse.x13.mitstr(obj.mit)];
        end
    end
end

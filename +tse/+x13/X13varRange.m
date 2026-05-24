classdef (Abstract) X13varRange < tse.x13.X13var
%X13VARRANGE  Abstract base for two-date regression variables
%   (aos, lss, rp, qd, qi, tl).  Construct with either an MIT range or a pair
%   of MITs.
    properties
        mit1
        mit2
    end
    methods
        function obj = X13varRange(a, b)
            if nargin == 1
                obj.mit1 = first(a);
                obj.mit2 = last(a);
            elseif nargin == 2
                obj.mit1 = a;
                obj.mit2 = b;
            end
        end
        function s = x13str(obj)
            s = [obj.shortname() tse.x13.mitstr(obj.mit1) '-' tse.x13.mitstr(obj.mit2)];
        end
    end
end

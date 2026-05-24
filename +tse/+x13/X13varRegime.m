classdef (Abstract) X13varRegime < tse.x13.X13var
%X13VARREGIME  Abstract base for regime-change regression variables
%   (td, tdnolpyear, td1coef, td1nolpyear, lpyear, lom, loq, seasonal).
%
%   Construction:
%     T()              regimechange = 'neither', mit = 1M1
%     T(mit)           regimechange = 'both'
%     T(mit, rc)       rc one of 'both', 'zerobefore', 'zeroafter'
    properties
        mit
        regimechange
    end
    methods
        function obj = X13varRegime(mit, rc)
            if nargin == 0
                obj.mit = tse.mm(1, 1);
                obj.regimechange = 'neither';
            elseif nargin == 1
                obj.mit = mit;
                obj.regimechange = 'both';
            else
                obj.mit = mit;
                obj.regimechange = char(rc);
            end
        end
        function s = x13str(obj)
            if strcmp(obj.regimechange, 'neither')
                s = obj.shortname();
            else
                [a, b] = tse.x13.X13var.regimechars(obj.regimechange);
                s = [obj.shortname() a tse.x13.mitstr(obj.mit) b];
            end
        end
    end
end

classdef (Abstract) X13var
%X13VAR  Abstract base for X13 regression / x11regression variable tokens.
%
%   Concrete leaf types (ao, ls, tc, so, aos, lss, rp, qd, qi, tl, tdstock,
%   tdstock1coef, easter, labor, thank, sceaster, easterstock, sincos, td,
%   tdnolpyear, td1coef, td1nolpyear, lpyear, lom, loq, seasonal) each know how
%   to render themselves into the token expected in a spec file via x13str.
%
%   See also: tse.x13.regression, tse.x13.x11regression.
    methods (Abstract)
        s = x13str(obj)
    end
    methods
        function n = shortname(obj)
            %SHORTNAME  Bare type name (no package prefix), e.g. 'ao'.
            n = regexprep(class(obj), '.*\.', '');
        end
    end
    methods (Static)
        function [s, e] = regimechars(rc)
            %REGIMECHARS  Start/end separators for a regime-change variable.
            switch char(rc)
                case 'both'
                    s = '/'; e = '/';
                case 'zerobefore'
                    s = '//'; e = '/';
                case 'zeroafter'
                    s = '/'; e = '//';
                otherwise
                    error('tseries:noMatch', ...
                        'regimechange must be both, zerobefore, zeroafter, or neither. Received: %s', char(rc));
            end
        end
    end
end

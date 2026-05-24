classdef FPConst
%FPCONST  A "fuzzy period" marker used by some X13 spec fields.
%
%   Represents a month, quarter or half-year position that is not tied to a
%   specific year, e.g. M12 (December), Q3 (third quarter).  Build one with the
%   helpers tse.x13.M(n), tse.x13.Q(n) or tse.x13.H(n).
%
%   Used by Span (e.g. tse.x13.Span([], tse.x13.M(12))  ->  "(, 0.dec)") and by
%   the force spec's start field (rendered bare, e.g. "oct").
%
%   See also: tse.x13.M, tse.x13.Q, tse.x13.H, tse.x13.Span.
    properties
        kind   % 'monthly' | 'quarterly' | 'halfyearly'
        n
    end
    methods
        function obj = FPConst(kind, n)
            obj.kind = kind;
            obj.n = double(n);
        end
        function s = bare(obj)
            %BARE  Period string: a month name for monthly, else the number.
            kind = char(obj.kind);
            if strcmp(kind, 'monthly')
                months = {'jan','feb','mar','apr','may','jun', ...
                          'jul','aug','sep','oct','nov','dec'};
                s = months{obj.n};
            else
                s = sprintf('%d', obj.n);
            end
        end
    end
end

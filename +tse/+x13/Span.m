classdef Span
%SPAN  A data span for X13 spec fields, with optionally open ends.
%
%   tse.x13.Span(mit1, mit2)   both ends given        -> "(a, b)"
%   tse.x13.Span(mit1:mit2)    from an MIT range       -> "(a, b)"
%   tse.x13.Span(mit1)         open end                -> "(a, )"
%   tse.x13.Span([], mit2)     open start              -> "(, b)"
%   tse.x13.Span([], M(12))    open start, fuzzy end   -> "(, 0.dec)"
%
%   An empty ([]) endpoint means "missing" (the start/end of the series).  A
%   fuzzy end (tse.x13.M/Q/H) is only allowed in some fields.
%
%   See also: tse.x13.M, tse.x13.Q, tse.x13.H.
    properties
        b
        e
    end
    methods
        function obj = Span(b, e)
            if nargin == 1
                if isa(b, 'tse.MITRange')
                    obj.b = first(b);
                    obj.e = last(b);
                else
                    obj.b = b;
                    obj.e = [];
                end
            else
                obj.b = b;
                obj.e = e;
            end
        end

        function tf = hasFuzzyEnd(obj)
            tf = isa(obj.e, 'tse.x13.FPConst');
        end

        function s = x13str(obj)
            bs = tse.x13.Span.partstr(obj.b);
            if isa(obj.e, 'tse.x13.FPConst')
                s = ['(' bs ', 0.' obj.e.bare() ')'];
            else
                s = ['(' bs ', ' tse.x13.Span.partstr(obj.e) ')'];
            end
        end
    end
    methods (Static)
        function s = partstr(x)
            if isa(x, 'tse.MIT')
                s = tse.x13.mitstr(x);
            else
                s = '';   % [] / missing
            end
        end
    end
end

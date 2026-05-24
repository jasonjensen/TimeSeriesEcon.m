classdef ao < tse.x13.X13varMIT
%AO  Additive (point) outlier regression variable at a date.  E.g. tse.x13.ao(2007Q1).
    methods
        function obj = ao(varargin)
            obj = obj@tse.x13.X13varMIT(varargin{:});
        end
    end
end

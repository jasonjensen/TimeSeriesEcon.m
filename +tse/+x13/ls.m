classdef ls < tse.x13.X13varMIT
%LS  Level-shift regression variable at a date.  E.g. tse.x13.ls(1971Q1).
    methods
        function obj = ls(varargin)
            obj = obj@tse.x13.X13varMIT(varargin{:});
        end
    end
end

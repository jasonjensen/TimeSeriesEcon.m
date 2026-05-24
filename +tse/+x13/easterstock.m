classdef easterstock < tse.x13.X13varN
%EASTERSTOCK  Stock Easter-holiday regression variable with window length n.
    methods
        function obj = easterstock(varargin)
            obj = obj@tse.x13.X13varN(varargin{:});
        end
    end
end

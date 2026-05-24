classdef labor < tse.x13.X13varN
%LABOR  Labor-day regression variable with window length n.  E.g. tse.x13.labor(10).
    methods
        function obj = labor(varargin)
            obj = obj@tse.x13.X13varN(varargin{:});
        end
    end
end

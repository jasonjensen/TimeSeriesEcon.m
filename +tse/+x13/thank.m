classdef thank < tse.x13.X13varN
%THANK  Thanksgiving regression variable with window length n.  E.g. tse.x13.thank(8).
    methods
        function obj = thank(varargin)
            obj = obj@tse.x13.X13varN(varargin{:});
        end
    end
end

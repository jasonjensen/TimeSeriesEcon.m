classdef sceaster < tse.x13.X13varN
%SCEASTER  Statistics-Canada Easter regression variable with window length n.
    methods
        function obj = sceaster(varargin)
            obj = obj@tse.x13.X13varN(varargin{:});
        end
    end
end

classdef easter < tse.x13.X13varN
%EASTER  Easter-holiday regression variable with window length n.  E.g. tse.x13.easter(8).
    methods
        function obj = easter(varargin)
            obj = obj@tse.x13.X13varN(varargin{:});
        end
    end
end

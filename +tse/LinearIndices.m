function L = LinearIndices(X)
%LINEARINDICES  Integer index vector 1:numel(X) for a TSeries / MVTSeries.
%
%   L = tse.LinearIndices(x) returns 1:numel(x), mirroring Julia's
%   LinearIndices for use in loops and broadcasting helpers.
    L = 1:numel(X);
end

function ax = Axis(varargin)
%AXIS  Alias for tse.Axis, kept so code written for tse.daec still works.
%
%   ax = tse.daec.Axis(...) is the same as tse.Axis(...) and returns a
%   tse.Axis.  The axis class moved to core TimeSeriesEcon.m so that
%   tse.NDTSeries does not depend on DataEcon.
%
%   See also tse.Axis.
    ax = tse.Axis(varargin{:});
end

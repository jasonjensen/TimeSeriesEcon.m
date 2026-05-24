function out = deseasonalize(ts, varargin)
%DESEASONALIZE  Seasonally adjust a TSeries with a default X11 run.
%
%   out = tse.x13.deseasonalize(ts)        returns the d11 final seasonally
%                                          adjusted series
%
%   Runs a default x11 spec (saving table d11) and returns a TSeries over the
%   same range holding the seasonally adjusted values.  Extra name-value pairs
%   are forwarded to the x11 spec.  Requires a configured x13as binary (see
%   tse.x13.run).
%
%   See also: tse.x13.run, tse.x13.x11.
    spec = tse.x13.newspec(ts, 'x11', tse.x13.x11('save', 'd11', varargin{:}));
    res = tse.x13.run(spec, 'verbose', false);
    d11 = res.series.d11;
    out = tse.TSeries(tse.firstdate(d11), d11.values);
end

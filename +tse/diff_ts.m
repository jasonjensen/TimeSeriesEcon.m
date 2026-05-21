function r = diff_ts(t, k)
%DIFF_TS  k-th difference of a TSeries.  Default k = -1, i.e. first
%difference: r(t) = t(t) - t(t-1).  Negative k corresponds to subtracting
%a lag; positive k corresponds to subtracting a lead.  Matches Julia's
%`diff(x, k)`.
    if nargin < 2, k = -1; end
    r = t - shift(t, -k);
end

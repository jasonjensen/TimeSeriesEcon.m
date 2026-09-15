function r = from_range(ax)
%FROM_RANGE  Convert a DataEcon range DEAxis into a tse.MITRange.
%
%   r = tse.daec.from_range(ax)
%
%   Uses the axis frequency, starting value, and length to rebuild the
%   contiguous MIT range.  Errors if the axis is not a range axis.
    if ~isa(ax, 'DEAxis')
        error('tseries:noMatch', 'from_range expects a DEAxis.');
    end
    if ax.ax_type ~= DAEC.enums.axis_type_t.axis_range
        error('tseries:noMatch', ...
            'from_range expects a range axis (ax_type == axis_range).');
    end
    start = tse.MIT(int32(ax.frequency), int64(ax.first));
    stop  = start + (double(ax.length) - 1);
    r     = start:stop;
end

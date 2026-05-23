function off = mit_offset(loc, F)
%MIT_OFFSET  x-axis offset of a point within its period, for plotting.
%
%   Mirrors TimeSeriesEcon.jl plotrecipes mit_offset:
%     :left   -> 0.0
%     :middle -> 0.5            (0.5/N for YP frequencies)
%     :right  -> 1.0            (1.0/N for YP frequencies)

    switch char(loc)
        case 'left'
            off = 0.0;
        case 'middle'
            if isa(F, 'tse.YPFrequency')
                off = 0.5 / double(F.PeriodsPerYear);
            else
                off = 0.5;
            end
        case 'right'
            if isa(F, 'tse.YPFrequency')
                off = 1.0 / double(F.PeriodsPerYear);
            else
                off = 1.0;
            end
        otherwise
            error('tseries:noMatch', ...
                'mit_loc must be ''left'', ''middle'', or ''right''. Received: %s', char(loc));
    end
end

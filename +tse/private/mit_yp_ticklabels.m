function mit_yp_ticklabels(ax, F, loc)
%MIT_YP_TICKLABELS  Relabel a numeric x-axis with YP-frequency MIT labels.
%
%   Mirrors plotrecipes mit_formatter: each numeric tick x is mapped back
%   to the MIT it represents; a trailing '+' marks ticks that do not align
%   with a period boundary (within one tenth of a period).

    N = double(F.PeriodsPerYear);
    off = mit_offset(loc, F);
    xt = ax.XTick;
    labs = cell(1, numel(xt));
    for i = 1:numel(xt)
        x = xt(i);
        yr = floor(x - off);
        per = 1 + floor(N * (x - yr - off));
        m = tse.MIT(F, int64(yr), int64(per));
        s = char(m);
        if N * abs(x - toFloat(m)) > 0.1
            s = [s '+']; %#ok<AGROW>
        end
        labs{i} = s;
    end
    ax.XTickLabel = labs;
end

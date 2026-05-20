function m = mm(y, p)
%MM Construct an MIT{Monthly} from year and period (1..12).
    m = tseries.MIT(tseries.Monthly(), y, p);
end

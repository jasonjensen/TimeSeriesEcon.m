function m = mm(y, p)
%MM Construct an MIT{Monthly} from year and period (1..12).
    m = tse.MIT(tse.Monthly(), y, p);
end

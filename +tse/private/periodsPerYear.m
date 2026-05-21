function N = periodsPerYear(F)

    if isnumeric(F)
        if F >= 256
            N = 1;
        elseif F >= 128
            N = 2;
        elseif F >= 64
            N = 4;
        elseif F >= 32
            N = 12;
        else
            N = 0;
        end        
    elseif isa(F, 'tse.Frequency')
        N = F.PeriodsPerYear;
    else
          error('tse:noMatch', 'Unknown frequency code: %d', double(F));
    end
end

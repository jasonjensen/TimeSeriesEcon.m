function d = x13tempdir()
%X13TEMPDIR  Create and return a fresh temp folder named with an "x13_" prefix.
%
%   The prefix lets tse.x13.cleanup find and remove leftover run folders.
    base = tempname;
    [pp, nm] = fileparts(base);
    d = fullfile(pp, ['x13_' nm]);
    mkdir(d);
end

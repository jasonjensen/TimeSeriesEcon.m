function startup(libname, headerpath)
%STARTUP  Load the FAME CHLI shared library and initialise it (cfmini).
%
%   tse.fame.startup()                 load the library named 'chli'
%   tse.fame.startup('mychli')         load a differently named library
%   tse.fame.startup('chli', hdr)      also override the prototype header path
%
%   The shared library (chli.dll / libchli.so) must be on the system library
%   path.  A failure to load is reported as a warning, so callers can probe
%   tse.fame.isavailable afterwards.
%
%   See also: tse.fame.isavailable, tse.fame.CHLI.
    try
        if nargin >= 2
            tse.fame.CHLI.load(libname, headerpath);
        elseif nargin >= 1
            tse.fame.CHLI.load(libname);
        else
            switch computer()
                case 'PCWIN'
                    tse.fame.CHLI.load('chli', 'chli.dll');
                case 'PCWIN64'
                    tse.fame.CHLI.load('chli', fullfile('64','chli.dll'));
                case 'GLNX86'
                    tse.fame.CHLI.load('libchli', 'libchli.so');
                case 'GLNXA64'
                    tse.fame.CHLI.load('libchli', fullfile('64','libchli.so'));
                otherwise
                    error('TSE.FAME:PlatformNotSupported', ...
                        'Your platform is not supported.');
            end
        end
    catch e
        warning('tseries:fame', 'Could not load the FAME CHLI: %s', e.message);
        return
    end
    if ~tse.fame.CHLI.isloaded()
        warning('tseries:fame', 'The FAME CHLI did not load.');
    end
end

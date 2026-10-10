function v = version()
%VERSION  Version of the libdaec that tse.daec uses.
%
%   v = tse.daec.version()   returns e.g. '0.4.0', loading the bundled
%                            library first if needed.
    v = daec_lib('call', 'de_version');
end

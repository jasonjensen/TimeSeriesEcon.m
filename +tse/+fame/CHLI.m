classdef CHLI < handle
%CHLI  Singleton loader / thin wrapper around the FAME CHLI (C library).
%
%   The FAME interop lives behind this one class so that all loadlibrary /
%   calllib usage -- the only unsafe part of the bridge -- is in a single
%   file.  Modelled on DataEcon's DAEC.m.
%
%   FAME CHLI convention: every cfm* function is void and reports success
%   through its FIRST argument, int *status (0 == HSUCC).  check_call passes
%   that status pointer, then returns any remaining by-reference outputs in
%   signature order (the same way MATLAB's calllib surfaces pointer args).
%
%   VALIDATE against your installed CHLI: the library name ('chli'), the
%   calllib by-reference return ordering, and cfmferr's message semantics.
%
%   Usage:
%       tse.fame.startup                 % load 'chli' + cfmini
%       tse.fame.startup('mychli')       % a differently named library
%
%   See also: tse.fame.isavailable, tse.fame.startup.

    properties
        libname     = 'libchli';
        libfile = 'libchli.so';
        headerpath  = '';
        initialized = false;
    end

    methods (Static, Access = private)
        function inst = instance()
            persistent instance_
            if isempty(instance_) || ~isvalid(instance_)
                instance_ = tse.fame.CHLI();
            end
            inst = instance_;
        end
    end

    methods (Access = private)
        function inst = CHLI()
            here = fileparts(mfilename('fullpath'));
            inst.headerpath = fullfile(here, 'private', 'chli.h');
        end
    end

    methods (Static)  % lifecycle

        function load(libname, libfile, headerpath)
            inst = tse.fame.CHLI.instance();
            if nargin >= 1 && ~isempty(libname)
                inst.libname = char(libname);
            end
             if nargin >= 2 && ~isempty(libfile)
                inst.libfile = char(libfile);
            end
            if nargin >= 3 && ~isempty(headerpath)
                inst.headerpath = char(headerpath);
            end
            if ~libisloaded(inst.libname)
                chlipath = fullfile(getenv('FAME'),'hli');
                chlih = 'hli.h';
                [~, ~] = loadlibrary(fullfile(chlipath,inst.libfile), ...
                             fullfile(chlipath, chlih));
            end
            if ~inst.initialized
                tse.fame.CHLI.init();
                inst.initialized = true;
            end
        end

        function unload()
            inst = tse.fame.CHLI.instance();
            if libisloaded(inst.libname)
                try
                    tse.fame.CHLI.fin();
                catch
                end
                unloadlibrary(inst.libname);
            end
            inst.initialized = false;
        end

        function tf = isloaded()
            tf = libisloaded(tse.fame.CHLI.instance().libname);
        end

        function n = libraryname()
            n = tse.fame.CHLI.instance().libname;
        end

        function ensure_loaded()
            if ~tse.fame.CHLI.isloaded()
                error('tseries:fame', ...
                    'The FAME CHLI is not loaded; call tse.fame.startup first.');
            end
        end
    end

    methods (Static)  % low-level cfm* wrappers (all calllib usage lives here)

        function init()
            tse.fame.CHLI.check_call('cfmini');
        end

        function fin()
            tse.fame.CHLI.check_call('cfmfin');
        end

        function idx = ddat(freq, year, month, day)
            % Calendar (year, month, day) -> FAME date index for `freq`.
            dp  = libpointer('int32Ptr', int32(0));
            idx = double(tse.fame.CHLI.check_call('cfmddat', ...
                int32(freq), dp, int32(year), int32(month), int32(day)));
        end

        function [year, month, day] = datd(freq, date)
            % FAME date index -> calendar (year, month, day) for `freq`.
            yp = libpointer('int32Ptr', int32(0));
            mp = libpointer('int32Ptr', int32(0));
            dp = libpointer('int32Ptr', int32(0));
            [year, month, day] = tse.fame.CHLI.check_call('cfmdatd', ...
                int32(freq), int32(date), yp, mp, dp);
            year = double(year); month = double(month); day = double(day);
        end

        % --- database lifecycle (confirmed signatures; used from step 3) ---

        function dbkey = opendb(dbname, mode)
            kp = libpointer('int32Ptr', int32(0));
            dbkey = double(tse.fame.CHLI.check_call('cfmopdb', ...
                kp, char(dbname), int32(mode)));
        end

        function dbkey = openwork()
            kp = libpointer('int32Ptr', int32(0));
            dbkey = double(tse.fame.CHLI.check_call('cfmopwk', kp));
        end

        function closedb(dbkey)
            tse.fame.CHLI.check_call('cfmcldb', int32(dbkey));
        end
    end

    methods (Static, Access = private)

        function varargout = check_call(func, varargin)
            inst = tse.fame.CHLI.instance();
            tse.fame.CHLI.ensure_loaded();
            sp = libpointer('int32Ptr', int32(0));
            % status is the first (output) argument; the remaining by-ref
            % outputs come back in signature order after it.
            [status, varargout{1:nargout}] = calllib(inst.libname, func, sp, varargin{:});
            tse.fame.CHLI.check(status);
        end

        function check(status)
            if status == 0
                return   % HSUCC
            end
            inst = tse.fame.CHLI.instance();
            msg = '';
            try
                buf = blanks(256);
                sp  = libpointer('int32Ptr', int32(0));
                [~, msg] = calllib(inst.libname, 'cfmferr', sp, buf);
                msg = strtrim(msg);
            catch
            end
            if isempty(msg)
                error('tseries:fame', 'FAME CHLI error (status %d).', double(status));
            else
                error('tseries:fame', 'FAME CHLI error (status %d): %s', double(status), msg);
            end
        end
    end
end

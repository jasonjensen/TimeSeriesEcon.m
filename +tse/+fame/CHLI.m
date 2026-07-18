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

        % --- database lifecycle ---

        function dbkey = opendb(dbname, mode)
            kp = libpointer('int32Ptr', int32(0));
            tse.fame.CHLI.raw_call('cfmopdb', kp, char(dbname), int32(mode));
            dbkey = double(kp.Value);
        end

        function dbkey = openwork()
            kp = libpointer('int32Ptr', int32(0));
            tse.fame.CHLI.raw_call('cfmopwk', kp);
            dbkey = double(kp.Value);
        end

        function postdb(dbkey)
            % Commit pending writes; must be called before closing a db that
            % was opened for create/overwrite/update.
            tse.fame.CHLI.raw_call('cfmpodb', int32(dbkey));
        end

        function closedb(dbkey)
            tse.fame.CHLI.raw_call('cfmcldb', int32(dbkey));
        end

        % --- objects, ranges, series data (all read outputs via .Value) ---

        function newobj(dbkey, name, objclass, freq, type, basis, observed)
            tse.fame.CHLI.raw_call('cfmnwob', int32(dbkey), char(name), ...
                int32(objclass), int32(freq), int32(type), int32(basis), int32(observed));
        end

        function info = whatis(dbkey, name)
            % Object attributes via cfmwhat.  Returns a struct with class,
            % type, freq, basis, observed, and the first/last (year, period).
            c  = libpointer('int32Ptr', int32(0));  t  = libpointer('int32Ptr', int32(0));
            f  = libpointer('int32Ptr', int32(0));  b  = libpointer('int32Ptr', int32(0));
            o  = libpointer('int32Ptr', int32(0));
            fy = libpointer('int32Ptr', int32(0));  fp = libpointer('int32Ptr', int32(0));
            ly = libpointer('int32Ptr', int32(0));  lp = libpointer('int32Ptr', int32(0));
            % six trailing int* (created / modified date parts) we do not use
            x1 = libpointer('int32Ptr', int32(0));  x2 = libpointer('int32Ptr', int32(0));
            x3 = libpointer('int32Ptr', int32(0));  x4 = libpointer('int32Ptr', int32(0));
            x5 = libpointer('int32Ptr', int32(0));  x6 = libpointer('int32Ptr', int32(0));
            desc = blanks(256);  doc = blanks(256);
            tse.fame.CHLI.raw_call('cfmwhat', int32(dbkey), char(name), ...
                c, t, f, b, o, fy, fp, ly, lp, x1, x2, x3, x4, x5, x6, desc, doc);
            info = struct('class', double(c.Value), 'type', double(t.Value), ...
                'freq', double(f.Value), 'basis', double(b.Value), ...
                'observed', double(o.Value), 'fyear', double(fy.Value), ...
                'fprd', double(fp.Value), 'lyear', double(ly.Value), 'lprd', double(lp.Value));
        end

        function [range, nobs] = makerange(freq, syear, sprd, eyear, eprd)
            % Build the FAME range array [freq, startIndex, endIndex] and the
            % observation count from a first/last (year, period).
            syp = libpointer('int32Ptr', int32(syear));  spp = libpointer('int32Ptr', int32(sprd));
            eyp = libpointer('int32Ptr', int32(eyear));  epp = libpointer('int32Ptr', int32(eprd));
            rng = libpointer('int32Ptr', int32([0 0 0])); nob = libpointer('int32Ptr', int32(0));
            tse.fame.CHLI.raw_call('cfmsrng', int32(freq), syp, spp, eyp, epp, rng, nob);
            range = int32(rng.Value);
            nobs  = double(nob.Value);
        end

        function data = readrange(dbkey, name, range, nobs, cls)
            % Read `nobs` observations of a series; missing values come back
            % as NaN (we pass a NaN misval array with translation enabled).
            K = fame_constants();
            switch cls
                case 'double'
                    dp = libpointer('doublePtr', zeros(nobs, 1));
                    mv = libpointer('doublePtr', [NaN; NaN; NaN]);
                case 'single'
                    dp = libpointer('singlePtr', zeros(nobs, 1, 'single'));
                    mv = libpointer('singlePtr', single([NaN; NaN; NaN]));
                otherwise
                    error('tseries:fame', 'readrange supports double/single (got %s).', cls);
            end
            tse.fame.CHLI.raw_call('cfmrrng_f', int32(dbkey), char(name), ...
                int32(range), dp, int32(K.HTMIS), mv);
            data = dp.Value;
        end

        function writerange(dbkey, name, range, data)
            % Write a series range; NaN in `data` is stored as FAME missing.
            K = fame_constants();
            if isa(data, 'single')
                dp = libpointer('singlePtr', single(data(:)));
                mv = libpointer('singlePtr', single([NaN; NaN; NaN]));
            else
                dp = libpointer('doublePtr', double(data(:)));
                mv = libpointer('doublePtr', [NaN; NaN; NaN]);
            end
            tse.fame.CHLI.raw_call('cfmwrng_f', int32(dbkey), char(name), ...
                int32(range), dp, int32(K.HTMIS), mv);
        end
    end

    methods (Static, Access = private)

        function raw_call(func, varargin)
            % Like check_call, but for functions with multiple / array output
            % pointers: the caller passes libpointers and reads their .Value
            % after the call.  status is captured from calllib's first return
            % (the status pointer) -- the mechanism validated in step 2.
            inst = tse.fame.CHLI.instance();
            tse.fame.CHLI.ensure_loaded();
            sp = libpointer('int32Ptr', int32(0));
            status = calllib(inst.libname, func, sp, varargin{:});
            tse.fame.CHLI.check(status);
        end

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

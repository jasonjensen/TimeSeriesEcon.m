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

        % --- object creation (classic cfmnwob, as FAME.jl does) ---

        function newobj(dbkey, name, objclass, freq, type, basis, observed)
            tse.fame.CHLI.raw_call('cfmnwob', int32(dbkey), char(name), ...
                int32(objclass), int32(freq), int32(type), int32(basis), int32(observed));
        end

        % --- metadata, date<->index, series data (modern fame_* API) ---
        % These return status as their return value and take a fame_range
        % struct {r_freq:int32, r_start:int64, r_end:int64} by pointer.

        function info = quick_info(dbkey, name)
            % fame_quick_info: class, type, freq, and first/last date index.
            oc = libpointer('int32Ptr', int32(0));  ty = libpointer('int32Ptr', int32(0));
            fr = libpointer('int32Ptr', int32(0));
            fi = libpointer('int64Ptr', int64(0));  li = libpointer('int64Ptr', int64(0));
            tse.fame.CHLI.fame_call('fame_quick_info', int32(dbkey), char(name), oc, ty, fr, fi, li);
            info = struct('class', double(oc.Value), 'type', double(ty.Value), ...
                'freq', double(fr.Value), 'first', double(fi.Value), 'last', double(li.Value));
        end

        function idx = yp_to_index(freq, year, period)
            dp = libpointer('int64Ptr', int64(0));
            tse.fame.CHLI.fame_call('fame_year_period_to_index', ...
                int32(freq), dp, int32(year), int32(period));
            idx = double(dp.Value);
        end

        function [year, period] = index_to_yp(freq, idx)
            yp = libpointer('int32Ptr', int32(0));  pp = libpointer('int32Ptr', int32(0));
            tse.fame.CHLI.fame_call('fame_index_to_year_period', ...
                int32(freq), int64(idx), yp, pp);
            year = double(yp.Value);  period = double(pp.Value);
        end

        function r = make_range(freq, first, last)
            % A libstruct matching the C fame_range type (loaded from hli.h).
            r = libstruct('fame_range');
            r.r_freq  = int32(freq);
            r.r_start = int64(first);
            r.r_end   = int64(last);
        end

        function data = get_precisions(dbkey, name, r, nobs)
            dp = libpointer('doublePtr', zeros(nobs, 1));
            tse.fame.CHLI.fame_call('fame_get_precisions', int32(dbkey), char(name), r, dp);
            data = tse.fame.CHLI.unmissing(dp.Value, 'double');
        end

        function data = get_numerics(dbkey, name, r, nobs)
            dp = libpointer('singlePtr', zeros(nobs, 1, 'single'));
            tse.fame.CHLI.fame_call('fame_get_numerics', int32(dbkey), char(name), r, dp);
            data = tse.fame.CHLI.unmissing(dp.Value, 'single');
        end

        function data = unmissing(data, cls)
            % Map FAME missing sentinels to NaN.  The sentinels are finite, so
            % an exact vectorized equality test is reliable (no per-value CHLI
            % call needed).
            K = fame_constants();
            if strcmp(cls, 'single')
                sentinels = K.numeric_missing;
            else
                sentinels = K.precision_missing;
            end
            for s = sentinels(:)'
                data(data == s) = NaN;
            end
        end

        function write_precisions(dbkey, name, r, data)
            K = fame_constants();
            d = double(data(:));
            d(isnan(d)) = K.FPRCNC;                 % NaN -> FAME NC
            dp = libpointer('doublePtr', d);
            tse.fame.CHLI.fame_call('fame_write_precisions', int32(dbkey), char(name), r, dp);
        end

        function write_numerics(dbkey, name, r, data)
            K = fame_constants();
            d = single(data(:));
            d(isnan(d)) = K.FNUMNC;                 % NaN -> FAME NC
            dp = libpointer('singlePtr', d);
            tse.fame.CHLI.fame_call('fame_write_numerics', int32(dbkey), char(name), r, dp);
        end

        function data = get_booleans(dbkey, name, r, nobs)
            dp = libpointer('int32Ptr', zeros(nobs, 1, 'int32'));
            tse.fame.CHLI.fame_call('fame_get_booleans', int32(dbkey), char(name), r, dp);
            % FAME booleans: 1 = true, 0 = false, missing = a distinct code.
            % tse logical has no missing state, so only exactly-1 is true.
            data = (dp.Value == 1);
        end

        function write_booleans(dbkey, name, r, data)
            dp = libpointer('int32Ptr', int32(logical(data(:))));
            tse.fame.CHLI.fame_call('fame_write_booleans', int32(dbkey), char(name), r, dp);
        end

        function data = get_strings(dbkey, name, r, nobs)
            % Two-step, as FAME.jl does: fame_len_strings for each length,
            % then fame_get_strings into per-string buffers (char**).
            lp = libpointer('int32Ptr', zeros(nobs, 1, 'int32'));
            tse.fame.CHLI.fame_call('fame_len_strings', int32(dbkey), char(name), r, lp);
            lens = double(lp.Value);
            bufs = cell(nobs, 1);
            for i = 1:nobs
                bufs{i} = blanks(lens(i) + 1);      % +1 for the null terminator
            end
            sp    = libpointer('stringPtrPtr', bufs);
            inlen = libpointer('int32Ptr', int32(lens));
            tse.fame.CHLI.fame_call('fame_get_strings', int32(dbkey), char(name), r, sp, inlen, []);
            out  = sp.Value;
            data = strings(nobs, 1);
            for i = 1:nobs
                s = char(out{i});
                z = find(s == char(0), 1);          % trim at the null terminator
                if ~isempty(z)
                    s = s(1:z-1);
                end
                data(i) = string(s);
            end
        end

        function write_strings(dbkey, name, r, data)
            c  = cellstr(string(data(:)));
            sp = libpointer('stringPtrPtr', c);
            tse.fame.CHLI.fame_call('fame_write_strings', int32(dbkey), char(name), r, sp);
        end

        % --- object enumeration (modern fame_*_wildcard) ---

        function objs = list_objects(dbkey)
            % Enumerate every object in the database.  Returns a struct array
            % with fields name, class, type, freq, first, last.  Pattern '?'
            % matches any name (as FAME.jl's listdb does).
            wildkey = tse.fame.CHLI.init_wildcard(dbkey, '?');
            cleanup = onCleanup(@() tse.fame.CHLI.free_wildcard(wildkey)); %#ok<NASGU>
            objs = struct('name', {}, 'class', {}, 'type', {}, ...
                          'freq', {}, 'first', {}, 'last', {});
            while true
                [status, name, oclass, type, freq, first, last] = ...
                    tse.fame.CHLI.next_wildcard(wildkey);
                if status == 13          % HNOOBJ: iteration exhausted
                    break
                elseif status ~= 0
                    tse.fame.CHLI.check(status);
                end
                objs(end+1) = struct('name', name, 'class', oclass, ...
                    'type', type, 'freq', freq, 'first', first, 'last', last); %#ok<AGROW>
            end
        end

        function wildkey = init_wildcard(dbkey, pattern)
            if nargin < 2 || isempty(pattern)
                pattern = '?';
            end
            wk = libpointer('int32Ptr', int32(0));
            % wildonly = 0, wildstart = '' (from the beginning)
            tse.fame.CHLI.fame_call('fame_init_wildcard', ...
                int32(dbkey), wk, char(pattern), int32(0), '');
            wildkey = double(wk.Value);
        end

        function [status, name, oclass, type, freq, first, last] = next_wildcard(wildkey)
            % Fetch the next matching object.  Returns status without raising,
            % so the caller can stop on HNOOBJ.  The name buffer is null-padded.
            inst = tse.fame.CHLI.instance();
            tse.fame.CHLI.ensure_loaded();
            oc = libpointer('int32Ptr', int32(0));  ty = libpointer('int32Ptr', int32(0));
            fr = libpointer('int32Ptr', int32(0));
            st = libpointer('int64Ptr', int64(0));  en = libpointer('int64Ptr', int64(0));
            ol = libpointer('int32Ptr', int32(0));
            buf = repmat(' ', 1, 256);
            [status, nameOut] = calllib(inst.libname, 'fame_get_next_wildcard', ...
                int32(wildkey), buf, oc, ty, fr, st, en, int32(numel(buf) - 1), ol);
            name = '';  oclass = 0;  type = 0;  freq = 0;  first = 0;  last = 0;
            if status == 0
                name = nameOut;
                z = find(name == char(0), 1);   % strip at the null terminator
                if ~isempty(z)
                    name = name(1:z-1);
                end
                name   = strtrim(name);
                oclass = double(oc.Value);  type = double(ty.Value);  freq = double(fr.Value);
                first  = double(st.Value);  last = double(en.Value);
            end
        end

        function free_wildcard(wildkey)
            tse.fame.CHLI.fame_call('fame_free_wildcard', int32(wildkey));
        end
    end

    methods (Static, Access = private)

        function raw_call(func, varargin)
            % Classic cfm* convention: status is the function's FIRST argument
            % (int*).  We prepend the status pointer, then the caller reads any
            % outputs from the libpointers it passed via .Value.
            inst = tse.fame.CHLI.instance();
            tse.fame.CHLI.ensure_loaded();
            sp = libpointer('int32Ptr', int32(0));
            status = calllib(inst.libname, func, sp, varargin{:});
            tse.fame.CHLI.check(status);
        end

        function fame_call(func, varargin)
            % Modern fame_* convention: status is the RETURN value (no status
            % pointer argument).  The caller reads outputs from its libpointers
            % (and libstruct) via .Value after the call.
            inst = tse.fame.CHLI.instance();
            tse.fame.CHLI.ensure_loaded();
            status = calllib(inst.libname, func, varargin{:});
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
            nm = tse.fame.CHLI.status_name(status);
            if isempty(msg)
                error('tseries:fame', 'FAME CHLI error %d (%s).', double(status), nm);
            else
                error('tseries:fame', 'FAME CHLI error %d (%s): %s', double(status), nm, msg);
            end
        end

        function nm = status_name(status)
            % Names for the FAME CHLI status codes we are most likely to hit.
            persistent m
            if isempty(m)
                m = containers.Map('KeyType', 'double', 'ValueType', 'char');
                pairs = { ...
                    0,'HSUCC'; 1,'HINITD'; 2,'HNINIT'; 3,'HFIN'; 4,'HBFILE'; ...
                    5,'HBMODE'; 6,'HBKEY'; 8,'HBSRNG'; 9,'HBERNG'; 10,'HBNRNG'; ...
                    13,'HNOOBJ'; 14,'HBRNG'; 15,'HDUTAR'; 16,'HBOBJT'; 17,'HBFREQ'; ...
                    18,'HTRUNC'; 20,'HNPOST'; 23,'HRNEXI'; 24,'HCEXI'; 25,'HNRESW'; ...
                    26,'HBCLAS'; 27,'HBOBSV'; 28,'HBBASI'; 30,'HBMONT'; 32,'HBMISS'; ...
                    33,'HBINDX'; 34,'HNWILD'; 46,'HBYEAR'; 47,'HBPER'; 48,'HBDAY'; ...
                    49,'HBDATE'; 70,'HBLEN'; 71,'HNULLP'; 72,'HREADO'; 513,'HFAMER'};
                for i = 1:size(pairs, 1)
                    m(pairs{i, 1}) = pairs{i, 2};
                end
            end
            if isKey(m, double(status))
                nm = m(double(status));
            else
                nm = 'unknown';
            end
        end
    end
end

function varargout = daec_lib(action, varargin)
%DAEC_LIB  Load and call the libdaec bundled with tse.daec.
%
%   daec_lib('load')                      load once (no-op when loaded)
%   tf = daec_lib('isloaded')
%   daec_lib('unload')
%   [out1, ...] = daec_lib('call', fname, args...)
%                                         calllib, outputs passed through
%   [out1, ...] = daec_lib('check_call', fname, args...)
%                                         calllib for a function returning a
%                                         status code; errors tseries:daec
%                                         with libdaec's message unless it
%                                         is DE_SUCCESS, and returns the
%                                         remaining outputs
%   old = daec_lib('debug', tf)           include the C source location in
%                                         error messages
%
%   The library is loaded under its own alias, so the DataEcon MATLAB
%   classes (alias 'libdaec') can stay on the path alongside.
%
%   The binaries and loadlibrary prototype files are built by
%   .github/workflows/libdaec.yml; see private/bin/README.md.  To use a
%   different build, set the TSE_LIBDAEC environment variable to the
%   library file; daec.h is then read from include/ next to its lib/ or
%   bin/ folder, which needs a C compiler that MATLAB supports.
    persistent debugMode
    if isempty(debugMode), debugMode = false; end
    alias = 'tse_libdaec';

    switch action
        case 'load'
            if ~libisloaded(alias)
                loadLibrary(alias);
            end
        case 'isloaded'
            varargout{1} = libisloaded(alias);
        case 'unload'
            if libisloaded(alias)
                unloadlibrary(alias);
            end
        case 'call'
            ensureLoaded(alias);
            varargout = cell(1, max(nargout, 1));
            [varargout{:}] = calllib(alias, varargin{:});
        case 'check_call'
            ensureLoaded(alias);
            out = cell(1, nargout + 1);
            [out{:}] = calllib(alias, varargin{:});
            checkStatus(alias, out{1}, debugMode);
            varargout = out(2:end);
        case 'debug'
            varargout{1} = debugMode;
            if ~isempty(varargin)
                debugMode = logical(varargin{1});
            end
        otherwise
            error('tseries:daec', 'Unknown daec_lib action ''%s''.', action);
    end
end

function ensureLoaded(alias)
    if ~libisloaded(alias)
        loadLibrary(alias);
    end
end

function loadLibrary(alias)
    custom = getenv('TSE_LIBDAEC');
    if ~isempty(custom)
        if exist(custom, 'file') ~= 2
            error('tseries:daec', 'TSE_LIBDAEC points to a missing file: %s', custom);
        end
        header = fullfile(fileparts(fileparts(custom)), 'include', 'daec.h');
        loadlibrary(custom, header, 'alias', alias);
    else
        arch = computer('arch');
        here = fileparts(mfilename('fullpath'));
        switch arch
            case 'glnxa64',          name = 'libdaec.so';
            case 'win64',            name = 'libdaec.dll';
            case {'maca64', 'maci64'}, name = 'libdaec.dylib';
            otherwise,               name = '';
        end
        libfile = fullfile(here, 'bin', arch, name);
        if isempty(name) || exist(libfile, 'file') ~= 2
            error('tseries:daec', ['No bundled libdaec for platform %s. ' ...
                'Set TSE_LIBDAEC to a libdaec build to use one.'], arch);
        end
        proto = ['daec_proto_' arch];
        if exist(fullfile(here, [proto '.m']), 'file') == 2
            loadlibrary(libfile, str2func(proto), 'alias', alias);
        else
            loadlibrary(libfile, fullfile(here, 'include', 'daec.h'), 'alias', alias);
        end
    end

    found = calllib(alias, 'de_version');
    expected = daec_enums().version;
    if ~versionCompatible(found, expected)
        unloadlibrary(alias);
        error('tseries:daec', ['libdaec version %s is not compatible with ' ...
            'the %s this toolbox was written for.'], found, expected);
    end
end

function ok = versionCompatible(found, expected)
% Julia's rule (TimeSeriesEcon.DataEcon.__init__): through 0.3.2 the
% versions must match exactly; for later 0.x the minor version must match
% and the patch must be the same or newer.
    f = sscanf(found, '%d.%d.%d')';
    e = sscanf(expected, '%d.%d.%d')';
    if numel(f) ~= 3 || numel(e) ~= 3
        ok = false;
    elseif e(1) == 0 && (e(2) < 3 || (e(2) == 3 && e(3) <= 2))
        ok = isequal(f, e);
    elseif e(1) == 0
        ok = f(1) == 0 && f(2) == e(2) && f(3) >= e(3);
    else
        ok = f(1) == e(1) && (f(2) > e(2) || (f(2) == e(2) && f(3) >= e(3)));
    end
end

function checkStatus(alias, status, debugMode)
    if status == 0
        return
    end
    buf = blanks(512);
    if debugMode
        [~, msg] = calllib(alias, 'de_error_source', buf, numel(buf) - 1);
    else
        [~, msg] = calllib(alias, 'de_error', buf, numel(buf) - 1);
    end
    msg = strtrim(strtok(msg, char(0)));
    if isempty(msg)
        msg = sprintf('libdaec error %d', status);
    end
    error('tseries:daec', '%s', msg);
end

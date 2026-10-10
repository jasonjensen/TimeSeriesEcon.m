classdef TestDaecFixtures < matlab.unittest.TestCase
    %TESTDAECFIXTURES  Read .daec files written by TimeSeriesEcon.jl.
    %
    %   tests/fixtures/daec holds the Julia-written fixtures of the Python
    %   port (see the README there).  Each <fixture>.json lists, per object,
    %   the raw storage that tools/daec_fixtures/expect.py read from the
    %   file's SQLite tables.  This test reads every object with tse.daec,
    %   lays the result out again the way libdaec stores it and compares:
    %
    %     ok        same object type, element type and frequency, axes and
    %               value bytes
    %     refused   tse.daec raised an error
    %     misread:  tse.daec returned something that lays out differently,
    %     <fields>  listing the fields that differ
    %
    %   known_gaps.tsv lists every object whose outcome is not ok.  The test
    %   fails when an outcome differs from that list, in either direction,
    %   and prints one line per difference starting with DAECFIX.
    %
    %   Julia markers other than Bool (jtype, jeltype) are ignored: tse
    %   reads the stored payload as is.

    properties (TestParameter)
        fixture = fixtureList()
    end

    methods (TestClassSetup)
        function needsBundledLibrary(tc)
            arch = computer('arch');
            root = fileparts(fileparts(mfilename('fullpath')));
            bin = fullfile(root, '+tse', '+daec', 'private', 'bin', arch);
            tc.assumeTrue(isfolder(bin) || ~isempty(getenv('TSE_LIBDAEC')), ...
                sprintf('No bundled libdaec for %s.', arch));
        end

        function quiet(tc)
            ws = warning('off', 'all');
            tc.addTeardown(@() warning(ws));
        end
    end

    methods (Test)
        function reads_as_stored(tc, fixture)
            folder = fixtureFolder();
            expected = jsondecode(fileread(fullfile(folder, [fixture '.json'])));
            objects = expected.objects;
            if isstruct(objects)
                objects = num2cell(objects);
            end
            known = knownGaps(fixture);
            de = tse.daec.opendaec(fullfile(folder, [fixture '.daec']));
            cleanup = onCleanup(@() de.close()); %#ok<NASGU>

            diffs = strings(0, 1);
            for k = 1:numel(objects)
                o = objects{k};
                [outcome, detail] = check(de, o);
                want = "ok";
                if isKey(known, o.path)
                    want = string(known(o.path));
                end
                if outcome ~= want
                    diffs(end+1, 1) = sprintf('%s\t%s\t%s\t(listed: %s) %s', ...
                        fixture, o.path, outcome, want, detail); %#ok<AGROW>
                end
            end
            listed = string(keys(known));
            paths = string(cellfun(@(o) o.path, objects, 'UniformOutput', false));
            missing = setdiff(listed, paths);
            for k = 1:numel(missing)
                diffs(end+1, 1) = sprintf('%s\t%s\tno such object\t(listed: %s)', ...
                    fixture, missing(k), known(char(missing(k)))); %#ok<AGROW>
            end
            for k = 1:numel(diffs)
                fprintf('DAECFIX %s\n', diffs(k));
            end
            tc.verifyEmpty(diffs, sprintf(['%d objects in %s read differently ' ...
                'from known_gaps.tsv (see the DAECFIX lines).'], numel(diffs), fixture));
        end
    end
end

% ---------- local functions ----------

function names = fixtureList()
    files = dir(fullfile(fixtureFolder(), '*.json'));
    names = cellfun(@(f) f(1:end-5), {files.name}, 'UniformOutput', false);
    if isempty(names)
        names = {'none'};
    end
end

function f = fixtureFolder()
    f = fullfile(fileparts(mfilename('fullpath')), 'fixtures', 'daec');
end

function known = knownGaps(fixture)
% path -> outcome for one fixture, from known_gaps.tsv (UTF-8, tab-separated
% fixture, path, outcome; # starts a comment line).
    known = containers.Map('KeyType', 'char', 'ValueType', 'char');
    fid = fopen(fullfile(fixtureFolder(), 'known_gaps.tsv'), 'r', 'n', 'UTF-8');
    if fid < 0
        return
    end
    text = fread(fid, '*char')';
    fclose(fid);
    lines = splitlines(string(text));
    for k = 1:numel(lines)
        if lines(k) == "" || startsWith(lines(k), "#")
            continue
        end
        parts = split(lines(k), sprintf('\t'));
        if parts(1) == fixture
            known(char(parts(2))) = char(parts(3));
        end
    end
end

function [outcome, detail] = check(de, o)
    detail = '';
    try
        v = de.read_data(o.path);
    catch err
        outcome = "refused";
        detail = err.message;
        return
    end
    try
        a = layout(v, o);
    catch err
        outcome = "misread:class";
        detail = sprintf('%s: %s', class(v), err.message);
        return
    end
    bad = strings(1, 0);
    if o.class == 1
        if a.eltype ~= o.type, bad(end+1) = "type"; end
        if a.elfreq ~= o.freq, bad(end+1) = "freq"; end
    else
        if ~isempty(a.type) && a.type ~= o.type, bad(end+1) = "type"; end
        if a.eltype ~= o.eltype, bad(end+1) = "eltype"; end
        if ~isequaln(a.elfreq, o.elfreq), bad(end+1) = "elfreq"; end
        if ~sameAxes(a.axes, o.axes), bad(end+1) = "axes"; end
    end
    if a.hex ~= string(o.hex), bad(end+1) = "bytes"; end
    if isempty(bad)
        outcome = "ok";
    else
        outcome = "misread:" + join(bad, ",");
        detail = class(v);
    end
end

function a = layout(v, o)
% Lay out a value read by tse.daec the way libdaec stores it.
    a = struct('type', [], 'eltype', 0, 'elfreq', 0, 'axes', [], 'hex', "");
    if o.class == 1
        [a.eltype, a.elfreq, a.hex] = elements(v, storedWidth(o));
        return
    end
    values = [];
    if isa(v, 'tse.TSeries')
        a.type = 12;
        values = v.values;
        a.axes = rangeAxis(v.firstdate, size(values, 1));
    elseif isa(v, 'tse.MVTSeries')
        a.type = 21;
        values = v.values;
        a.axes = [rangeAxis(v.firstdate, size(values, 1)), namesAxis(v.colnames)];
    elseif isa(v, 'tse.MITRange')
        a.type = 11;
        a.axes = rangeAxis(v.startMIT, length(v));
    elseif o.type == 11 && isnumeric(v) && isrow(v)
        a.type = 11;
        a.axes = plainAxes(numel(v));
    elseif isa(v, 'tse.daec.Array')
        values = v.values;
        a.axes = arrayfun(@toAxis, v.axes, 'UniformOutput', false);
        a.axes = [a.axes{:}];
    else
        values = v;
        dims = size(v);
        n = numel(o.axes);
        if n == 1
            dims = numel(v);
        elseif numel(dims) < n
            dims(end+1:n) = 1;
        end
        a.type = 10 * min(numel(dims), 3);
        a.axes = plainAxes(dims);
    end
    if a.type == 11
        a.eltype = 0;
        a.hex = "";
    else
        [a.eltype, a.elfreq, a.hex] = elements(values, storedWidth(o));
    end
end

function ax = rangeAxis(first, n)
    ax = struct('type', 1, 'length', double(n), 'freq', double(first.frequency), ...
        'first', string(int64(first.value)), 'names', strings(1, 0));
end

function ax = namesAxis(names)
    names = reshape(string(names), 1, []);
    ax = struct('type', 2, 'length', numel(names), 'freq', 0, 'first', "", ...
        'names', names);
end

function ax = plainAxes(dims)
    ax = arrayfun(@(n) struct('type', 0, 'length', n, 'freq', 0, 'first', "", ...
        'names', strings(1, 0)), dims, 'UniformOutput', false);
    ax = [ax{:}];
end

function ax = toAxis(x)
    switch x.kind
        case "range"
            ax = rangeAxis(x.firstdate(), x.length);
        case "names"
            ax = namesAxis(x.names);
        otherwise
            ax = plainAxes(x.length);
    end
end

function tf = sameAxes(got, want)
    tf = numel(got) == numel(want);
    for k = 1:numel(want)
        if ~tf
            return
        end
        g = got(k);
        w = want(k);
        if iscell(want)
            w = want{k};
        end
        tf = g.type == w.type && g.length == w.length;
        if tf && w.type == 1
            tf = g.freq == w.freq && g.first == string(w.first);
        elseif tf && w.type == 2
            tf = isequal(g.names, reshape(string(w.names), 1, []));
        end
    end
end

function w = storedWidth(o)
% Bytes per stored element (0 when there are none).
    n = 1;
    if o.class ~= 1
        n = prod(arrayfun(@(a) a.length, toStruct(o.axes)));
    end
    w = 0;
    if n > 0
        w = numel(o.hex) / 2 / n;
    end
end

function s = toStruct(axes)
    s = axes;
    if iscell(axes)
        s = [axes{:}];
    end
end

function [eltype, elfreq, hex] = elements(v, width)
% Element type, element frequency and bytes of values, column-major.
% Single values stored as 2-byte floats (Julia's Float16) are laid out as
% half precision again.
    elfreq = 0;
    if isa(v, 'tse.MIT') || isa(v, 'tse.Duration')
        eltype = 1;
        if isa(v, 'tse.MIT')
            eltype = 3;
        end
        if isempty(v)
            elfreq = NaN;   % an empty date array keeps no frequency
            bytes = uint8.empty(0, 1);
        else
            elfreq = double(v(1).frequency);
            if any(double([v.frequency]) ~= elfreq)
                elfreq = NaN;
            end
            bytes = typecast(int64(reshape([v.value], [], 1)), 'uint8');
        end
    elseif isstring(v) || ischar(v) || iscellstr(v)
        eltype = 6;
        if ischar(v)
            v = string(v);
        end
        v = string(v);
        parts = arrayfun(@(s) [unicode2native(char(s), 'UTF-8'), uint8(0)], ...
            reshape(v, 1, []), 'UniformOutput', false);
        bytes = [uint8.empty(1, 0), parts{:}];
    elseif islogical(v)
        eltype = 1;
        bytes = typecast(int8(v(:)), 'uint8');
    elseif isinteger(v)
        eltype = 1;
        if startsWith(class(v), 'u')
            eltype = 2;
        end
        bytes = typecast(v(:), 'uint8');
    elseif isa(v, 'single') && isreal(v) && width == 2
        eltype = 4;
        bytes = typecast(singleToHalf(v(:)), 'uint8');
    elseif isfloat(v) && isreal(v)
        eltype = 4;
        bytes = typecast(v(:), 'uint8');
    elseif isfloat(v)
        eltype = 5;
        pairs = [reshape(real(v), 1, []); reshape(imag(v), 1, [])];
        bytes = typecast(pairs(:), 'uint8');
    else
        error('tseries:daec', 'No layout for class %s.', class(v));
    end
    hex = string(lower(reshape(dec2hex(bytes(:), 2)', 1, [])));
end

function h = singleToHalf(s)
% Half-precision bit patterns of single values that came from halves.
    b = typecast(s, 'uint32');
    sign = uint16(bitand(bitshift(b, -16), uint32(32768)));
    e = double(bitand(bitshift(b, -23), uint32(255)));
    m = bitand(b, uint32(8388607));
    h = zeros(size(b), 'uint16');
    for k = 1:numel(b)
        if e(k) == 255                      % Inf, NaN
            h(k) = uint16(31 * 1024) + uint16(bitshift(m(k), -13));
        elseif e(k) == 0                    % zero
            h(k) = 0;
        elseif e(k) - 127 < -14             % half subnormal
            h(k) = uint16(abs(double(s(k))) * 2^24);
        else
            h(k) = uint16((e(k) - 112) * 1024) + uint16(bitshift(m(k), -13));
        end
        h(k) = bitor(h(k), sign(k));
    end
end

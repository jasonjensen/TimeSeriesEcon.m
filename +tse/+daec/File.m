classdef File < handle
    %FILE  An open .daec file.  Create one with tse.daec.opendaec.
    %
    %   de = tse.daec.opendaec('data.daec', 'write', true);
    %   de.store_tseries('gdp', tse.TSeries(tse.qq(2020, 1), rand(8, 1)));
    %   x = de.load_tseries('gdp');
    %   de.close();
    %
    %   Objects are named by a full path ('/models/gdp' or 'models/gdp'),
    %   by a parent catalog and a name (de.store_scalar('/models', 'n', 3)),
    %   or by the numeric id that store_* and find_* return.  The root
    %   catalog is id 0 (tse.daec.File.root_id).
    %
    %   Files
    %     close, isopen, truncate, isempty
    %   Objects and catalogs
    %     find_object, find_fullpath, get_fullpath, delete_object,
    %     new_catalog, catalog_size, list_catalog
    %   Attributes
    %     get_attribute, set_attribute, get_all_attributes
    %   Values
    %     store_scalar / load_scalar         numbers, strings, MIT, Duration
    %     store_tseries / load_tseries       vectors, TSeries, MITRange
    %     store_mvtseries / load_mvtseries   matrices, MVTSeries
    %     store_ndtseries / load_ndtseries   arrays of up to 5 dimensions
    %     write_data / read_data             any of the above, chosen by value
    %     writedb / readdb                   a struct, one catalog per field
    %                                        that is a struct
    %
    %   tse.daec.Array values keep their axes in any order and are written
    %   with the store function that matches their number of axes.
    %
    %   The names and behaviour follow TimeSeriesEcon.jl's DataEcon module.
    %   See also tse.daec.opendaec, tse.daec.readdb, tse.daec.writedb.

    properties (SetAccess = private)
        fname = ''
        readonly = true
        overwrite = false
    end

    properties (Constant)
        root_id = int64(0)
    end

    properties (Access = private)
        ptr = []
        open_ = false
    end

    methods
        function de = File(fname, readonly, overwrite)
            % Use tse.daec.opendaec or tse.daec.opendaecmem instead.
            daec_lib('load');
            fname = char(fname);
            ptr = libpointer('voidPtrPtr', 0);
            if strcmp(fname, ':memory:')
                daec_lib('check_call', 'de_open_memory', ptr);
                readonly = false;
            elseif readonly
                daec_lib('check_call', 'de_open_readonly', fname, ptr);
            else
                daec_lib('check_call', 'de_open', fname, ptr);
            end
            de.ptr = ptr;
            de.open_ = true;
            de.fname = fname;
            de.readonly = logical(readonly);
            de.overwrite = logical(overwrite);
        end

        function delete(de)
            if de.open_
                try
                    close(de);
                catch
                end
            end
        end

        function disp(de)
            if de.open_
                state = '';
                if de.readonly, state = ' (read-only)'; end
                if de.overwrite, state = [state ' (overwrite)']; end
            else
                state = ' (closed)';
            end
            fprintf('  tse.daec.File: "%s"%s\n', de.fname, state);
        end

        % ---------- files ----------

        function close(de)
            %CLOSE  Close the file.  Closing twice is harmless.
            if de.open_
                de.open_ = false;
                daec_lib('check_call', 'de_close', de.ptr);
            end
        end

        function tf = isopen(de)
            tf = de.open_;
        end

        function de = truncate(de)
            %TRUNCATE  Delete everything in the file.
            needWritable(de);
            daec_lib('check_call', 'de_truncate', de.ptr);
        end

        function tf = isempty(de)
            tf = catalog_size(de, de.root_id) == 0;
        end

        % ---------- objects ----------

        function id = find_object(de, parent, name, dne_error)
            %FIND_OBJECT  Id of the named object in a catalog.
            %
            %   id = de.find_object(parent, name)
            %   id = de.find_object(parent, name, false)   [] if missing
            if nargin < 4
                dne_error = true;
            end
            pid = resolve(de, parent);
            idp = libpointer('int64Ptr', 0);
            status = daec_lib('call', 'de_find_object', cptr(de), pid, char(name), idp);
            id = foundId(status, idp, dne_error);
        end

        function id = find_fullpath(de, fullpath, dne_error)
            %FIND_FULLPATH  Id of the object at a full path.
            %
            %   id = de.find_fullpath('/models/gdp')
            %   id = de.find_fullpath('/models/gdp', false)   [] if missing
            if nargin < 3
                dne_error = true;
            end
            fullpath = char(fullpath);
            if ~startsWith(fullpath, '/')
                fullpath = ['/' fullpath];
            end
            idp = libpointer('int64Ptr', 0);
            status = daec_lib('call', 'de_find_fullpath', cptr(de), fullpath, idp);
            id = foundId(status, idp, dne_error);
        end

        function p = get_fullpath(de, ref)
            %GET_FULLPATH  Full path of an object.
            id = resolve(de, ref);
            fp = libpointer('stringPtrPtr', {''});
            depth = libpointer('int64Ptr', 0);
            pid = libpointer('int64Ptr', 0);
            daec_lib('check_call', 'de_get_object_info', cptr(de), id, fp, depth, pid);
            p = fp.Value{1};
        end

        function delete_object(de, ref)
            %DELETE_OBJECT  Delete an object, with its attributes and, for
            %   a catalog, everything in it.
            needWritable(de);
            daec_lib('check_call', 'de_delete_object', cptr(de), resolve(de, ref));
        end

        % ---------- catalogs ----------

        function id = new_catalog(de, varargin)
            %NEW_CATALOG  Create a catalog.
            %
            %   id = de.new_catalog(fullpath)
            %   id = de.new_catalog(parent, name)
            [pid, name] = parentAndName(de, varargin{:});
            prepareStore(de, pid, name);
            idp = libpointer('int64Ptr', 0);
            daec_lib('check_call', 'de_new_catalog', cptr(de), pid, name, idp);
            id = idp.Value;
        end

        function n = catalog_size(de, ref)
            %CATALOG_SIZE  Number of objects directly in a catalog.
            if nargin < 2
                ref = de.root_id;
            end
            np = libpointer('int64Ptr', 0);
            daec_lib('check_call', 'de_catalog_size', cptr(de), resolve(de, ref), np);
            n = double(np.Value);
        end

        function list = list_catalog(de, varargin)
            %LIST_CATALOG  Full paths of the objects in a catalog.
            %
            %   list = de.list_catalog()                 root, recursively
            %   list = de.list_catalog(catalog, ...)
            %   Options: 'recursive' (true), 'quiet' (false: print a tree)
            ref = de.root_id;
            if mod(numel(varargin), 2) == 1
                ref = varargin{1};
                varargin(1) = [];
            end
            opts = nameValues(varargin, struct('recursive', true, 'quiet', false));
            cid = resolve(de, ref);
            prefix = '';
            if cid ~= de.root_id
                prefix = get_fullpath(de, cid);
            end
            list = listCatalog(de, cid, prefix, 0, opts);
        end

        % ---------- attributes ----------

        function value = get_attribute(de, varargin)
            %GET_ATTRIBUTE  Value of an attribute, or missing.
            %
            %   v = de.get_attribute(ref, attr)
            %   v = de.get_attribute(parent, name, attr)
            [id, attr] = objectAndRest(de, 1, varargin{:});
            vp = libpointer('stringPtrPtr', {''});
            status = daec_lib('call', 'de_get_attribute', cptr(de), id, char(attr{1}), vp);
            if status == daecStatus('DE_MIS_ATTR')
                daec_lib('call', 'de_clear_error');
                value = missing;
                return
            end
            daec_lib('check', status);
            value = vp.Value{1};
        end

        function set_attribute(de, varargin)
            %SET_ATTRIBUTE  Set an attribute, replacing any old value.
            %
            %   de.set_attribute(ref, attr, value)
            %   de.set_attribute(parent, name, attr, value)
            needWritable(de);
            [id, rest] = objectAndRest(de, 2, varargin{:});
            daec_lib('check_call', 'de_set_attribute', cptr(de), id, ...
                char(rest{1}), char(rest{2}));
        end

        function attrs = get_all_attributes(de, varargin)
            %GET_ALL_ATTRIBUTES  All attributes of an object, as a
            %   containers.Map from name to value.
            %
            %   attrs = de.get_all_attributes(ref)
            %   attrs = de.get_all_attributes(parent, name)
            %   libdaec joins all names and all values with a delimiter;
            %   option 'delim' (default char(31), the ASCII unit separator)
            %   must not occur in any name or value.
            delim = char(31);
            k = find(cellfun(@(a) (ischar(a) || isstring(a)) && strcmp(a, 'delim'), varargin), 1);
            if ~isempty(k)
                delim = char(varargin{k + 1});
                varargin(k:k+1) = [];
            end
            [id, ~] = objectAndRest(de, 0, varargin{:});
            np = libpointer('int64Ptr', 0);
            names = libpointer('stringPtrPtr', {''});
            values = libpointer('stringPtrPtr', {''});
            daec_lib('check_call', 'de_get_all_attributes', cptr(de), id, delim, ...
                np, names, values);
            attrs = containers.Map('KeyType', 'char', 'ValueType', 'char');
            if np.Value == 0
                return
            end
            n = split(string(names.Value{1}), delim);
            v = split(string(values.Value{1}), delim);
            if numel(n) ~= np.Value || numel(v) ~= np.Value
                error('tseries:daec', ...
                    'Number of attribute names and values do not match. Try another delim.');
            end
            for i = 1:numel(n)
                attrs(char(n(i))) = char(v(i));
            end
        end

        % ---------- scalars ----------

        function id = store_scalar(de, varargin)
            %STORE_SCALAR  Store a number, string, logical, tse.MIT or
            %   tse.Duration.
            %
            %   id = de.store_scalar(fullpath, value)
            %   id = de.store_scalar(parent, name, value)
            [pid, name, value] = parentNameValue(de, varargin{:});
            id = storeScalar(de, pid, name, value);
        end

        function value = load_scalar(de, varargin)
            %LOAD_SCALAR  Load a scalar.  ref is an id, a full path, or a
            %   parent and a name.
            id = objectId(de, varargin{:});
            s = libstruct('scalar_t', struct('frequency', int32(0)));
            s.object = objectStruct();
            [~, out] = daec_lib('check_call', 'de_load_scalar', cptr(de), id, ...
                libpointer('scalar_t', s));
            objType = daec_code('type_t', out.object.obj_type);
            value = daec_unpack(out.value, objType, out.frequency, out.nbytes, 1);
            e = daec_enums();
            if objType == e.type_t.type_string
                value = char(value);
            end
            if isequal(get_attribute(de, id, 'jtype'), 'Bool')
                value = logical(value);
            end
        end

        % ---------- arrays ----------

        function id = store_tseries(de, varargin)
            %STORE_TSERIES  Store a 1-d value: a vector, tse.TSeries,
            %   tse.MITRange, or 1-axis tse.daec.Array.
            %
            %   id = de.store_tseries(fullpath, value)
            %   id = de.store_tseries(parent, name, value)
            [pid, name, value] = parentNameValue(de, varargin{:});
            id = storeArray(de, pid, name, value, 1);
        end

        function id = store_mvtseries(de, varargin)
            %STORE_MVTSERIES  Store a 2-d value: a matrix, tse.MVTSeries,
            %   or 2-axis tse.daec.Array.
            [pid, name, value] = parentNameValue(de, varargin{:});
            id = storeArray(de, pid, name, value, 2);
        end

        function id = store_ndtseries(de, varargin)
            %STORE_NDTSERIES  Store an array of up to 5 dimensions, or a
            %   tse.daec.Array.  1-d and 2-d values go to store_tseries and
            %   store_mvtseries.
            [pid, name, value] = parentNameValue(de, varargin{:});
            id = storeArray(de, pid, name, value, []);
        end

        function value = load_tseries(de, varargin)
            %LOAD_TSERIES  Load a 1-d object.
            id = objectId(de, varargin{:});
            s = libstruct('tseries_t', struct('eltype', int32(0), 'elfreq', int32(0)));
            s.object = objectStruct();
            s.axis = axisStruct();
            [~, out] = daec_lib('check_call', 'de_load_tseries', cptr(de), id, ...
                libpointer('tseries_t', s));
            value = finishLoad(de, id, out, {out.axis});
        end

        function value = load_mvtseries(de, varargin)
            %LOAD_MVTSERIES  Load a 2-d object.
            id = objectId(de, varargin{:});
            s = libstruct('mvtseries_t', struct('eltype', int32(0), 'elfreq', int32(0)));
            s.object = objectStruct();
            s.axis1 = axisStruct();
            s.axis2 = axisStruct();
            [~, out] = daec_lib('check_call', 'de_load_mvtseries', cptr(de), id, ...
                libpointer('mvtseries_t', s));
            value = finishLoad(de, id, out, {out.axis1, out.axis2});
        end

        function value = load_ndtseries(de, varargin)
            %LOAD_NDTSERIES  Load an N-d object.
            id = objectId(de, varargin{:});
            s = libstruct('ndtseries_t', struct('eltype', int32(0), 'elfreq', int32(0)));
            s.object = objectStruct();
            for k = 1:5
                s.(sprintf('axis%d', k)) = axisStruct();
            end
            [~, out] = daec_lib('check_call', 'de_load_ndtseries', cptr(de), id, ...
                libpointer('ndtseries_t', s));
            raw = arrayfun(@(k) out.(sprintf('axis%d', k)), 1:double(out.naxes), ...
                'UniformOutput', false);
            value = finishLoad(de, id, out, raw);
        end

        % ---------- any value ----------

        function id = write_data(de, varargin)
            %WRITE_DATA  Store a value with the store function its type
            %   calls for.  A struct becomes a catalog, written recursively.
            %
            %   id = de.write_data(fullpath, value)
            %   id = de.write_data(parent, name, value)
            [pid, name, value] = parentNameValue(de, varargin{:});
            id = writeValue(de, pid, name, value);
        end

        function value = read_data(de, varargin)
            %READ_DATA  Load any object; a catalog loads as a struct.
            id = objectId(de, varargin{:});
            value = readValue(de, id);
        end

        function writedb(de, varargin)
            %WRITEDB  Write each field of a struct; struct fields become
            %   catalogs.  Values that cannot be written are skipped with a
            %   warning.
            %
            %   de.writedb(data)
            %   de.writedb(parent, data)
            if numel(varargin) == 1
                pid = de.root_id;
                data = varargin{1};
            elseif numel(varargin) == 2
                pid = resolve(de, varargin{1});
                data = varargin{2};
            else
                error('tseries:noMatch', 'Use de.writedb(data) or de.writedb(parent, data).');
            end
            if ~isstruct(data) || ~isscalar(data)
                error('tseries:noMatch', 'writedb needs a scalar struct (got %s).', class(data));
            end
            writeStruct(de, pid, data);
        end

        function data = readdb(de, ref)
            %READDB  Read a catalog (the root by default) into a struct.
            if nargin < 2
                ref = de.root_id;
            end
            data = readValue(de, resolve(de, ref));
        end
    end

    methods (Access = private)
        function h = cptr(de)
            if ~de.open_
                error('tseries:daec', 'The file is closed.');
            end
            h = de.ptr;
        end

        function needWritable(de)
            cptr(de);
            if de.readonly
                error('tseries:daec', 'The file is open read-only.');
            end
        end

        function id = resolve(de, ref)
            % Object id from an id or a full path.
            if isnumeric(ref) && isscalar(ref)
                id = int64(ref);
            elseif ischar(ref) || (isstring(ref) && isscalar(ref))
                id = find_fullpath(de, ref);
            else
                error('tseries:noMatch', 'An object is named by its id or full path.');
            end
        end

        function id = objectId(de, varargin)
            % id, full path, or parent and name
            switch numel(varargin)
                case 1
                    id = resolve(de, varargin{1});
                case 2
                    id = find_object(de, varargin{1}, varargin{2});
                otherwise
                    error('tseries:noMatch', ...
                        'Name the object by id, full path, or parent and name.');
            end
        end

        function [id, rest] = objectAndRest(de, nrest, varargin)
            % (ref, rest...) or (parent, name, rest...)
            nref = numel(varargin) - nrest;
            if nref < 1 || nref > 2
                error('tseries:noMatch', 'Wrong number of arguments.');
            end
            id = objectId(de, varargin{1:nref});
            rest = varargin(nref+1:end);
        end

        function [pid, name] = parentAndName(de, varargin)
            if numel(varargin) == 1
                p = char(varargin{1});
                if ~startsWith(p, '/')
                    p = ['/' p];
                end
                k = find(p == '/', 1, 'last');
                name = p(k+1:end);
                if k == 1
                    pid = de.root_id;
                else
                    pid = find_fullpath(de, p(1:k-1));
                end
            elseif numel(varargin) == 2
                pid = resolve(de, varargin{1});
                name = char(varargin{2});
            else
                error('tseries:noMatch', 'Name the object by full path, or parent and name.');
            end
            if isempty(name)
                error('tseries:noMatch', 'The object name is empty.');
            end
        end

        function [pid, name, value] = parentNameValue(de, varargin)
            if numel(varargin) < 2 || numel(varargin) > 3
                error('tseries:noMatch', 'Use (fullpath, value) or (parent, name, value).');
            end
            [pid, name] = parentAndName(de, varargin{1:end-1});
            value = varargin{end};
        end

        function prepareStore(de, pid, name)
            needWritable(de);
            if de.overwrite
                id = find_object(de, pid, name, false);
                if ~isempty(id)
                    delete_object(de, id);
                end
            end
        end

        function id = storeScalar(de, pid, name, value)
            if ischar(value) && (isrow(value) || isempty(value))
                value = string(value);
            end
            if ~isscalar(value) || ~(isnumeric(value) || islogical(value) ...
                    || isstring(value) || isa(value, 'tse.MIT') || isa(value, 'tse.Duration'))
                error('tseries:daec', 'Cannot store a %s as a scalar.', class(value));
            end
            p = daec_pack(value);
            prepareStore(de, pid, name);
            objType = p.eltype;
            idp = libpointer('int64Ptr', 0);
            daec_lib('check_call', 'de_store_scalar', cptr(de), pid, name, ...
                int32(objType), int32(p.elfreq), int64(p.nbytes), p.ptr, idp);
            id = idp.Value;
            if ~isempty(p.jeltype)
                set_attribute(de, id, 'jtype', p.jeltype);
            end
        end

        function id = storeArray(de, pid, name, value, want)
            % want: 1, 2 or [] (any); value decides the layout
            [objType, axes, values] = arrayLayout(value, want);
            e = daec_enums();
            T = e.type_t;
            if objType == T.type_range
                p = struct('eltype', T.type_none, 'elfreq', 0, 'nbytes', 0, ...
                    'ptr', libpointer(), 'jeltype', '');
            else
                p = daec_pack(values);
            end
            prepareStore(de, pid, name);
            ids = zeros(1, numel(axes), 'int64');
            for k = 1:numel(axes)
                ids(k) = makeAxis(de, axes(k));
            end
            idp = libpointer('int64Ptr', 0);
            args = {int32(objType), int32(p.eltype), int32(p.elfreq)};
            switch numel(axes)
                case 1
                    daec_lib('check_call', 'de_store_tseries', cptr(de), pid, name, ...
                        args{:}, ids(1), int64(p.nbytes), p.ptr, idp);
                case 2
                    daec_lib('check_call', 'de_store_mvtseries', cptr(de), pid, name, ...
                        args{:}, ids(1), ids(2), int64(p.nbytes), p.ptr, idp);
                otherwise
                    daec_lib('check_call', 'de_store_ndtseries', cptr(de), pid, name, ...
                        args{:}, int64(numel(ids)), libpointer('int64Ptr', ids), ...
                        int64(p.nbytes), p.ptr, idp);
            end
            id = idp.Value;
            if ~isempty(p.jeltype)
                set_attribute(de, id, 'jeltype', p.jeltype);
            end
        end

        function id = makeAxis(de, ax)
            idp = libpointer('int64Ptr', 0);
            switch ax.kind
                case "plain"
                    daec_lib('check_call', 'de_axis_plain', cptr(de), int64(ax.length), idp);
                case "range"
                    first = ax.firstdate();
                    daec_lib('check_call', 'de_axis_range', cptr(de), int64(ax.length), ...
                        int32(first.frequency), int64(first.value), idp);
                case "names"
                    daec_lib('check_call', 'de_axis_names', cptr(de), int64(ax.length), ...
                        char(strjoin(ax.names, newline)), idp);
            end
            id = idp.Value;
        end

        function value = finishLoad(de, id, out, raw)
            % out is the loaded tseries_t, mvtseries_t or ndtseries_t and
            % raw its axis_t structs.  Copy the values out first: libdaec
            % reuses that buffer on the next call.
            e = daec_enums();
            objType = daec_code('type_t', out.object.obj_type);
            if objType == e.type_t.type_range
                values = [];
            else
                n = prod(cellfun(@(a) double(a.length), raw));
                values = daec_unpack(out.value, out.eltype, out.elfreq, out.nbytes, n);
            end
            % A names axis points into SQLite's row buffer, which loading
            % the next axis overwrites, so only the last axis's names
            % survive the load.  Reload each names axis on its own.
            axes = tse.daec.Axis.empty(1, 0);
            for k = 1:numel(raw)
                a = raw{k};
                if daec_code('axis_type_t', a.ax_type) == e.axis_type_t.axis_names
                    [~, a] = daec_lib('check_call', 'de_load_axis', cptr(de), ...
                        int64(a.id), libpointer('axis_t', axisStruct()));
                end
                axes(k) = daec_axis(a);
            end
            value = finishArray(de, id, objType, axes, values);
        end

        function value = finishArray(de, id, objType, axes, values)
            jeltype = get_attribute(de, id, 'jeltype');
            if ismissing(jeltype)
                jeltype = '';
            end
            value = daec_assemble(objType, axes, values, jeltype);
        end

        function id = writeValue(de, pid, name, value)
            if isstruct(value) && isscalar(value)
                id = new_catalog(de, pid, name);
                writeStruct(de, id, value);
            elseif isa(value, 'tse.TSeries') || isa(value, 'tse.MITRange')
                id = storeArray(de, pid, name, value, 1);
            elseif isa(value, 'tse.MVTSeries')
                id = storeArray(de, pid, name, value, 2);
            elseif isa(value, 'tse.daec.Array')
                id = storeArray(de, pid, name, value, []);
            elseif (ischar(value) && (isrow(value) || isempty(value))) ...
                    || ((isnumeric(value) || islogical(value) || isstring(value) ...
                    || isa(value, 'tse.MIT') || isa(value, 'tse.Duration')) && isscalar(value))
                id = storeScalar(de, pid, name, value);
            elseif isnumeric(value) || islogical(value) || isstring(value) ...
                    || iscellstr(value) || isa(value, 'tse.MIT') || isa(value, 'tse.Duration')
                id = storeArray(de, pid, name, value, []);
            else
                error('tseries:daec', 'Cannot write a value of class %s.', class(value));
            end
        end

        function writeStruct(de, pid, data)
            names = fieldnames(data);
            for k = 1:numel(names)
                try
                    writeValue(de, pid, names{k}, data.(names{k}));
                catch err
                    where = names{k};
                    if pid ~= de.root_id
                        where = [get_fullpath(de, pid) '/' where];
                    end
                    warning('tseries:daec', 'Failed to write %s: %s', where, err.message);
                end
            end
        end

        function value = readValue(de, id)
            e = daec_enums();
            C = e.class_t;
            s = objectStruct();
            [~, obj] = daec_lib('check_call', 'de_load_object', cptr(de), id, ...
                libpointer('object_t', s));
            switch daec_code('class_t', obj.obj_class)
                case C.class_catalog
                    value = readCatalog(de, id);
                case C.class_scalar
                    value = load_scalar(de, id);
                case C.class_tseries
                    value = load_tseries(de, id);
                case C.class_mvtseries
                    value = load_mvtseries(de, id);
                case C.class_ndtseries
                    value = load_ndtseries(de, id);
                otherwise
                    error('tseries:daec', 'Unknown object class %s.', string(obj.obj_class));
            end
        end

        function data = readCatalog(de, cid)
            data = struct();
            children = catalogChildren(de, cid);
            for k = 1:numel(children)
                c = children(k);
                field = c.name;
                if ~isvarname(field)
                    field = matlab.lang.makeValidName(field);
                    warning('tseries:daec', 'Read object "%s" into field %s.', c.name, field);
                end
                try
                    data.(field) = readValue(de, c.id);
                catch err
                    daec_lib('call', 'de_clear_error');
                    warning('tseries:daec', 'Failed to load %s: %s', c.name, err.message);
                end
            end
        end

        function children = catalogChildren(de, cid)
            % id, name and class of each object in a catalog, in order
            children = struct('id', {}, 'name', {}, 'obj_class', {});
            search = libpointer('voidPtrPtr', 0);
            daec_lib('check_call', 'de_list_catalog', cptr(de), cid, search);
            cleanup = onCleanup(@() daec_lib('call', 'de_finalize_search', search));
            done = daecStatus('DE_NO_OBJ');
            while true
                s = objectStruct();
                [status, ~, obj] = daec_lib('call', 'de_next_object', search, ...
                    libpointer('object_t', s));
                if status == done
                    daec_lib('call', 'de_clear_error');
                    break
                end
                daec_lib('check', status);
                children(end+1) = struct('id', int64(obj.id), 'name', char(obj.name), ...
                    'obj_class', daec_code('class_t', obj.obj_class)); %#ok<AGROW>
            end
        end

        function list = listCatalog(de, cid, prefix, depth, opts)
            e = daec_enums();
            list = strings(0, 1);
            children = catalogChildren(de, cid);
            for k = 1:numel(children)
                c = children(k);
                path = [prefix '/' c.name];
                indent = repmat(' ', 1, 2 * depth);
                if c.obj_class == e.class_t.class_catalog
                    if opts.recursive
                        if ~opts.quiet, fprintf('%s%s/\n', indent, c.name); end
                        list = [list; listCatalog(de, c.id, path, depth + 1, opts)]; %#ok<AGROW>
                    elseif ~opts.quiet
                        fprintf('%s%s/ (%d objects)\n', indent, c.name, catalog_size(de, c.id));
                    end
                else
                    if ~opts.quiet, fprintf('%s %s\n', indent, c.name); end
                    list(end+1, 1) = string(path); %#ok<AGROW>
                end
            end
        end
    end
end

% ---------- local functions ----------

function s = objectStruct()
    s = libstruct('object_t', struct('obj_class', int32(0), 'obj_type', int32(0)));
end

function s = axisStruct()
    s = libstruct('axis_t', struct('ax_type', int32(0), 'frequency', int32(0)));
end

function id = foundId(status, idp, dne_error)
    if status == daecStatus('DE_OBJ_DNE') && ~dne_error
        daec_lib('call', 'de_clear_error');
        id = [];
        return
    end
    daec_lib('check', status);
    id = idp.Value;
end

function s = daecStatus(name)
    e = daec_enums();
    s = e.status_t.(name);
end

function opts = nameValues(args, opts)
    if mod(numel(args), 2) ~= 0
        error('tseries:noMatch', 'Options come in name, value pairs.');
    end
    for k = 1:2:numel(args)
        key = char(args{k});
        if ~isfield(opts, key)
            error('tseries:noMatch', 'Unknown option ''%s''.', key);
        end
        opts.(key) = args{k + 1};
    end
end

function [objType, axes, values] = arrayLayout(value, want)
% Object type, axes and values to store for an array-like value.
    e = daec_enums();
    T = e.type_t;
    if isa(value, 'tse.MITRange')
        objType = T.type_range;
        axes = tse.daec.Axis(value);
        values = [];
    elseif isa(value, 'tse.TSeries')
        a = tse.daec.Array(value);
        objType = T.type_tseries;
        axes = a.axes;
        values = a.values;
    elseif isa(value, 'tse.MVTSeries')
        a = tse.daec.Array(value);
        objType = T.type_mvtseries;
        axes = a.axes;
        values = a.values;
    elseif isa(value, 'tse.daec.Array')
        axes = value.axes;
        values = value.values;
        kinds = [axes.kind];
        switch numel(axes)
            case 1
                if kinds == "plain"
                    objType = T.type_vector;
                elseif kinds == "range"
                    objType = T.type_tseries;
                else
                    objType = T.type_other_1d;
                end
            case 2
                if all(kinds == "plain")
                    objType = T.type_matrix;
                elseif isequal(kinds, ["range" "names"])
                    objType = T.type_mvtseries;
                else
                    objType = T.type_other_2d;
                end
            otherwise
                if all(kinds == "plain")
                    objType = T.type_tensor;
                else
                    objType = T.type_ndtseries;
                end
        end
    else
        if iscellstr(value) || ischar(value)
            value = string(value);
        end
        sz = size(value);
        if numel(sz) == 2 && sz(2) == 1 && (isempty(want) || want == 1)
            sz = sz(1);
        elseif isequal(want, 1)
            if ~isvector(value) && ~isempty(value)
                error('tseries:daec', 'store_tseries needs a vector.');
            end
            sz = numel(value);
        end
        axes = tse.daec.Axis.empty(1, 0);
        for k = 1:numel(sz)
            axes(k) = tse.daec.Axis(sz(k));
        end
        values = value;
        switch numel(sz)
            case 1, objType = T.type_vector;
            case 2, objType = T.type_matrix;
            otherwise, objType = T.type_tensor;
        end
    end
    if isequal(want, 1) && numel(axes) ~= 1
        error('tseries:daec', 'store_tseries needs a 1-d value, not %d-d.', numel(axes));
    end
    if isequal(want, 2) && numel(axes) ~= 2
        error('tseries:daec', 'store_mvtseries needs a 2-d value, not %d-d.', numel(axes));
    end
end

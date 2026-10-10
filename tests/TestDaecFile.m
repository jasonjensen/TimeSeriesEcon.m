classdef TestDaecFile < matlab.unittest.TestCase
    %TESTDAECFILE  Reading and writing .daec files through tse.daec.
    %
    %   Includes DataEcon's MATLAB test scripts test_tse.m, test_tse_dates.m
    %   and test_float32.m (bankofcanada/DataEcon, matlab branch), ported
    %   to tse types.  Skips on platforms with no bundled libdaec.

    properties
        file
    end

    methods (TestClassSetup)
        function needsBundledLibrary(tc)
            arch = computer('arch');
            root = fileparts(fileparts(mfilename('fullpath')));
            bin = fullfile(root, '+tse', '+daec', 'private', 'bin', arch);
            tc.assumeTrue(isfolder(bin) || ~isempty(getenv('TSE_LIBDAEC')), ...
                sprintf('No bundled libdaec for %s.', arch));
        end
    end

    methods (TestMethodSetup)
        function tempFile(tc)
            tc.file = [tempname '.daec'];
            tc.addTeardown(@() deleteIfExists(tc.file));
        end
    end

    methods (Test)

        % ---- scalars ----

        function scalars_roundtrip(tc)
            d = struct();
            d.double_val = 3.14159;
            d.negative_val = -123.456;
            d.small_val = 1.0e-15;
            d.zero_val = 0;
            d.int64_min = intmin('int64');
            d.int8_val = int8(-7);
            d.uint16_val = uint16(65535);
            d.uint64_max = intmax('uint64');
            d.single_val = single(0.1);
            d.complex_val = complex(2.5, 3.7);
            d.complex_single = complex(single(1.25), single(-2.5));
            d.true_val = true;
            d.false_val = false;
            d.char_val = 'Hello World!';
            d.empty_char = '';
            d.unicode_val = 'caf\x00e9 \x20ac';
            d.quarter = tse.qq(2022, 3);
            d.month = tse.mm(2022, 9);
            d.day = tse.day('2022-09-10');
            d.half = tse.MIT(tse.HalfYearly(6), 2022, 1);
            d.steps = tse.Duration(tse.Quarterly(), 4);
            d.unicode_val = sprintf(d.unicode_val);

            tse.daec.writedb(tc.file, d);
            r = tse.daec.readdb(tc.file);

            % libdaec lists a catalog by name
            tc.verifyEqual(fieldnames(r), sort(fieldnames(d)));
            for f = fieldnames(d)'
                tc.verifyEqual(r.(f{1}), d.(f{1}), f{1});
            end
        end

        function string_scalar_reads_as_char(tc)
            tse.daec.writedb(tc.file, struct('s', "text"));
            r = tse.daec.readdb(tc.file);
            tc.verifyEqual(r.s, 'text');
        end

        % ---- arrays ----

        function arrays_roundtrip(tc)
            d = struct();
            d.double_vec = [1.1; 2.2; 3.3];
            d.row_vec = [1.1, 2.2, 3.3];          % stays 1-by-3
            d.int64_vec = int64([10; -20; 30]);
            d.int32_vec = int32([1; 2; 3]);
            d.uint64_vec = uint64([10; 20; 30]);
            d.logical_vec = [true; false; true];
            d.single_vec = single([0.1; 0.2; 1.5]);
            d.complex_vec = [1.1 + 5.5i; 2.2 + 4.4i];
            d.string_vec = ["a"; ""; "ccc"];
            d.date_vec = [tse.qq(2020, 1); tse.qq(2020, 2)];
            d.empty_vec = zeros(0, 1);
            d.double_mat = [1.1, 2.2, 3.3; 4.4, 5.5, 6.6];
            d.complex_mat = complex(rand(4, 3), rand(4, 3));
            d.logical_mat = logical([1 0; 0 1]);
            d.tensor = reshape(1:24, 2, 3, 4);
            d.tensor5 = rand(2, 2, 2, 2, 2);
            d.large_mat = randn(200, 80);

            tse.daec.writedb(tc.file, d);
            r = tse.daec.readdb(tc.file);
            for f = fieldnames(d)'
                tc.verifyEqual(r.(f{1}), d.(f{1}), f{1});
            end
        end

        function cellstr_reads_as_strings(tc)
            tse.daec.writedb(tc.file, struct('c', {{'x'; 'yy'}}));
            r = tse.daec.readdb(tc.file);
            tc.verifyEqual(r.c, ["x"; "yy"]);
        end

        function six_dimensions_is_skipped_with_a_warning(tc)
            d = struct('ok', 1, 'big', rand(2, 2, 2, 2, 2, 2));
            tc.verifyWarning(@() tse.daec.writedb(tc.file, d), 'tseries:daec');
            r = tse.daec.readdb(tc.file);
            tc.verifyEqual(fieldnames(r), {'ok'});
        end

        % ---- series (DataEcon's test_tse.m) ----

        function tseries_every_frequency(tc)
            d = struct();
            d.yearly = tse.TSeries(tse.yy(1990), (1:30)');
            d.halfyearly = tse.TSeries(tse.MIT(tse.HalfYearly(6), 2000, 1), (1:12)');
            d.quarterly = tse.TSeries(tse.qq(2000, 1), 100 + cumsum(randn(24, 1)));
            d.quarterly_jan = tse.TSeries(tse.MIT(tse.Quarterly(1), 2000, 1), (1:8)');
            d.monthly = tse.TSeries(tse.mm(2010, 6), (1:60)');
            d.weekly = tse.TSeries(tse.MIT(tse.Weekly(7), 2021, 1), rand(10, 1));
            d.daily = tse.TSeries(tse.day('2023-01-01'), cumsum(randn(15, 1)));
            d.bdaily = tse.TSeries(tse.bday('2023-01-02'), cumsum(randn(20, 1)));
            d.unit = tse.TSeries(tse.MIT(tse.Unit(), 5), [1; NaN; 3]);
            d.logical_ts = tse.TSeries(tse.qq(2000, 1), [true; false]);
            d.empty_ts = tse.TSeries(tse.qq(2000, 1), zeros(0, 1));

            tse.daec.writedb(tc.file, d);
            r = tse.daec.readdb(tc.file);
            for f = fieldnames(d)'
                verifySeries(tc, r.(f{1}), d.(f{1}), f{1});
            end
        end

        function mvtseries_roundtrip(tc)
            d = struct();
            d.quarterly = tse.MVTSeries(tse.qq(2000, 1), {'gdp', 'cpi', 'rate'}, reshape(1:72, 24, 3));
            d.monthly = tse.MVTSeries(tse.mm(2010, 6), {'x', 'y'}, reshape(1:120, 60, 2));
            d.weekly = tse.MVTSeries(tse.MIT(tse.Weekly(7), 2021, 1), {'p', 'q'}, reshape(1:20, 10, 2));
            d.one_column = tse.MVTSeries(tse.yy(2000), {'only'}, (1:5)');
            d.complex = tse.MVTSeries(tse.qq(2022, 3), {'a', 'b'}, complex(rand(5, 2), rand(5, 2)));

            tse.daec.writedb(tc.file, d);
            r = tse.daec.readdb(tc.file);
            for f = fieldnames(d)'
                verifySeries(tc, r.(f{1}), d.(f{1}), f{1});
            end
        end

        function mitrange_roundtrip(tc)
            rng = tse.qq(2020, 1):tse.qq(2024, 4);
            tse.daec.writedb(tc.file, struct('rng', rng));
            r = tse.daec.readdb(tc.file);
            tc.verifyClass(r.rng, 'tse.MITRange');
            tc.verifyTrue(first(r.rng) == first(rng));
            tc.verifyTrue(last(r.rng) == last(rng));
        end

        % ---- arrays with axes in any order ----

        function names_by_dates_reads_as_array(tc)
            % DataEcon's ndtseries test layout: names first, then dates
            axes = [tse.daec.Axis(["GDP" "CPI"]), tse.daec.Axis(tse.qq(2022, 3), 5)];
            a = tse.daec.Array(axes, [1.1 2.2 3.3 4.4 5.5; 1.2 2.3 3.4 4.5 5.6]);
            tse.daec.writedb(tc.file, struct('a', a));
            r = tse.daec.readdb(tc.file);
            tc.verifyClass(r.a, 'tse.daec.Array');
            tc.verifyTrue(isequal(r.a, a));
        end

        function three_d_with_a_range_axis(tc)
            axes = [tse.daec.Axis(tse.mm(2020, 1), 4), tse.daec.Axis(["a" "b"]), tse.daec.Axis(3)];
            a = tse.daec.Array(axes, reshape(1:24, 4, 2, 3));
            tse.daec.writedb(tc.file, struct('a', a));
            r = tse.daec.readdb(tc.file);
            tc.verifyTrue(isequal(r.a, a));
        end

        function one_names_axis(tc)
            a = tse.daec.Array(tse.daec.Axis({'x', 'y', 'z'}), [1; 2; 3]);
            tse.daec.writedb(tc.file, struct('a', a));
            r = tse.daec.readdb(tc.file);
            tc.verifyTrue(isequal(r.a, a));
        end

        function array_of_a_series_reads_as_the_series(tc)
            x = tse.MVTSeries(tse.qq(2000, 1), {'a', 'b'}, rand(4, 2));
            a = tse.daec.Array(x);
            tc.verifyEqual(a.toseries().values, x.values);
            tse.daec.writedb(tc.file, struct('a', a));
            r = tse.daec.readdb(tc.file);
            verifySeries(tc, r.a, x, 'a');
        end

        function array_checks_its_shape(tc)
            tc.verifyError(@() tse.daec.Array(tse.daec.Axis(3), [1; 2]), 'tseries:noMatch');
            tc.verifyError(@() tse.daec.Array([tse.daec.Axis(2), tse.daec.Axis(2)], ones(2, 3)), ...
                'tseries:noMatch');
        end

        % ---- 32-bit floats (DataEcon's test_float32.m) ----

        function float32_reads_as_single(tc)
            % TimeSeriesEcon.jl writes Float32 as 4-byte floats; they must
            % not be read as 8-byte doubles.
            raw = [0.1, 0.2, 1.5, 2.25, 100.375, -3.5];
            d.vec = single(raw(:));
            d.mat = single(reshape(raw, 2, 3));
            d.scalar = single(0.1);
            d.cplx = complex(single(1.25), single(-2.5));
            tse.daec.writedb(tc.file, d);
            r = tse.daec.readdb(tc.file);
            for f = fieldnames(d)'
                tc.verifyClass(r.(f{1}), 'single', f{1});
                tc.verifyEqual(r.(f{1}), d.(f{1}), f{1});
            end
        end

        % ---- catalogs and the File API ----

        function nested_catalogs(tc)
            d.top = 1;
            d.models.gdp = tse.TSeries(tse.qq(2000, 1), (1:4)');
            d.models.inner.n = int64(3);
            d.empty = struct();
            tse.daec.writedb(tc.file, d);

            r = tse.daec.readdb(tc.file);
            tc.verifyEqual(r.models.inner.n, int64(3));
            tc.verifyEqual(r.empty, struct());
            sub = tse.daec.readdb(tc.file, '/models');
            tc.verifyEqual(sub.inner.n, int64(3));

            de = tse.daec.opendaec(tc.file);
            list = de.list_catalog('quiet', true);
            tc.verifyEqual(list, ["/models/gdp"; "/models/inner/n"; "/top"]);
            tc.verifyEqual(de.catalog_size(), 3);
            tc.verifyEqual(de.catalog_size('/models'), 2);
            tc.verifyEqual(de.load_scalar('/models/inner', 'n'), int64(3));
            tc.verifyEqual(de.get_fullpath(de.find_fullpath('models/inner/n')), '/models/inner/n');
            tc.verifyEmpty(de.find_object(0, 'nothing', false));
            tc.verifyError(@() de.find_object(0, 'nothing'), 'tseries:daec');
            de.close();
            tc.verifyFalse(de.isopen());
        end

        function file_api_stores_and_loads(tc)
            de = tse.daec.opendaec(tc.file, 'write', true);
            cid = de.new_catalog('c');
            de.store_scalar(cid, 'x', 2.5);
            de.store_tseries('/c/v', [1 2 3]);           % a row is stored as a vector
            de.store_mvtseries('/c/m', [1; 2]);          % a column as a 2-by-1 matrix
            de.store_ndtseries('/c/t', ones(2, 2, 2));
            de.write_data('/c/ts', tse.TSeries(tse.yy(2000), [1; 2]));
            tc.verifyEqual(de.load_scalar('/c/x'), 2.5);
            tc.verifyEqual(de.load_tseries('/c/v'), [1; 2; 3]);
            tc.verifyEqual(de.load_mvtseries('/c/m'), [1; 2]);
            tc.verifyEqual(de.load_ndtseries('/c/t'), ones(2, 2, 2));
            tc.verifyClass(de.read_data('c', 'ts'), 'tse.TSeries');
            tc.verifyError(@() de.load_scalar('/c/v'), 'tseries:daec');
            de.delete_object('/c/x');
            tc.verifyEmpty(de.find_fullpath('/c/x', false));
            de.close();
        end

        function attributes(tc)
            de = tse.daec.opendaec(tc.file, 'write', true);
            id = de.store_scalar('x', 1);
            tc.verifyTrue(ismissing(de.get_attribute(id, 'note')));
            de.set_attribute(id, 'note', 'hello');
            de.set_attribute('x', 'unit', 'kg');
            tc.verifyEqual(de.get_attribute('/x', 'note'), 'hello');
            tc.verifyEqual(de.get_attribute(0, 'x', 'unit'), 'kg');
            a = de.get_all_attributes('x');
            tc.verifyEqual(sort(a.keys()), {'note', 'unit'});
            tc.verifyEqual(a('unit'), 'kg');
            de.close();
        end

        function existing_names_need_overwrite(tc)
            de = tse.daec.opendaec(tc.file, 'write', true);
            de.store_scalar('x', 1);
            tc.verifyError(@() de.store_scalar('x', 2), 'tseries:daec');
            de.close();
            de = tse.daec.opendaec(tc.file, 'write', true, 'overwrite', true);
            de.store_scalar('x', 2);
            tc.verifyEqual(de.load_scalar('x'), 2);
            de.close();
        end

        function readonly_and_truncate(tc)
            tse.daec.writedb(tc.file, struct('a', 1));
            de = tse.daec.opendaec(tc.file);
            tc.verifyError(@() de.store_scalar('b', 2), 'tseries:daec');
            de.close();
            tc.verifyError(@() tse.daec.opendaec(tc.file, 'truncate', true), 'tseries:noMatch');

            tse.daec.writedb(tc.file, struct('b', 2));                     % appends
            tc.verifyEqual(fieldnames(tse.daec.readdb(tc.file)), {'a'; 'b'});
            tse.daec.writedb(tc.file, struct('c', 3), 'append', false);    % empties first
            tc.verifyEqual(fieldnames(tse.daec.readdb(tc.file)), {'c'});
        end

        function in_memory_file(tc)
            de = tse.daec.opendaecmem();
            tc.verifyTrue(de.isempty());
            de.writedb(struct('a', 1, 'b', "x"));
            tc.verifyEqual(tse.daec.readdb(de), struct('a', 1, 'b', 'x'));
            tse.daec.closedaec(de);
        end

        function read_and_write_aliases(tc)
            % moved from TestDaecInterop: these no longer need DataEcon
            d = struct();
            d.gdp = tse.TSeries(tse.qq(2000, 1), (1:24)');
            d.mv = tse.MVTSeries(tse.mm(2010, 1), {'a', 'b'}, reshape(1:24, 12, 2));
            tse.daec.write(tc.file, struct('old', 1));
            tse.daec.write(tc.file, d);
            d2 = tse.daec.read(tc.file);
            tc.verifyEqual(fieldnames(d2), {'gdp'; 'mv'});
            verifySeries(tc, d2.gdp, d.gdp, 'gdp');
            verifySeries(tc, d2.mv, d.mv, 'mv');
        end

        % ---- dates (DataEcon's test_tse_dates.m) ----

        function libdaec_decodes_dates_like_tse(tc)
            % tse and DataEcon share their date integers; check libdaec
            % turns them into the same calendar dates tse does.
            yp = {tse.yy(2020), tse.MIT(tse.HalfYearly(6), 2020, 2), ...
                tse.qq(2020, 3), tse.mm(2020, 7)};
            cal = {tse.MIT(tse.Weekly(7), 2021, 10), tse.day('2023-01-15'), ...
                tse.bday('2023-01-16')};
            tse.daec.version();   % loads the library
            for k = 1:numel(yp)
                m = yp{k};
                [~, y, p] = calllib('tse_libdaec', 'de_unpack_year_period_date', ...
                    int32(m.frequency), m.value, libpointer('int32Ptr', 0), libpointer('uint32Ptr', 0));
                ref = tse.mit2yp(m);
                tc.verifyEqual(double([y p]), double(ref(1:2)), char(m));
            end
            for k = 1:numel(cal)
                m = cal{k};
                [~, y, mo, dd] = calllib('tse_libdaec', 'de_unpack_calendar_date', ...
                    int32(m.frequency), m.value, libpointer('int32Ptr', 0), ...
                    libpointer('uint32Ptr', 0), libpointer('uint32Ptr', 0));
                [ty, tm, td] = ymd(tse.toDate(m));
                tc.verifyEqual(double([y mo dd]), [ty tm td], char(m));
            end
        end
    end
end

function verifySeries(tc, got, want, name)
    tc.verifyClass(got, class(want), name);
    if ~isa(got, class(want))
        return
    end
    tc.verifyTrue(got.firstdate == want.firstdate, name);
    tc.verifyEqual(got.values, want.values, name);
    if isa(want, 'tse.MVTSeries')
        tc.verifyEqual(string(got.colnames), string(want.colnames), name);
    end
end

function deleteIfExists(f)
    if exist(f, 'file')
        delete(f);
    end
end

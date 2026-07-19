classdef TestFameSeries < matlab.unittest.TestCase
    %TESTFAMESERIES  Series read/write round-trip tests for tse.fame.*.
    %
    %   These write a temporary FAME database and read it back, so they need
    %   the CHLI loaded AND write access.  The whole suite skips cleanly when
    %   the CHLI is not loaded (tse.fame.startup).

    methods (TestMethodSetup)
        function skipIfNoFame(tc)
            if ~tse.fame.isavailable()
                tc.assumeFail('FAME CHLI is not loaded; run tse.fame.startup first.');
            end
        end
    end

    methods (Test)

        function precision_and_numeric_roundtrip(tc)
            f = [tempname '.db'];
            cleaner = onCleanup(@() cleanupDb(f)); %#ok<NASGU>

            d.gdp = tse.TSeries(tse.qq(2000, 1), (1:24)');            % double -> precision
            d.cpi = tse.TSeries(tse.mm(2010, 1), single((1:60)'));   % single -> numeric

            tse.fame.write(f, d);
            d2 = tse.fame.read(f, {'gdp', 'cpi'});

            tc.verifyEqual(d2.gdp.values, d.gdp.values);
            tc.verifyTrue(d.gdp.firstdate == d2.gdp.firstdate);
            % numeric series: values match (single precision-exact here).
            tc.verifyEqual(double(d2.cpi.values), double(d.cpi.values));
            tc.verifyTrue(d.cpi.firstdate == d2.cpi.firstdate);
        end

        function missing_values_roundtrip(tc)
            f = [tempname '.db'];
            cleaner = onCleanup(@() cleanupDb(f)); %#ok<NASGU>

            v = (1:12)';
            v([3, 7]) = NaN;
            d.x = tse.TSeries(tse.mm(2020, 1), v);

            tse.fame.write(f, d);
            d2 = tse.fame.read(f, {'x'});

            tc.verifyTrue(isequaln(d2.x.values, v));   % NaN in the same positions
            tc.verifyTrue(all(isnan(d2.x.values([3, 7]))));
        end

        function annual_roundtrip(tc)
            f = [tempname '.db'];
            cleaner = onCleanup(@() cleanupDb(f)); %#ok<NASGU>

            d.y = tse.TSeries(tse.yy(1990), (1:30)');
            tse.fame.write(f, d);
            d2 = tse.fame.read(f, {'y'});
            tc.verifyEqual(d2.y.values, d.y.values);
            tc.verifyTrue(d.y.firstdate == d2.y.firstdate);
        end

        function read_whole_db_by_enumeration(tc)
            f = [tempname '.db'];
            cleaner = onCleanup(@() cleanupDb(f)); %#ok<NASGU>

            d.gdp = tse.TSeries(tse.qq(2000, 1), (1:24)');
            d.cpi = tse.TSeries(tse.mm(2010, 1), (1:60)');
            tse.fame.write(f, d);

            d2 = tse.fame.read(f);                 % no names -> enumerate all
            tc.verifyTrue(isfield(d2, 'gdp'));
            tc.verifyTrue(isfield(d2, 'cpi'));
            tc.verifyEqual(d2.gdp.values, d.gdp.values);
            tc.verifyEqual(d2.cpi.values, d.cpi.values);
        end

        function frequency_coverage(tc)
            % Round-trip across more frequencies: a non-default end period
            % (Quarterly(1)), the calendar frequencies daily/bdaily, and
            % weekly (tse.mit2yp and FAME agree, and MIT(Weekly,y,p) rebuilds
            % the original -- confirmed against the CHLI).
            f = [tempname '.db'];
            cleaner = onCleanup(@() cleanupDb(f)); %#ok<NASGU>

            d = struct();
            d.hy = tse.TSeries(tse.MIT(tse.HalfYearly(6), 2000, 1), (1:20)');
            d.qj = tse.TSeries(tse.MIT(tse.Quarterly(1),  2000, 1), (1:16)');
            d.da = tse.TSeries(tse.day('2023-01-01'),               (1:30)');
            d.bd = tse.TSeries(tse.bday('2023-01-02'),              (1:20)');
            d.wk = tse.TSeries(tse.week('2021-03-07'),              (1:15)');
            tse.fame.write(f, d);

            d2 = tse.fame.read(f, {'hy', 'qj', 'da', 'bd', 'wk'});
            for nm = {'hy', 'qj', 'da', 'bd', 'wk'}
                key = nm{1};
                tc.verifyEqual(d2.(key).values, d.(key).values, ...
                    sprintf('values differ for %s', key));
                tc.verifyTrue(d.(key).firstdate == d2.(key).firstdate, ...
                    sprintf('firstdate differs for %s', key));
            end
        end

        function boolean_roundtrip(tc)
            f = [tempname '.db'];
            cleaner = onCleanup(@() cleanupDb(f)); %#ok<NASGU>

            d.flag = tse.TSeries(tse.qq(2000, 1), logical([1 0 1 1 0 1 0 0]'));
            tse.fame.write(f, d);
            d2 = tse.fame.read(f, {'flag'});
            tc.verifyClass(d2.flag.values, 'logical');
            tc.verifyEqual(d2.flag.values, d.flag.values);
        end

        function string_roundtrip(tc)
            % tse has no string-valued series, so build the FAME object at the
            % CHLI level, then read it back (read_object returns a bare string
            % array).  This exercises the char** marshaling.
            f = [tempname '.db'];
            cleaner = onCleanup(@() cleanupDb(f)); %#ok<NASGU>
            freq = 162;                                   % quarterly time axis
            strs = ["alpha"; "beta"; "gamma"; "delta"];

            dbkey = tse.fame.CHLI.opendb(f, 3);           % HOMODE (overwrite)
            tse.fame.CHLI.newobj(dbkey, 'tags', 1, freq, 4, 1, 0);  % HSERIE, freq, HSTRNG, HBSDAY, HOBUND
            i0 = tse.fame.CHLI.yp_to_index(freq, 2000, 1);
            i1 = tse.fame.CHLI.yp_to_index(freq, 2000, 4);
            tse.fame.CHLI.write_strings(dbkey, 'tags', ...
                tse.fame.CHLI.make_range(freq, i0, i1), strs);
            tse.fame.CHLI.postdb(dbkey);
            tse.fame.CHLI.closedb(dbkey);

            d2 = tse.fame.read(f, {'tags'});
            tc.verifyEqual(cellstr(d2.tags), cellstr(strs));
        end

        function date_valued_roundtrip(tc)
            % Likewise build a date-valued series at the CHLI level (value
            % frequency stored in the type field), then read it back as a
            % tse.MIT array.
            f = [tempname '.db'];
            cleaner = onCleanup(@() cleanupDb(f)); %#ok<NASGU>
            freq    = 162;                                % quarterly time axis
            valfreq = 162;                                % quarterly-valued dates
            dates   = [tse.qq(2020, 1); tse.qq(2020, 2); tse.qq(2020, 3); tse.qq(2020, 4)];

            dbkey = tse.fame.CHLI.opendb(f, 3);
            tse.fame.CHLI.newobj(dbkey, 'dts', 1, freq, valfreq, 1, 0);  % type = value freq
            i0 = tse.fame.CHLI.yp_to_index(freq, 2000, 1);
            i1 = tse.fame.CHLI.yp_to_index(freq, 2000, 4);
            idx = zeros(4, 1, 'int64');
            for i = 1:4
                yp = tse.mit2yp(dates(i));
                idx(i) = tse.fame.CHLI.yp_to_index(valfreq, yp(1), yp(2));
            end
            tse.fame.CHLI.write_dates(dbkey, 'dts', ...
                tse.fame.CHLI.make_range(freq, i0, i1), valfreq, idx);
            tse.fame.CHLI.postdb(dbkey);
            tse.fame.CHLI.closedb(dbkey);

            d2 = tse.fame.read(f, {'dts'});
            tc.verifyEqual(numel(d2.dts), 4);
            for i = 1:4
                tc.verifyTrue(d2.dts(i) == dates(i));
            end
        end

    end
end

function cleanupDb(f)
    if exist(f, 'file')
        delete(f);
    end
end

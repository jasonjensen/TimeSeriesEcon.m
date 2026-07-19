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
            % Round-trip across more frequencies, including a non-default end
            % period (Quarterly(1)) and the calendar frequencies daily/bdaily.
            % (Weekly is deferred -- its year/period reconstruction needs the
            % ISO-week path, tracked separately.)
            f = [tempname '.db'];
            cleaner = onCleanup(@() cleanupDb(f)); %#ok<NASGU>

            d = struct();
            d.hy = tse.TSeries(tse.MIT(tse.HalfYearly(6), 2000, 1), (1:20)');
            d.qj = tse.TSeries(tse.MIT(tse.Quarterly(1),  2000, 1), (1:16)');
            d.da = tse.TSeries(tse.day('2023-01-01'),               (1:30)');
            d.bd = tse.TSeries(tse.bday('2023-01-02'),              (1:20)');
            tse.fame.write(f, d);

            d2 = tse.fame.read(f, {'hy', 'qj', 'da', 'bd'});
            for nm = {'hy', 'qj', 'da', 'bd'}
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
            f = [tempname '.db'];
            cleaner = onCleanup(@() cleanupDb(f)); %#ok<NASGU>

            d.tags = tse.TSeries(tse.qq(2000, 1), ["alpha"; "beta"; "gamma"; "delta"]);
            tse.fame.write(f, d);
            d2 = tse.fame.read(f, {'tags'});
            tc.verifyEqual(cellstr(d2.tags.values), cellstr(d.tags.values));
        end

    end
end

function cleanupDb(f)
    if exist(f, 'file')
        delete(f);
    end
end

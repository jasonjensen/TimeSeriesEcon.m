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

    end
end

function cleanupDb(f)
    if exist(f, 'file')
        delete(f);
    end
end

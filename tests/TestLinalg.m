classdef TestLinalg < matlab.unittest.TestCase
    %TESTLINALG  Mirrors @testset "linalg" of test_various.jl.

    methods (Test)

        function adjoint_tseries(tc)
            v = 10.0 + (1:12)';
            s = tse.TSeries(tse.qq(2020,1), v);
            tc.verifyEqual(adjoint(s), v', 'AbsTol', 0);
        end

        function adjoint_mvts(tc)
            U = tse.Unit();
            x = tse.MVTSeries(tse.MIT(U,1):tse.MIT(U,10), {'a','b'});
            a = (1:10)';
            b = (11:20)';
            x.a = a;
            x.b = b;
            tc.verifyEqual(adjoint(x), [a, b]');
        end

        function transpose_returns_underlying(tc)
            o = ones(20, 3);
            X = tse.MVTSeries(tse.yy(2000), {'x','y','z'}, o);
            tc.verifyEqual(transpose(X), transpose(o));
        end

        function mvts_div_mvts_delegates(tc)
            U = tse.Unit();
            x  = tse.MVTSeries(tse.MIT(U,1):tse.MIT(U,10), {'a','b'});
            x.a = (1:10)';
            x.b = (11:20)';
            x2 = tse.MVTSeries(tse.MIT(U,1):tse.MIT(U,10), {'a','b'});
            x2.a = (1:10)';
            x2.b = (11:20)';
            tc.verifyEqual(x / x2, x.values / x2.values, 'AbsTol', 1e-10);
            tc.verifyEqual(x / x2.values, x.values / x2.values, 'AbsTol', 1e-10);
            tc.verifyEqual(x.values / x2, x.values / x2.values, 'AbsTol', 1e-10);
        end

        function mvts_mtimes_mvts_delegates(tc)
            U = tse.Unit();
            x = tse.MVTSeries(tse.MIT(U,1):tse.MIT(U,10), {'a','b'});
            x.a = (1:10)';
            x.b = (11:20)';
            x3 = tse.MVTSeries(tse.MIT(U,1):tse.MIT(U,2), ...
                {'a','b','c','d','e','f','g','h','i','j'});
            x3.values = repmat((1:2)', 1, 10);
            tc.verifyEqual(x * x3, x.values * x3.values, 'AbsTol', 1e-10);
        end

        function mvts_mldivide(tc)
            U = tse.Unit();
            x  = tse.MVTSeries(tse.MIT(U,1):tse.MIT(U,10), {'a','b'});
            x.a = (1:10)';
            x.b = (11:20)';
            x2 = tse.MVTSeries(tse.MIT(U,1):tse.MIT(U,10), {'a','b'});
            x2.a = (1:10)';
            x2.b = (11:20)';
            tc.verifyEqual(x \ x2, x.values \ x2.values, 'AbsTol', 1e-9);
        end

        function tseries_div_tseries(tc)
            s  = tse.TSeries(tse.qq(2020,1), 10 + (1:12)');
            s2 = tse.TSeries(tse.qq(2020,1), [2]);
            % s / s2 = 12x1 / 1x1 column = nan-error... actually MATLAB's
            % column-vector / scalar-vector returns the same shape.
            r = s / s2;
            tc.verifyEqual(r.values, s.values / s2.values, 'AbsTol', 1e-10); 
        end
    end
end

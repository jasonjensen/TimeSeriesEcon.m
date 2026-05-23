classdef FconvertTestUtils < matlab.unittest.TestCase
    %FCONVERTTESTUTILS  Shared constructors and comparison helpers for the
    %   fconvert test mirrors (TestFconvert*, generated from test_fconvert.jl).

    methods (Static)
        % ---- MIT / range constructors (mirror Julia literals) ----
        function m = Y(y),        m = tse.MIT(tse.Yearly(), int64(y)); end
        function m = Yv(v, ep),   m = tse.MIT(tse.Yearly(ep), int64(v)); end
        function m = H(y, p),     m = tse.MIT(tse.HalfYearly(), int64(y), int64(p)); end
        function m = Hv(v, ep),   m = tse.MIT(tse.HalfYearly(ep), int64(v)); end
        function m = Q(y, p),     m = tse.qq(y, p); end
        function m = Qn(y, p, ep),m = tse.MIT(tse.Quarterly(ep), int64(y), int64(p)); end
        function m = Qv(v, ep),   m = tse.MIT(tse.Quarterly(ep), int64(v)); end
        function m = M(y, p),     m = tse.mm(y, p); end
        function m = Mv(v),       m = tse.MIT(tse.Monthly(), int64(v)); end
        function m = D(v),        m = tse.MIT(tse.Daily(), int64(v)); end
        function m = BD(v),       m = tse.MIT(tse.BDaily(), int64(v)); end
        function m = W(v, ep),    m = tse.MIT(tse.Weekly(ep), int64(v)); end
        function m = U(v),        m = tse.MIT(tse.Unit(), int64(v)); end
        function r = R(a, b),     r = tse.MITRange(a, b); end

        % slice helper: sl(vec, idx) = vec(idx) (lets us inline-slice expressions)
        function out = sl(v, idx), out = v(idx); end

        % did the thunk throw?
        function tf = threw(fh)
            tf = false;
            try
                fh();
            catch
                tf = true;
            end
        end
    end

    methods
        % ---- comparison helpers ----
        function vApprox(tc, actual, expected, tol)
            % NaN-aware approximate equality on numeric vectors/scalars.
            a = double(actual); a = a(:);
            e = double(expected); e = e(:);
            tc.verifyEqual(numel(a), numel(e), 'length mismatch');
            both = isnan(a) & isnan(e);
            if any(~both)
                tc.verifyLessThanOrEqual(max(abs(a(~both) - e(~both))), tol);
            end
        end

        function vRange(tc, rng, a, b)
            tc.verifyTrue(eq(rng, tse.MITRange(a, b)));
        end

        function vRangeVals(tc, rng, lo, hi)
            tc.verifyEqual(double(rng.startMIT.value), double(lo));
            tc.verifyEqual(double(rng.stopMIT.value), double(hi));
        end
    end
end

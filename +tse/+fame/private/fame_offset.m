function O = fame_offset(F)
%FAME_OFFSET  Constant offset between a tse MIT value and a FAME date index.
%
%   O = fame_offset(F)   (private to +tse/+fame)
%
%   For a given frequency, the FAME date index and the tse MIT.value both
%   advance by exactly 1 per period, so their difference is a constant that
%   depends only on the frequency.  We recover it from a single real
%   conversion: take a reference MIT of frequency F, get a calendar day
%   inside its period (tse.toDate ... 'end'), ask the CHLI for that day's
%   FAME index (cfmddat), and subtract the MIT value.
%
%       fame_index(m) == m.value + O          (see tse.fame.to_date)
%       m.value       == fame_index - O       (see tse.fame.from_date)
%
%   Computing O this way absorbs any epoch/phase difference between the two
%   date systems (so e.g. the weekly week-numbering offset just falls out).
%   As a safety net we compute O from two different reference years and
%   error if they disagree -- that catches a genuinely non-constant mapping
%   (for instance BDaily against a holiday calendar, or a weekly end-day
%   mismatch) instead of silently returning wrong dates.
%
%   Unit frequency (FAME 'case') is the identity: O = 0.
    if isa(F, 'tse.Unit')
        O = int64(0);
        return
    end
    freqCode = tse.fame.freq_to_fame(F);
    O1 = local_ref_offset(F, freqCode, 2000);
    O2 = local_ref_offset(F, freqCode, 2010);
    if O1 ~= O2
        error('tseries:fame', ...
            ['FAME/tse period offset is not constant for %s (%d vs %d). The two ', ...
             'date systems disagree over this frequency (e.g. BDaily against a ', ...
             'holiday calendar, or a weekly end-day mismatch); FAME interop for ', ...
             'this frequency needs review before use.'], class(F), O1, O2);
    end
    O = O1;
end

function O = local_ref_offset(F, freqCode, yr)
    m0 = tse.MIT(F, yr, 1);              % period 1 of the reference year
    d  = tse.toDate(m0, 'end');          % a calendar day inside that period
    [y, mo, dy] = ymd(d);
    idx = tse.fame.CHLI.ddat(freqCode, y, mo, dy);
    O   = int64(idx) - int64(m0.value);
end

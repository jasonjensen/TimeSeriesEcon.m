function c = fame_constants()
%FAME_CONSTANTS  FAME CHLI integer constants used by the interop.  (private)
%
%   Values marked (confirmed) were read from the FAME.jl bindings and/or the
%   CRAN `fame` header; the rest are the standard FAME HLI values.  VALIDATE
%   the (std) ones against your installed hli.h -- especially the access
%   modes, which neither reference spelled out.
    persistent k
    if isempty(k)
        % --- database access modes (std; VALIDATE) ---
        k.HRMODE = 1;    % read
        k.HCMODE = 2;    % create
        k.HOMODE = 3;    % overwrite
        k.HUMODE = 4;    % update
        k.HSMODE = 5;    % shared

        % --- object classes ---
        k.HSERIE = 1;    % (confirmed) series
        k.HSCALA = 2;    % scalar

        % --- data types ---
        k.HUNDFT = 0;
        k.HNUMRC = 1;    % (confirmed) numeric  -> single
        k.HNAMEL = 2;    % namelist
        k.HBOOLN = 3;    % (confirmed) boolean  -> logical
        k.HSTRNG = 4;    % string
        k.HPRECN = 5;    % (confirmed) precision -> double
        k.HDATE  = 6;    % date -> tse.MIT

        % --- basis (day counting for daily/business series) ---
        k.HBSUND = 0;
        k.HBSDAY = 1;    % (confirmed)
        k.HBSBUS = 2;

        % --- observed (intra-period aggregation) ---
        k.HOBUND = 0;
        k.HOBBEG = 1;
        k.HOBEND = 2;
        k.HOBAVG = 3;    % (confirmed)
        k.HOBSUM = 4;
        k.HOBANN = 5;
        k.HOBFRM = 6;
        k.HOBHIG = 7;
        k.HOBLOW = 8;

        % --- status ---
        k.HSUCC  = 0;    % success

        % --- missing-value sentinels (extern globals in the CHLI; MATLAB
        %     cannot read them, so they are recorded here from their exact bit
        %     patterns).  All are finite, so equality comparison is exact.
        %     NaN maps to NC on write; any of NC/NA/ND maps to NaN on read.
        k.FPRCNC = typecast(uint64(5179139575771037696), 'double');   % precision NC
        k.FPRCNA = typecast(uint64(5179139580066004992), 'double');   % precision NA
        k.FPRCND = typecast(uint64(5179139584360972288), 'double');   % precision ND
        k.FNUMNC = typecast(uint32(2130706440),          'single');   % numeric   NC
        k.FNUMNA = typecast(uint32(2130706448),          'single');   % numeric   NA
        k.FNUMND = typecast(uint32(2130706456),          'single');   % numeric   ND
        % NaN maps to NC on write; any of NC/NA/ND maps to NaN on read.
        k.precision_missing = [k.FPRCNC, k.FPRCNA, k.FPRCND];
        k.numeric_missing   = [k.FNUMNC, k.FNUMNA, k.FNUMND];
    end
    c = k;
end

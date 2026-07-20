function diag_namelist()
%DIAG_NAMELIST  One-shot diagnostic for the FAME namelist round-trip failure.
%
%   Run:  diag_namelist
%
%   Writes a namelist three different ways and reports, at each step, the raw
%   CHLI status and what cfmnlen/cfmgtnl read back -- both in the SAME session
%   (before posting) and after a post/close/reopen.  This isolates whether the
%   failure is in cfmwtnl, in persistence, or in the read path, and whether the
%   FAME command interpreter (the mechanism the R `fame` package uses) works
%   where cfmwtnl does not.
%
%   Paste the entire printed report back.

    tse.fame.startup();                      % load the CHLI
    K = fame_constants();
    lib = tse.fame.CHLI.instance().libname;

    fprintf('\n==================== FAME namelist diagnostic ====================\n');
    fprintf('HNLALL=%d  HSCALA=%d  HNAMEL=%d  HUNDFX=%d\n\n', ...
        K.HNLALL, K.HSCALA, K.HNAMEL, K.HUNDFX);

    % --- helpers that call the CHLI directly and report the RAW status -------
    function s = raw(func, varargin)
        sp = libpointer('int32Ptr', int32(0));
        try
            calllib(lib, func, sp, varargin{:});
            s = double(sp.Value);
        catch e
            fprintf('   !! %s threw: %s\n', func, e.message);
            s = NaN;
        end
    end
    function [n, st] = nlen(dbkey, name, idx)
        lp = libpointer('int32Ptr', int32(-999));
        st = raw('cfmnlen', int32(dbkey), char(name), int32(idx), lp);
        n  = double(lp.Value);
    end
    function [str, n, st] = gtnl(dbkey, name, idx)
        [n, ~] = nlen(dbkey, name, idx);
        str = '';
        if n > 0
            bufp = libpointer('cstring', blanks(n + 1));
            op   = libpointer('int32Ptr', int32(0));
            st = raw('cfmgtnl', int32(dbkey), char(name), int32(idx), bufp, int32(n + 1), op);
            str = bufp.Value;
        else
            st = 0;
        end
    end
    function report(tag, dbkey, name)
        try
            info = tse.fame.CHLI.quick_info(dbkey, name);
            fprintf('   [%s] quick_info class=%d type=%d freq=%d first=%d last=%d\n', ...
                tag, info.class, info.type, info.freq, info.first, info.last);
        catch e
            fprintf('   [%s] quick_info threw: %s\n', tag, e.message);
        end
        [n, stL]      = nlen(dbkey, name, K.HNLALL);
        [str, ~, stG] = gtnl(dbkey, name, K.HNLALL);
        fprintf('   [%s] cfmnlen(HNLALL) status=%g len=%g  cfmgtnl status=%g str="%s"\n', ...
            tag, stL, n, stG, str);
    end

    % ---------------------------------------------------------------------
    % CASE 1: cfmnwob + cfmwtnl  (exactly the FAME.jl path we ship)
    % ---------------------------------------------------------------------
    f1 = [tempname '.db'];
    db = tse.fame.CHLI.opendb(f1, K.HOMODE);
    name = 'MYLIST';
    fprintf('CASE 1  cfmnwob + cfmwtnl "{GDP,CPI,RATE}" (shipped path)\n');
    stC = raw('cfmnwob', int32(db), char(name), int32(K.HSCALA), int32(K.HUNDFX), ...
              int32(K.HNAMEL), int32(K.HBSDAY), int32(K.HOBUND));
    fprintf('   cfmnwob status=%g\n', stC);
    stW = raw('cfmwtnl', int32(db), char(name), int32(K.HNLALL), '{GDP,CPI,RATE}');
    fprintf('   cfmwtnl status=%g  (value "{GDP,CPI,RATE}")\n', stW);
    report('same-session', db, name);
    tse.fame.CHLI.postdb(db);
    tse.fame.CHLI.closedb(db);
    db = tse.fame.CHLI.opendb(f1, K.HRMODE);
    report('after-reopen', db, name);
    tse.fame.CHLI.closedb(db);
    delete(f1);
    fprintf('\n');

    % ---------------------------------------------------------------------
    % CASE 2: same, but sweep the `index` argument (Perl port calls arg 4
    %         `index`, not `mode`; maybe write wants a value other than -1)
    % ---------------------------------------------------------------------
    fprintf('CASE 2  cfmwtnl index sweep (0, 1, -1) then read with HNLALL\n');
    for idx = [0, 1, -1]
        f2 = [tempname '.db'];
        db = tse.fame.CHLI.opendb(f2, K.HOMODE);
        raw('cfmnwob', int32(db), char(name), int32(K.HSCALA), int32(K.HUNDFX), ...
            int32(K.HNAMEL), int32(K.HBSDAY), int32(K.HOBUND));
        stW = raw('cfmwtnl', int32(db), char(name), int32(idx), '{GDP,CPI,RATE}');
        [n, ~] = nlen(db, name, K.HNLALL);
        fprintf('   index=%3d  cfmwtnl status=%g  -> cfmnlen(HNLALL) len=%g\n', idx, stW, n);
        tse.fame.CHLI.closedb(db);
        delete(f2);
    end
    fprintf('\n');

    % ---------------------------------------------------------------------
    % CASE 3: FAME command interpreter (the R `fame` package's mechanism)
    % ---------------------------------------------------------------------
    fprintf('CASE 3  cfmfame command interpreter: scalar db''NAME:namelist = {...}\n');
    f3 = [tempname '.db'];
    ok3 = true;
    stO = raw('cfmfame', sprintf('open <access overwrite> "%s" as diagdb', f3));
    fprintf('   open command status=%g\n', stO);
    if isnan(stO), ok3 = false; end
    if ok3
        cmd = sprintf('scalar diagdb''%s:namelist = {GDP,CPI,RATE}', name);
        stCmd = raw('cfmfame', cmd);
        fprintf('   assign command status=%g  cmd="%s"\n', stCmd, cmd);
        raw('cfmfame', 'post diagdb');
        raw('cfmfame', 'close diagdb');
        db = tse.fame.CHLI.opendb(f3, K.HRMODE);
        report('cmd-reopen', db, name);
        tse.fame.CHLI.closedb(db);
    end
    if exist(f3, 'file'), delete(f3); end

    fprintf('==================================================================\n\n');
end

function [methodinfo, structs, enuminfo, ThunkLibName] = hli_proto()
%HLI_PROTO  MATLAB loadlibrary prototype for the FAME HLI shared library.
%
%   Committed into the repo so that regular users do NOT need a C compiler,
%   the fame.h header, or the FAME environment variable to load libhli.
%   They only need libhli reachable from the process (via LD_LIBRARY_PATH /
%   PATH), the same way FAME's own CLI expects it.
%
%   Maintainers regenerate this from $FAME/hli(/64)/fame.h via
%   tse.fame.regenerate_proto -- see the docstring there for the workflow.
%
%   The set of prototypes here mirrors the CRAN R `fame` package's fame.h
%   header (a purpose-built subset of the full FAME HLI covering the
%   read/write/list workflow).  cfmgtsts (STRING series read, needs a
%   char** buffer) is intentionally omitted -- STRING series are out of
%   scope for tse.fame; add it when needed.
%
%   Type conventions used below:
%       int      -> int32              (scalar input)
%       int*     -> int32Ptr           (scalar or short-array output)
%       char*    -> cstring            (input or caller-preallocated output)
%       void*    -> voidPtr            (caller allocates and setdatatype)
%       float(*) -> single, singlePtr
%       double(*)-> double, doublePtr
%
%   All entry points use the cdecl calling convention.
    ival = {cell(1, 0)};
    enuminfo     = [];
    structs      = [];
    ThunkLibName = [];
    fcns = struct('name', ival, 'calltype', ival, 'LHS', ival, 'RHS', ival);

    i = 0;

    % --- init / shutdown -------------------------------------------------
    i = i + 1;
    fcns.name{i} = 'cfmini';    fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr'};

    i = i + 1;
    fcns.name{i} = 'cfmfin';    fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr'};

    i = i + 1;
    fcns.name{i} = 'cfmfame';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'cstring'};

    i = i + 1;
    fcns.name{i} = 'cfmferr';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'cstring'};

    % --- database open / close ------------------------------------------
    i = i + 1;
    fcns.name{i} = 'cfmopdb';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32Ptr', 'cstring', 'int32'};

    i = i + 1;
    fcns.name{i} = 'cfmopdc';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32Ptr', 'cstring', 'int32', 'int32'};

    i = i + 1;
    fcns.name{i} = 'cfmopwk';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32Ptr'};

    i = i + 1;
    fcns.name{i} = 'cfmopcn';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32Ptr', 'cstring', 'cstring', 'cstring', 'cstring'};

    i = i + 1;
    fcns.name{i} = 'cfmcldb';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32'};

    i = i + 1;
    fcns.name{i} = 'cfmclcn';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32'};

    i = i + 1;
    fcns.name{i} = 'cfmgcid';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'int32Ptr'};

    % --- dates: index <-> year/month/day/subperiod ----------------------
    i = i + 1;
    fcns.name{i} = 'cfmdatd';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'int32', 'int32Ptr', 'int32Ptr', 'int32Ptr'};

    i = i + 1;
    fcns.name{i} = 'cfmdatt';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'int32', 'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr'};

    i = i + 1;
    fcns.name{i} = 'cfmddat';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'int32Ptr', 'int32', 'int32', 'int32'};

    % --- object create / delete / rename --------------------------------
    i = i + 1;
    fcns.name{i} = 'cfmnwob';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'cstring', 'int32', 'int32', 'int32', 'int32', 'int32'};

    i = i + 1;
    fcns.name{i} = 'cfmdlob';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'cstring'};

    i = i + 1;
    fcns.name{i} = 'cfmrnob';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'cstring', 'cstring'};

    % --- wildcard iteration ---------------------------------------------
    i = i + 1;
    fcns.name{i} = 'cfminwc';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'cstring'};

    i = i + 1;
    fcns.name{i} = 'cfmnxwc';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'cstring', 'int32Ptr', 'int32Ptr', 'int32Ptr'};

    % --- description / documentation / event / missing setters ---------
    i = i + 1;
    fcns.name{i} = 'cfmsdes';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'cstring', 'cstring'};

    i = i + 1;
    fcns.name{i} = 'cfmsdoc';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'cstring', 'cstring'};

    i = i + 1;
    fcns.name{i} = 'cfmrmev';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'cstring', 'cstring', 'int32', 'cstring'};

    i = i + 1;
    fcns.name{i} = 'cfmsbm';    fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'int32', 'int32', 'int32Ptr'};

    i = i + 1;
    fcns.name{i} = 'cfmsnm';    fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'single', 'single', 'single', 'singlePtr'};

    i = i + 1;
    fcns.name{i} = 'cfmspm';    fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'double', 'double', 'double', 'doublePtr'};

    % --- range and metadata queries -------------------------------------
    i = i + 1;
    fcns.name{i} = 'cfmfrng';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32', 'int32'};

    i = i + 1;
    fcns.name{i} = 'cfmsrng';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr'};

    i = i + 1;
    fcns.name{i} = 'cfmwhat';   fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = { ...
        'int32Ptr', 'int32', 'cstring', ...
        'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr', ...
        'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr', ...
        'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr', 'int32Ptr', ...
        'cstring', 'cstring'};

    % --- bulk read / write of series values (the _f names are the real
    %     symbols; the macros cfmrrng / cfmwrng in the header just forward). ---
    i = i + 1;
    fcns.name{i} = 'cfmrrng_f'; fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'cstring', 'int32Ptr', 'voidPtr', 'int32', 'voidPtr'};

    i = i + 1;
    fcns.name{i} = 'cfmwrng_f'; fcns.calltype{i} = 'cdecl';
    fcns.LHS{i}  = '';          fcns.RHS{i}      = {'int32Ptr', 'int32', 'cstring', 'int32Ptr', 'voidPtr', 'int32', 'voidPtr'};

    methodinfo = fcns;
end

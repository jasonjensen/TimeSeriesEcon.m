/*
 * chli.h -- minimal MATLAB loadlibrary prototype header for the FAME CHLI.
 *
 * Hand-authored from the Bank of Canada FAME.jl bindings and the CRAN `fame`
 * R package header (https://github.com/cran/fame/blob/master/src/fame.h).
 * Only the functions TimeSeriesEcon.m calls are declared.  The K&R DLLENTRY /
 * A(()) wrappers of the original header are resolved to plain ANSI prototypes
 * here so MATLAB's loadlibrary can parse them.
 *
 * FAME CHLI calling convention: every function is void and reports success
 * through its FIRST argument, `int *status` (0 == HSUCC).  Object and date
 * indices are 32-bit `int` in this (classic) interface.
 *
 * VALIDATE against the CHLI actually installed on your machine before relying
 * on this: in particular the range read/write symbol names (this header uses
 * the classic cfmrrng / cfmwrng; the CRAN header exports cfmrrng_f / cfmwrng_f)
 * and the exact argument count of cfmwhat.
 */

/* ---- library lifecycle ---- */
void cfmini(int *status);
void cfmfin(int *status);

/* ---- error text ---- */
void cfmferr(int *status, char *message);

/* ---- databases ---- */
void cfmopdb(int *status, int *dbkey, char *dbname, int mode);
void cfmopwk(int *status, int *dbkey);
void cfmpodb(int *status, int dbkey);
void cfmcldb(int *status, int dbkey);

/* ---- objects ---- */
void cfmdlob(int *status, int dbkey, char *objname);
void cfmnwob(int *status, int dbkey, char *objname,
             int objclass, int freq, int type, int basis, int observed);
void cfmwhat(int *status, int dbkey, char *objname,
             int *objclass, int *type, int *freq, int *basis, int *observed,
             int *fyear, int *fperiod, int *lyear, int *lperiod,
             int *cyear, int *cmonth, int *cday, int *gyear, int *gmonth,
             int *gday, char *desc, char *doc);

/* ---- ranges ---- */
void cfmsrng(int *status, int freq,
             int *syear, int *speriod, int *eyear, int *eperiod,
             int *range, int *numobs);

/* ---- series data ---- */
void cfmrrng(int *status, int dbkey, char *objname,
             const int *range, void *data, int tmiss, void *misval);
void cfmwrng(int *status, int dbkey, char *objname,
             const int *range, void *data, int tmiss, void *misval);

/* ---- date conversion (calendar year/month/day based) ---- */
void cfmddat(int *status, int freq, int *date, int year, int month, int day);
void cfmdatd(int *status, int freq, int date, int *year, int *month, int *day);

/* ---- FAME command execution ---- */
void cfmfame(int *status, char *command);

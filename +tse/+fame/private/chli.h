/*
 * chli.h -- reference notes on the FAME CHLI signatures TimeSeriesEcon.m uses.
 *
 * NOTE: this file is documentation only.  tse.fame.CHLI.load points MATLAB's
 * loadlibrary at the real FAME header ($FAME/hli/hli.h), so the signatures and
 * the fame_range struct below come from there -- they are recorded here so the
 * MATLAB wrappers can be read without the vendor header at hand.
 *
 * Two calling conventions are in play:
 *   - classic cfm* : void, status reported through the FIRST argument (int*).
 *   - modern fame_*: int return value is the status; no status argument.
 *
 * The interop follows FAME.jl: classic for the database lifecycle and object
 * creation, modern for metadata, date<->index conversion, and series data.
 */

/* ==== classic cfm* (status is the first int* argument) ==================== */

/* library lifecycle + error text */
void cfmini(int *status);
void cfmfin(int *status);
void cfmferr(int *status, char *message);

/* databases */
void cfmopdb(int *status, int *dbkey, char *dbname, int mode);
void cfmopwk(int *status, int *dbkey);
void cfmpodb(int *status, int dbkey);
void cfmcldb(int *status, int dbkey);

/* object creation / deletion */
void cfmnwob(int *status, int dbkey, char *objname,
             int objclass, int freq, int type, int basis, int observed);
void cfmdlob(int *status, int dbkey, char *objname);

/* ==== modern fame_* (int return value is the status) ===================== */

/* fame_index is a 64-bit index; fame_freq/fame_type are int. */
typedef struct { int r_freq; long long r_start; long long r_end; } fame_range;

int fame_quick_info(int dbkey, const char *oname, int *oclass, int *type,
                    int *freq, long long *findex, long long *lindex);
int fame_year_period_to_index(int freq, long long *date, int year, int period);
int fame_index_to_year_period(int freq, long long date, int *year, int *period);

int fame_get_precisions (int dbkey, const char *objnam, const fame_range *range, double *valary);
int fame_get_numerics   (int dbkey, const char *objnam, const fame_range *range, float  *valary);
int fame_write_precisions(int dbkey, const char *objnam, const fame_range *range, const double *valary);
int fame_write_numerics  (int dbkey, const char *objnam, const fame_range *range, const float  *valary);

/* Later steps: fame_get/write_booleans/strings/dates, fame_*_wildcard. */

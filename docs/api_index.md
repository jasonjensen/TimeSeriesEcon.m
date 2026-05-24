# API index

A flat listing of the public surface of the `tse` package. In MATLAB you can
also run `help tse` for the same overview, or `help tse.<name>` for any item.

## Classes

| Name | Page |
|------|------|
| `tse.Frequency`, `tse.CalendarFrequency`, `tse.YPFrequency` (abstract) | [Frequencies](reference/frequencies.md) |
| `tse.Unit`, `tse.Yearly`, `tse.HalfYearly`, `tse.Quarterly`, `tse.Monthly`, `tse.Weekly`, `tse.Daily`, `tse.BDaily` | [Frequencies](reference/frequencies.md) |
| `tse.MIT`, `tse.Duration`, `tse.MITRange` | [MIT & MITRange](reference/mit.md) |
| `tse.TSeries` | [TSeries](reference/tseries.md) |
| `tse.MVTSeries` | [MVTSeries](reference/mvtseries.md) |

## MIT constructors

`tse.qq`, `tse.mm`, `tse.yy`, `tse.day`, `tse.bday`, `tse.week`,
`tse.weekly_from_iso` — see [MIT & MITRange](reference/mit.md).

## Inspection

`tse.frequencyof`, `tse.year`, `tse.period`, `tse.mit2yp`, `tse.ppy`,
`tse.endperiod`, `tse.sanitize_frequency`, `tse.firstdate`, `tse.lastdate`,
`tse.rangeof`, `tse.rangeof_span`, `tse.toDate`, `tse.LinearIndices`.

## Frequency predicates

`tse.isyearly`, `tse.ishalfyearly`, `tse.isquarterly`, `tse.ismonthly`,
`tse.isweekly`, `tse.isdaily`, `tse.isbdaily`, `tse.istypenan`.

## Transforms & helpers

| Function | Page |
|----------|------|
| `tse.fconvert` | [Frequency conversion](reference/fconvert.md) |
| `tse.undiff` | [Math](reference/math.md) |
| `tse.lookup` | [Indexing](reference/indexing.md) |
| `tse.overlay`, `tse.compare`, `tse.reindex` | [Misc helpers](reference/various.md) |
| `tse.strip_ts`, `tse.extend_series`, `tse.trim_series` | [Math](reference/math.md) / [fconvert](reference/fconvert.md) |
| `tse.rec` | [Recursive](reference/recursive.md) |
| `tse.cleanedvalues`, `tse.typenan` | [Statistics](reference/stats.md) |

## TSeries / MVTSeries methods

`shift`, `lag`, `lead`, `cumsum`, `diff`, `pct`, `apct`, `ytypct`,
`moving_average`, `moving_sum`, `moving`, `sum`, `mean`, `std`, `var`, `median`,
`min`, `max`, `prod`, `any`, `all`, `plot`, `compare`, `rangeof`, `firstdate`,
`lastdate`, `frequencyof`, `columns` (MVTSeries). See
[TSeries](reference/tseries.md) and [MVTSeries](reference/mvtseries.md).

## Options & holidays

`tse.getoption`, `tse.setoption`, `tse.set_holidays_map`,
`tse.get_holidays_options`, `tse.clear_holidays_map` — see
[Options](reference/options.md).

# Frequencies

A `Frequency` describes the spacing between observations. You rarely construct
these directly — the `MIT` constructor functions (`qq`, `mm`, `yy`, `day`,
`bday`, `week`) produce the right frequency for you — but the classes are public
for explicit use and for the variant end-month / end-day forms.

## Class hierarchy

```
Frequency (abstract)
├── Unit                         non-calendar, just counts observations
├── CalendarFrequency (abstract)
│   ├── Daily                    every calendar day        (ppy 365*)
│   ├── BDaily                   business days, Mon–Fri     (ppy 260*)
│   ├── Weekly(endDay)           weeks ending endDay 1..7   (ppy 52*)
│   └── YPFrequency (abstract)   year-period frequencies
│       ├── Yearly(endMonth)     1 period/year,  endMonth 1..12 (default 12)
│       ├── HalfYearly(endMonth) 2 periods/year, endMonth 1..6  (default 6)
│       ├── Quarterly(endMonth)  4 periods/year, endMonth 1..3  (default 3)
│       └── Monthly              12 periods/year
```

`*` `ppy` (periods per year) returns the hardcoded sentinels 365 / 260 / 52 for
Daily / BDaily / Weekly, matching the Julia upstream.

## Constructors

| Call | Meaning |
|------|---------|
| `tse.Yearly()` / `tse.Yearly(m)` | Yearly, default end month 12 (or `m`) |
| `tse.HalfYearly()` / `tse.HalfYearly(m)` | HalfYearly, default end month 6 |
| `tse.Quarterly()` / `tse.Quarterly(m)` | Quarterly, default end month 3 |
| `tse.Monthly()` | Monthly |
| `tse.Weekly()` / `tse.Weekly(d)` | Weekly, default end day 7 (Sunday) |
| `tse.Daily()`, `tse.BDaily()`, `tse.Unit()` | the fixed frequencies |

Two frequencies are equal when they are the same class with the same end
period: `tse.Quarterly() == tse.Quarterly(3)` is `true`.

## Inspection

| Function | Description |
|----------|-------------|
| `frequencyof(x)` | The `Frequency` object of an MIT / Duration / range / series |
| `ppy(x)` | Periods per year (accepts an MIT or a Frequency) |
| `endperiod(x)` | End-month (YP) or end-day (Weekly); 1 otherwise |
| `sanitize_frequency(name)` | Canonical `Frequency` from a class name or instance |
| `isyearly`, `ishalfyearly`, `isquarterly`, `ismonthly`, `isweekly`, `isdaily`, `isbdaily` | Frequency predicates |

```matlab
import tse.*
frequencyof(qq(2020, 1))     % a Quarterly frequency
ppy(qq(2020, 1))             % 4
endperiod(Quarterly())       % 3
isquarterly(qq(2020, 1))     % true
```

!!! info "Julia ↔ MATLAB"
    Julia's parametric `Quarterly{3}` becomes an `endPeriod` constructor
    argument, `Quarterly(3)`. There is no `Frequency` *type* value to pass
    around the way Julia passes `Quarterly` — pass an instance (`Quarterly()`),
    a class-name string (`'Quarterly'`), or the integer code.

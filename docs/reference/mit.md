# MIT and MITRange

`MIT` is a moment in time of a given frequency. Arithmetic between two `MIT`s of
the same frequency yields a `Duration`; `MIT + Duration` (or `MIT + int` as a
shorthand) yields a new `MIT`. `MITRange` is the inclusive, evenly-spaced range —
the analogue of Julia's `first:last`.

## Constructing an MIT

| Function | Result |
|----------|--------|
| `tse.qq(y, p)` | Quarterly MIT, e.g. `qq(2020,1)` → `2020Q1` |
| `tse.mm(y, p)` | Monthly MIT |
| `tse.yy(y)` | Yearly MIT |
| `tse.day(d)` | Daily MIT from a `datetime` or `'yyyy-MM-dd'` string |
| `tse.bday(d, 'bias', b)` | Business-daily MIT (`b` = `strict`/`previous`/`next`/`nearest`) |
| `tse.week(d, endDay)` | Weekly MIT (default `endDay` 7) |
| `tse.weekly_from_iso(y, p)` | Weekly{7} MIT from ISO (year, week) |
| `tse.MIT(F, value)` | low-level: frequency object + integer offset |
| `tse.MIT(F, y, p)` | low-level: frequency + (year, period), e.g. `MIT(HalfYearly(), 2022, 1)` |

`day`, `bday` accept two date strings to build a range directly:
`tse.day('2022-01-01', '2022-01-31')`.

## MIT operations

| Expression | Result |
|------------|--------|
| `a - b` (two MITs) | `Duration` (same frequency required) |
| `m + k` / `m - k` (integer `k`) | `MIT` shifted by `k` periods |
| `m + d` (Duration) | `MIT` |
| `a < b`, `a == b`, … | comparisons (same frequency) |
| `a : b` / `a : step : b` | `MITRange` (colon is overloaded on MIT) |
| `frequencyof(m)`, `year(m)`, `period(m)`, `mit2yp(m)` | inspection |
| `toDate(m[, ref])` | calendar date of a calendar-frequency MIT (`ref` = `'begin'`/`'end'`) |
| `int64(m)` / `double(m)` | underlying integer offset |

```matlab
import tse.*
m = qq(2020, 1);
m + 4                        % 2021Q1
qq(2001, 2) - qq(2000, 1)    % Duration of 5 quarters
mit2yp(mm(2020, 7))          % [2020 7]
```

## MITRange

| Call | Meaning |
|------|---------|
| `tse.MITRange(a, b)` | inclusive unit-step range |
| `tse.MITRange(a, step, b)` | step range (`step` is a nonzero integer; negative walks backward) |
| `a:b`, `a:step:b` | same, via the overloaded colon |

| Operation | Description |
|-----------|-------------|
| `length(rng)` / `numel(rng)` | number of elements |
| `rng(k)` | the k-th MIT |
| `first(rng)` / `last(rng)` | endpoints |
| `collect(rng)` | the MITs as an array (for `for m = collect(rng)`) |
| `rng + k`, `rng - k` | shift the whole range |
| `intersect(a, b)`, `union(a, b)` | set operations on unit ranges |
| `ismember(rng, m)` | membership test |

```matlab
rng = MITRange(qq(2020, 1), qq(2021, 4));   % or qq(2020,1):qq(2021,4)
length(rng)        % 8
collect(rng(1:3))  % first three MITs
```

!!! info "Julia ↔ MATLAB"
    Julia's `2020Q1` literal → `qq(2020, 1)`; `2020Q1:2021Q4` →
    `MITRange(qq(2020,1), qq(2021,4))` or the overloaded colon. The step is the
    *middle* argument: `MITRange(a, step, b)` (Julia writes `a:step:b`).
    `MIT == int` compares the underlying offset.

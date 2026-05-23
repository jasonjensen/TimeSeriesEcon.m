# Frequency model

## Parametric types become constructor arguments

Julia encodes the end-of-period in the *type*: `Quarterly{3}`, `Yearly{12}`,
`Weekly{7}`. MATLAB has no value-parameterised types, so the end period is an
ordinary constructor argument and an immutable property:

```matlab
tse.Quarterly()      % endPeriod = 3 (default)
tse.Quarterly(2)     % endPeriod = 2
tse.Yearly(11)       % fiscal year ending November
tse.Weekly(6)        % weeks ending Saturday
```

Two frequencies are equal when they are the same class with the same
`endPeriod`, so `tse.Quarterly() == tse.Quarterly(3)` is `true`. This replaces
Julia's `Quarterly{3} == Quarterly{3}` parametric-type equality.

## Why no `2020Q1` literal

Julia gets `2020Q1` from a numeric-literal suffix; Python deliberately avoids
operator-overload sugar. MATLAB simply *has* no user-defined literals, so the
constructor functions `qq` / `mm` / `yy` (and `day` / `bday` / `week` for
calendar dates) are the only spelling. This is also why `MIT` arithmetic with a
bare integer is interpreted as a `Duration` in the MIT's own frequency
(`qq(2000,1) + 6`), matching Julia's `2000Q1 + 6` shorthand.

## Internal integer frequency codes

For speed, `MIT` / `Duration` / `MITRange` / `TSeries` / `MVTSeries` store the
frequency as an `int32` code rather than a `Frequency` object, and reconstruct
the object only when needed (display, public `frequencyof`). The encoding (see
`+tse/private/freq2int.m` / `int2freq.m`):

| Frequency | Code |
|-----------|------|
| `Unit` | 11 |
| `Daily` | 12 |
| `BDaily` | 13 |
| `Weekly(ep)` | 16 + ep |
| `Monthly` | 32 |
| `Quarterly(ep)` | 64 + ep |
| `HalfYearly(ep)` | 128 + ep |
| `Yearly(ep)` | 256 + ep |

This keeps frequency comparisons and constructor dispatch to plain integer
operations on the hot path, which is the single biggest performance lever in a
class-heavy MATLAB design.

## `MIT == int`

Comparing an `MIT` to a plain integer compares the underlying offset only, so a
quarterly and a monthly MIT with the same internal value are *not* confused with
each other when both are compared to the same integer — use `frequencyof` to be
explicit, and `int64(m)` to extract the raw offset.

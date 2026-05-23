# Recursive (rec)

`rec` evaluates a recurrence over an `MITRange`, committing each write before the
next step runs — the function equivalent of Julia's `@rec` macro.

```matlab
t = tse.rec(rng, t, fn)
```

- `rng` — an `MITRange` (use a negative step to run backward, i.e. backcasting).
- `t` — the target `TSeries` (seed values must already be present).
- `fn` — a two-argument function handle, in one of two forms:
    - `@(s, mit)` — receives the current `TSeries` and the current `MIT`; index
      with `s(mit-1)` etc. (the general form).
    - `@(v, i)` — receives the raw values vector and an integer index; index with
      `v(i-1)` (a faster form for tight AR-style loops with no MIT arithmetic).

Because `TSeries` is a value type, **reassign the result**: `t = rec(rng, t, fn)`.

## Examples

AR(1) with a steady state and an impulse:

```matlab
import tse.*
a_ss = 1.0; rho = 0.6;
a = TSeries(MITRange(qq(2020,1), qq(2022,1)), a_ss);
a(a.firstdate) = a(a.firstdate) + 0.1;            % impulse
a = rec(rangeof(a, 'drop', 1), a, ...
        @(s, t) (1 - rho) * a_ss + rho * s(t - 1));
```

Fibonacci (fast values form):

```matlab
f = TSeries(MIT(Unit(), 1), [1; 1; zeros(8,1)]);
f = rec(MITRange(MIT(Unit(),3), MIT(Unit(),10)), f, @(v, i) v(i-1) + v(i-2));
```

Backcasting with a reversed range:

```matlab
g = 0.05;
back = TSeries(MITRange(qq(2020,1), qq(2022,4)), 0.0);
back(back.lastdate) = 1.0;
back = rec(MITRange(back.lastdate - 1, -1, back.firstdate), back, ...
           @(s, t) s(t + 1) - g);
```

The `rangeof(x, 'drop', k)` helper is the canonical way to build the recurrence
range: `'drop', 1` skips the first period (so `s(t-1)` is always in range),
`'drop', -1` skips the last.

!!! info "Julia ↔ MATLAB"
    Julia's parse-time `@rec rng a[t] = …` becomes the higher-order
    `a = rec(rng, a, @(s,t) …)`. Semantics match (each step commits before the
    next). There is no `rec_linear` (the Python Cython narrowing); use the
    general `rec`, or `undiff` for `a[t] = a[t-1] + c`. For multi-target
    recurrences write an explicit `for t = collect(rng)` loop.

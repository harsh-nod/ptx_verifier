# volta_spec

The textual spec language: a math description of what a kernel should
compute. `volta verify` checks a kernel against one.

```
# relu.spec
dim N;
array x[N];
array out[N];
out[i] = max(x[i], 0);
```

```
dim M; dim N; dim K;
param alpha;
array A[M, K]; array B[K, N]; array C[M, N];
C[i, j] = alpha * sum(k in 0..K, A[i, k] * B[k, j]);
```

## Pipeline

```
.spec text ──lex.rs──► tokens ──parse.rs──► ParsedSpec ──instantiate.rs──► (SpecEnv, Vec<OutputSpec>)
                                            (named dims)  (dim values,        │
                                                           e.g. --dim N=128)  ▼
                                                              spec.rs: unfold ──► SymbolicOutputs
```

- **`lex.rs`**: ASCII-only tokenizer.
- **`parse.rs`**: `parse_spec` produces a `ParsedSpec` (`ast.rs`):
  - `dim NAME;`: an integer size, given a value at instantiation;
  - `param NAME;`: a symbolic scalar, matched to the kernel's symbolic float
    parameter of the same name;
  - `array NAME[d0, d1, ...] [padded];`: an array's shape. With `padded`, an
    out-of-shape read is 0 (convolution borders) instead of an error;
  - `NAME[i, j, ...] = expr;`: an output equation. Bodies use `+ - * /`,
    unary `-`, builtins (`exp`, `log`, `sqrt`, `abs`, `sign`, `min`, `max`)
    and `bit_sign(word, bit_index)`, plus reductions `sum(k in 0..K, e)` / `max(k in 0..K, e)`. Bodies parse
    directly into `SpecExpr` (`spec.rs`).
- **`instantiate.rs`**: `instantiate(parsed, dims)` resolves every dim to a
  concrete value, producing the `SpecEnv` and `OutputSpec`s `unfold` takes.
  Parsing and instantiation are separate, so one parsed spec serves many sizes.
- **`spec.rs`**: the mathematical form of a spec: `OutputSpec` (an output
  array as a formula `SpecExpr` over other arrays, with `sum`/`max`
  reductions), `Shape` and `SpecEnv`. `unfold` expands every output element
  into a `volta_expr::SymbolicOutputs`, using the same arena constructors the
  interpreter uses. The root re-exports these types and `unfold`
  (`volta_spec::unfold`).

Each spec output must be declared `out` or `inout` in the kernel's launch
config. The unfolded spec then plays the role of the reference kernel in the
equivalence check.

An output array has exactly one equation. Array shape products must fit the
64-bit flat index domain; overflow is an error before any output is unfolded.
`output_index_mismatch` checks complete written indices against the dense spec
shape before either interface samples expressions. Sampling preserves the full
required element count.

Depends on `volta_common` (spans, errors) and `volta_expr`.

## Packed integer words

`bit_sign(word, bit_index)` returns `+1` when the selected bit of an integer
word is one, otherwise `-1`. Positions refer to the low 32 bits; they must
resolve to `0..31` during unfolding, including positions using bound variables.
The word remains symbolic. The builtin lowers independently to logical right
shift, AND with one, comparison against zero and selection of `+1`/`-1`.
It does not reinterpret floating-point storage or restrict input words to lane IDs.

```text
dim WORDS; dim K; dim N;
array packed[WORDS, N]; array a[K]; array out[N];
out[j] = sum(k in 0..K, a[k] * bit_sign(packed[k / 32, j], k % 32));
```

Integer index expressions support `+`, `-`, `*`, `/`, `%` and parentheses.
Division truncates toward zero and remainder has the dividend's sign. Division
by zero, overflow, unresolved names and invalid bit positions are errors during
unfolding. `/` in a value expression retains mathematical division; `%` is only
part of concrete index syntax. Array bounds remain checked after index evaluation.

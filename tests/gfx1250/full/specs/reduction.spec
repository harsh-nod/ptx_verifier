// One complete original CTA tile; the F32 output is also an input.
// This does not assert inter-CTA accumulation or whole-grid race freedom.
dim R; dim TILE; array x[TILE]; array output[R]; output[r] = output[r] + sum(k in 0..TILE,x[k]);

dim R;
dim C;
array x[R, C];
array out[R, C];
out[r, c] = exp(x[r, c] - max(k in 0..C, x[r, k]))
          / sum(k in 0..C, exp(x[r, k] - max(j in 0..C, x[r, j])));

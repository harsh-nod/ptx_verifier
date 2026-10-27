// Inputs are the builtin's lane-packed A and B fragments, not row-major A.
// A[k,row] lives in lane k*16+row; four C values are contiguous per lane.
dim K;
dim M;
dim N;
dim G;
dim C;
array a[K, M];
array b[K, N];
array out[G, N, C];
out[g, j, c] = sum(k in 0..K, a[k, 4*g + c] * b[k, j]);

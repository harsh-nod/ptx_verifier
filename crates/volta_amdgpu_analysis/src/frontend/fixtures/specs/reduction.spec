// One selected tile (workgroup x=0,y=0). Existing output is an input symbol.
// Inter-workgroup atomic accumulation is not established by this scoped spec.
dim R;
dim N;
dim TILE;
array x[R, N];
array out[R];
out[r] = out[r] + sum(k in 0..TILE, x[r, k]);

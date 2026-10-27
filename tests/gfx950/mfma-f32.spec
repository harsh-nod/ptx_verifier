dim K;
dim N;
dim G;
dim R;
array a[K, N];
array b[K, N];
array out[G, N, R];
out[g, j, r] = sum(k in 0..K, a[k, 4*g+r] * b[k, j]);

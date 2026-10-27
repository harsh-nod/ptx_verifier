// Bound scalar globals and the exact initialized2,3,5,7 constant table.
dim N; dim BOUND; dim BIAS;
array out[N];
out[i] = BOUND+BIAS+2+i+max(i-1,0);

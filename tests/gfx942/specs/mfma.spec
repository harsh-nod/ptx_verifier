// Actual lane-packed A/B ABI. GROUPS4 with ITEMS1/4 gives K4/K16.
dim GROUPS; dim M; dim N; dim ITEMS; dim G; dim C;
array a[GROUPS,M,ITEMS]; array b[GROUPS,N,ITEMS];
array out[G,N,C];
out[g,j,c] = sum(k in 0..GROUPS, sum(t in 0..ITEMS, a[k,4*g+c,t] * b[k,j,t]));

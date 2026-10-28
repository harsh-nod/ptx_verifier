// Public gfx1250 lane input groups and C/D row groups, full 256 outputs.
dim GROUPS; dim M; dim N; dim ITEMS; dim G; dim C;
array a[GROUPS,M,ITEMS]; array b[GROUPS,N,ITEMS]; array out[G,N,C];
out[g,j,c]=sum(k in 0..GROUPS,sum(t in 0..ITEMS,a[k,8*g+c,t]*b[k,j,t]));

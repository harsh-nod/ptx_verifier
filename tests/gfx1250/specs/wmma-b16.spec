// K32 is split into 8-element blocks interleaved between two lane groups.
dim GROUPS; dim M; dim N; dim BLOCKS; dim ITEMS; dim G; dim C;
array a[GROUPS,M,BLOCKS,ITEMS]; array b[GROUPS,N,BLOCKS,ITEMS]; array out[G,N,C];
out[g,j,c]=sum(k in 0..GROUPS,sum(z in 0..BLOCKS,sum(t in 0..ITEMS,a[k,8*g+c,z,t]*b[k,j,z,t])));

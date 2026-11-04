dim WAVES; dim LANES;
array x[WAVES,LANES]; array out[WAVES];
out[w] = sum(l in 0..LANES, x[w,l]);

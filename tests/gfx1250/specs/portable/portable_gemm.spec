dim M; dim N; dim K; array a[M,K]; array b[K,N]; array out[M,N]; out[i,j]=sum(k in 0..K,a[i,k]*b[k,j]);

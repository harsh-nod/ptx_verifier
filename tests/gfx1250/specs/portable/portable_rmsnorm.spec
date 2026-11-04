dim R; dim N; array x[R,N]; array weight[R,N]; array out[R,N]; out[r,i]=x[r,i]*weight[r,i]/sqrt(sum(k in 0..N,x[r,k]*x[r,k])/N+0.0000009999999974752427);

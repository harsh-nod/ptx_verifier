// Exact decoded native F32 epsilon; arithmetic follows Volta's real-number model.
dim R; dim N; array x[R,N]; array weight[R,N]; array output[R,N];
output[r,i] = x[r,i]*weight[r,i]/sqrt(sum(k in 0..N,x[r,k]*x[r,k])/N+0.0000009999999974752427);

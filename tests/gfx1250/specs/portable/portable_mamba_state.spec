dim T; dim PITCH; dim M; dim N; array x[T,PITCH]; array b[T,PITCH]; array dt[T]; array da[T]; array states[M,N]; states[i,j]=sum(t in 0..T,x[t,i]*b[t,j]*dt[t]*exp(min(da[T-1]-da[t],0)));

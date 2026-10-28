dim Q; dim T; dim D;
array q[Q,D]; array k[T,D]; array v[T,D]; array out[Q,D];
out[i,d]=sum(t in 0..T,(exp(sum(j in 0..D,q[i,j]*k[t,j])/8)/sum(s in 0..T,exp(sum(j in 0..D,q[i,j]*k[s,j])/8)))*v[t,d]);

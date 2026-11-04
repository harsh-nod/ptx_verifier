// Actual PTX B weighting is rounded to half before MFMA; idealized here as in the existing real model.
dim T;
dim PITCH;
dim M;
dim N;
array x[T,PITCH];
array b[T,PITCH];
array dt[T];
array dA_cumsum[T];
array states[M,N];
states[i,j] = sum(t in 0..T, x[t,i] * b[t,j] * dt[t] * exp(min(dA_cumsum[T-1]-dA_cumsum[t],0)));

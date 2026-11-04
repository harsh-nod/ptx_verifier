// Exact encoded base2 score/LSE constants from the native and baseline artifacts.
// General exp2/lg2 use the disclosed shared reciprocal-LOG2_E_F32 base conversion.
dim Q;
dim T;
dim D;
array q[Q,D];
array k[T,D];
array v[T,D];
array log_lambda[T];
array out[Q,D];
array lse[Q];
out[i,d] = sum(j in 0..T,exp(((sum(a in 0..D,q[i,a]*k[j,a])*0.1803368777036667 - log_lambda[j]*1.4426950216293335) - max(b in 0..T,(sum(a in 0..D,q[i,a]*k[b,a])*0.1803368777036667 - log_lambda[b]*1.4426950216293335)))/1.4426950216293335)*v[j,d])/(sum(j in 0..T,exp(((sum(a in 0..D,q[i,a]*k[j,a])*0.1803368777036667 - log_lambda[j]*1.4426950216293335) - max(b in 0..T,(sum(a in 0..D,q[i,a]*k[b,a])*0.1803368777036667 - log_lambda[b]*1.4426950216293335)))/1.4426950216293335)));
lse[i] = (max(b in 0..T,(sum(a in 0..D,q[i,a]*k[b,a])*0.1803368777036667 - log_lambda[b]*1.4426950216293335)) + log(sum(j in 0..T,exp(((sum(a in 0..D,q[i,a]*k[j,a])*0.1803368777036667 - log_lambda[j]*1.4426950216293335) - max(b in 0..T,(sum(a in 0..D,q[i,a]*k[b,a])*0.1803368777036667 - log_lambda[b]*1.4426950216293335)))/1.4426950216293335)))*1.4426950216293335)*0.6931471824645996 + log_lambda[i];

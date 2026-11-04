// Exact baseline/native base2 constants; general base conversion is disclosed separately.
dim R; dim T; dim D;
array x[R,D];
array y[T,D];
array f_hat[R];
array g_hat[T];
array log_b[T];
array f_out[R];
f_out[i] = 0.5*f_hat[i] - 0.5*(max(b in 0..T,(sum(a in 0..D,x[i,a]*y[b,a])*2.885390043258667 + g_hat[b]*1.4426950216293335 + log_b[b]*1.4426950216293335)) + log(max(sum(j in 0..T,exp(((sum(a in 0..D,x[i,a]*y[j,a])*2.885390043258667 + g_hat[j]*1.4426950216293335 + log_b[j]*1.4426950216293335)-max(b in 0..T,(sum(a in 0..D,x[i,a]*y[b,a])*2.885390043258667 + g_hat[b]*1.4426950216293335 + log_b[b]*1.4426950216293335)))/1.4426950216293335)),0.0000000000000000000000000000000000000000999994610111475958152591905227349949604220526961919185041279068749432712426283842432894743978977203369140625))*1.4426950216293335)*0.6931471824645996;

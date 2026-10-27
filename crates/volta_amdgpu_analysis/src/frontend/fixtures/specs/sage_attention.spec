// Signed I8 Q/K numeric values, exact F16 conversion, bounded64-term dot product.
// The actual source uses base2 softmax with a distinct scale per64-key half.
// Half probability/PV rounding is abstracted as in the existing verifier.
dim Q; dim T; dim D; dim HALF; dim ONE; dim TWO;
array q[Q,D];
array k[T,D];
array v[T,D];
array q_scale[ONE];
array k_scale[TWO];
array out[Q,D];
out[i,d] = (sum(j in 0..HALF,exp(((sum(a in 0..D,q[i,a]*k[j,a])*q_scale[0]*k_scale[0])-max(max(b in 0..HALF,(sum(a in 0..D,q[i,a]*k[b,a])*q_scale[0]*k_scale[0])),max(b in 0..HALF,(sum(a in 0..D,q[i,a]*k[b+HALF,a])*q_scale[0]*k_scale[1]))))/1.4426950216293335)*v[j,d])+sum(j in 0..HALF,exp(((sum(a in 0..D,q[i,a]*k[j+HALF,a])*q_scale[0]*k_scale[1])-max(max(b in 0..HALF,(sum(a in 0..D,q[i,a]*k[b,a])*q_scale[0]*k_scale[0])),max(b in 0..HALF,(sum(a in 0..D,q[i,a]*k[b+HALF,a])*q_scale[0]*k_scale[1]))))/1.4426950216293335)*v[j+HALF,d]))/(sum(j in 0..HALF,exp(((sum(a in 0..D,q[i,a]*k[j,a])*q_scale[0]*k_scale[0])-max(max(b in 0..HALF,(sum(a in 0..D,q[i,a]*k[b,a])*q_scale[0]*k_scale[0])),max(b in 0..HALF,(sum(a in 0..D,q[i,a]*k[b+HALF,a])*q_scale[0]*k_scale[1]))))/1.4426950216293335))+sum(j in 0..HALF,exp(((sum(a in 0..D,q[i,a]*k[j+HALF,a])*q_scale[0]*k_scale[1])-max(max(b in 0..HALF,(sum(a in 0..D,q[i,a]*k[b,a])*q_scale[0]*k_scale[0])),max(b in 0..HALF,(sum(a in 0..D,q[i,a]*k[b+HALF,a])*q_scale[0]*k_scale[1]))))/1.4426950216293335)));

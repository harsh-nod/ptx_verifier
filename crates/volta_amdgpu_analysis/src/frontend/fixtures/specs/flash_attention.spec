// Real-arithmetic abstraction: native F16 conversions round ideally away.
// The recognized exact binary32 log2(e) compiler idiom is abstracted as exp.
// LSE retains the exact binary32 ln(2) multiplier in native instructions.
// The disclosed shared PTX/AMD base conversion models lg2(x) as
// log(x)*LOG2_E_F32; these two rounded constants do not silently cancel.
dim Q;
dim T;
dim D;
array q[Q,D];
array k[T,D];
array v[T,D];
array out[Q,D];
array lse[Q];

out[i,d] = sum(j in 0..T,
    exp(sum(a in 0..D, q[i,a]*k[j,a]) * 0.125
        - max(b in 0..T, sum(a in 0..D, q[i,a]*k[b,a]) * 0.125)) * v[j,d])
    / sum(j in 0..T,
      exp(sum(a in 0..D, q[i,a]*k[j,a]) * 0.125
        - max(b in 0..T, sum(a in 0..D, q[i,a]*k[b,a]) * 0.125)));

lse[i] = max(j in 0..T, sum(a in 0..D, q[i,a]*k[j,a]) * 0.125)
    + log(sum(j in 0..T,
        exp(sum(a in 0..D, q[i,a]*k[j,a]) * 0.125
          - max(b in 0..T, sum(a in 0..D, q[i,a]*k[b,a]) * 0.125))))
      * 1.4426950216293335 * 0.6931471824645996;

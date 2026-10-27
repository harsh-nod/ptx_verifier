// Real-arithmetic abstraction: native F16 conversions round ideally away.
// The recognized exact binary32 log2(e) compiler idiom is abstracted as exp.
// LSE retains the exact binary32 ln(2) multiplier emitted by both artifacts;
// it is not silently replaced with an infinitely precise natural-log factor.
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
      * 0.6931471824645996 / log(2);

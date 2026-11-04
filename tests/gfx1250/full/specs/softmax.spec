// Source-specified half conversions are retained in native code and physical CPU oracle.
// Like existing Volta specs, this equation describes the mathematical-real abstraction.
dim R; dim C; array input[R,C]; array output[R,C];
output[r,c] = exp(input[r,c]-max(k in 0..C,input[r,k]))/sum(k in 0..C,exp(input[r,k]-max(j in 0..C,input[r,j])));

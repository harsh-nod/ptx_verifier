// Mixed positional HSA by-value widths, including an unused padding byte31.
#include <hip/hip_runtime.h>
extern "C" __global__ void mixed_byvalue(float *out,float alpha,double beta,
                                       int n,short s,unsigned char b) {
  unsigned t=threadIdx.x;
  if(t<(unsigned)n) out[t]=alpha+(float)beta+(float)s+(float)b;
}

// Launch block2, dynamic LDS8bytes. A12-byte static object precedes an
// extern shared allocation aligned to32bytes; descriptor fixed size includes
// that padding. Preserve actual compiler offsets rather than inventing an ABI.
#include <hip/hip_runtime.h>
extern "C" __global__ void dynamic_lds(const float *x,float *out) {
  __shared__ volatile float fixed[3];
  extern __shared__ __align__(32) float flexible[];
  unsigned t=threadIdx.x;
  fixed[t]=x[t]; flexible[t]=x[t+2]; __syncthreads();
  out[t]=fixed[t^1]+flexible[t^1];
}

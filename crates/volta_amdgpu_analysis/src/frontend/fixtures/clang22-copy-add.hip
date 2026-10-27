#include <hip/hip_runtime.h>

extern "C" __global__ void copy(const float *x, float *out, unsigned n) {
  unsigned i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n)
    out[i] = x[i];
}

extern "C" __global__ void add(const float *x, const float *y, float *out,
                               unsigned n) {
  unsigned i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n)
    out[i] = x[i] + y[i];
}

// Real CDNA3 compiler fixtures, not retargeted CDNA4 assembly.
#include <hip/hip_runtime.h>

extern "C" __global__ __launch_bounds__(128)
void exchange(const float *x, float *out) {
  __shared__ float tile[128];
  unsigned i = threadIdx.x;
  tile[i] = x[i];
  __syncthreads();
  out[i] = tile[i ^ 64];
}

extern "C" __global__ __launch_bounds__(128)
void reduce(const float *x, float *out) {
  unsigned i = threadIdx.x;
  float value = x[i];
  for (int distance = 32; distance; distance >>= 1)
    value += __shfl_down(value, distance);
  if ((i & 63) == 0) out[i / 64] = value;
}

// Retain actual gfx942 descriptor/packed local-ID extraction for this launch.
extern "C" __global__ void ids_3d(float *out) {
  unsigned x = threadIdx.x, y = threadIdx.y, z = threadIdx.z;
  unsigned i = x + blockDim.x * (y + blockDim.y * z);
  out[i] = float(x + 10 * y + 100 * z);
}

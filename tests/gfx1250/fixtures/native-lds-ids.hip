#include <hip/hip_runtime.h>
extern "C" __global__ __launch_bounds__(64)
void exchange(const float *x, float *out) {
  __shared__ float tile[64];
  unsigned t = threadIdx.x;
  tile[t] = x[t];
  __syncthreads();
  out[t] = tile[t ^ 32];
}
extern "C" __global__ __launch_bounds__(64)
void reduce(const float *x, float *out) {
  unsigned t = threadIdx.x;
  float value = x[t];
  for (int d = 16; d; d >>= 1) value += __shfl_down(value, d, 32);
  if ((t & 31) == 0) out[t / 32] = value;
}
extern "C" __global__ void ids_3d(float *out) {
  unsigned x = threadIdx.x, y = threadIdx.y, z = threadIdx.z;
  unsigned i = x + blockDim.x * (y + blockDim.y * z);
  out[i] = float(x + 10*y + 100*z);
}

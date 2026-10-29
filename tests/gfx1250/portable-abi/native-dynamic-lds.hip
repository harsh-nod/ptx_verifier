#include <hip/hip_runtime.h>

using Float4 = float __attribute__((ext_vector_type(4)));

extern "C" __global__ void abi_dynamic_static(const float *x, float *out) {
  __shared__ volatile float fixed[3];
  extern __shared__ __align__(32) float flexible[];
  const unsigned index = threadIdx.x;
  fixed[index] = x[index];
  flexible[index] = x[index + 2];
  __syncthreads();
  out[index] = fixed[index ^ 1] + flexible[index ^ 1];
}

extern "C" __global__ void abi_extern_only(float *out) {
  extern __shared__ volatile float words[];
  words[3] = 42.0f;
  __syncthreads();
  out[0] = words[3];
}

extern "C" __global__ void abi_static_dynamic_disjoint(float *out) {
  __shared__ volatile float fixed[4];
  extern __shared__ __align__(32) volatile float disjoint_flexible[];
  const unsigned index = threadIdx.x;
  if (index == 0)
    fixed[0] = 7.0f;
  if (index == 32)
    disjoint_flexible[0] = 9.0f;
  __syncthreads();
  if (index == 0) {
    out[0] = fixed[0];
    out[1] = disjoint_flexible[0];
  }
}

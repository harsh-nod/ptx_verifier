// The portable byte-copy obligation is the full 128 bytes, independent of the
// NVIDIA/AMD tensor descriptor field schemas. Harmful variant is CPU-only.
#include <hip/hip_runtime.h>
__device__ __forceinline__ unsigned integer_value(unsigned value) {
  asm volatile("v_add_nc_u32 %0, 0, %0" : "+v"(value));
  return value;
}

template <bool ConcurrentReplace>
__device__ __forceinline__ void descriptor_bytes(const unsigned *seed,
                                                 volatile unsigned *destination, unsigned *out) {
  __shared__ volatile unsigned source[32];
  unsigned tid = threadIdx.x;
  if (tid < 32)
    source[tid] = integer_value(seed[tid]);
  __syncthreads();
  if (tid == 0) {
#pragma unroll
    for (unsigned i = 0; i < 32; ++i)
      destination[i] = integer_value(source[i]);
  }
  if (ConcurrentReplace && tid == 32) {
    source[0] = integer_value(seed[32]);
    destination[0] = integer_value(seed[33]);
  }
  __syncthreads();
  if (tid >= 32)
    out[tid - 32] = integer_value(destination[tid - 32]);
}

extern "C" __global__ __launch_bounds__(64) void tensor_descriptor_bytes_ordered(
    const unsigned *seed, volatile unsigned *destination, unsigned *out) {
  descriptor_bytes<false>(seed, destination, out);
}
extern "C" __global__ __launch_bounds__(64) void tensor_descriptor_bytes_replace_race(
    const unsigned *seed, volatile unsigned *destination, unsigned *out) {
  descriptor_bytes<true>(seed, destination, out);
}

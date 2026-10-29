// A complete128-byte LDS source remains borrowed until its TDM store completes.
#include <hip/hip_runtime.h>
#include <stdint.h>
using UInt4 = unsigned __attribute__((ext_vector_type(4)));
using Int4 = int __attribute__((ext_vector_type(4)));
using Int8 = int __attribute__((ext_vector_type(8)));

__device__ __forceinline__ UInt4 lifetime_descriptor(float *global, unsigned lds) {
  uint64_t address = reinterpret_cast<uint64_t>(global);
  return {1, lds, unsigned(address), unsigned((address >> 32) & 0x1ffffffu) | 0x80000000u};
}
__device__ __forceinline__ float lifetime_value(float value) {
  asm volatile("v_add_f32 %0, 0, %0" : "+v"(value));
  return value;
}

extern "C" __global__ __launch_bounds__(64)
void async_source128_reuse(const float *input, float *out) {
  __shared__ volatile float tile[32];
  unsigned thread = threadIdx.x;
  if (thread < 32) tile[thread] = lifetime_value(input[thread]);
  __syncthreads();
  const Int8 shape = {2 << 16, 32 << 16, 1 << 16, 32 << 16, 1, 32, 0, 0};
  const Int4 zero = {};
  if (thread == 0)
    __builtin_amdgcn_tensor_store_from_lds(
        lifetime_descriptor(out, unsigned(reinterpret_cast<uintptr_t>(tile))),
        shape, zero, zero, 0);
  __builtin_amdgcn_s_wait_tensorcnt(0);
  __syncthreads();
  if (thread >= 32) {
    tile[thread - 32] = lifetime_value(input[thread]);
    out[thread] = lifetime_value(tile[thread - 32]);
  }
}

// Native equivalent of an 8x8 F16 tensor's 4x4 tile at coordinate (6,6).
// TDM copies the bounded 2x2 valid crop; ordinary LDS stores fill the padding.
#include <hip/hip_runtime.h>
#include <stdint.h>
using Half = _Float16;
using UInt4 = unsigned __attribute__((ext_vector_type(4)));
using Int4 = int __attribute__((ext_vector_type(4)));
using Int8 = int __attribute__((ext_vector_type(8)));

__device__ __forceinline__ UInt4 descriptor(const Half *global, unsigned lds) {
  uint64_t address = reinterpret_cast<uint64_t>(global);
  return {1, lds, unsigned(address), unsigned((address >> 32) & 0x1ffffffu) | 0x80000000u};
}

__device__ __forceinline__ Half half_zero() {
  Half value = 0;
  asm volatile("v_add_f16 %0, %0, %0" : "+v"(value));
  return value;
}

extern "C" __global__ __launch_bounds__(64) void tensor_edge_4x4(const Half *input, Half *out) {
  __shared__ Half crop[4];
  __shared__ Half padded[16];
  unsigned tid = threadIdx.x;
  if (tid < 16)
    padded[tid] = half_zero();
  const Int8 d1 = {1 << 16, 2 << 16, 2 << 16, 2 << 16, 2, 8, 0, 0};
  const Int4 zero = {};
  if (tid == 0) {
    unsigned shared = unsigned(reinterpret_cast<uintptr_t>(crop));
    __builtin_amdgcn_tensor_load_to_lds(descriptor(input + 54, shared), d1, zero, zero, 0);
  }
  __builtin_amdgcn_s_wait_tensorcnt(0);
  __syncthreads();
  if (tid < 4)
    padded[(tid / 2) * 4 + tid % 2] = crop[tid];
  __syncthreads();
  if (tid < 16)
    out[tid] = padded[tid];
}

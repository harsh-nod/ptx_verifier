// Bounded, non-padded 2-D tensor copy, two 64-float stages in one reused LDS tile.
// D0/D1 packing independently pinned to public LLVM + FlyDSL references.
#include <hip/hip_runtime.h>
#include <stdint.h>
typedef unsigned uint4v __attribute__((ext_vector_type(4)));
typedef int int4v __attribute__((ext_vector_type(4)));
typedef int int8v __attribute__((ext_vector_type(8)));
__device__ __forceinline__ uint4v descriptor0(const float *global, unsigned lds) {
  uint64_t addr = reinterpret_cast<uint64_t>(global);
  return uint4v{1, lds, unsigned(addr), unsigned((addr >> 32) & 0x1ffffffu) | 0x80000000u};
}
extern "C" __global__ __launch_bounds__(64)
void tensor_roundtrip(const float *x, float *out) {
  __shared__ float tile[64];
  unsigned t = threadIdx.x;
  unsigned lds = unsigned(reinterpret_cast<uintptr_t>(tile));
  const int8v d1 = {2 << 16, 64 << 16, 1 << 16, 64 << 16, 1, 64, 0, 0};
  const int4v zero = {};
  #pragma unroll
  for (unsigned stage = 0; stage < 2; ++stage) {
    if (t == 0)
      __builtin_amdgcn_tensor_load_to_lds(descriptor0(x + stage * 64, lds), d1, zero, zero, 0);
    __builtin_amdgcn_s_wait_tensorcnt(0);
    __syncthreads();
    tile[t] = tile[t] + 1.0f;
    __syncthreads();
    if (t == 0)
      __builtin_amdgcn_tensor_store_from_lds(descriptor0(out + stage * 64, lds), d1, zero, zero, 0);
    __builtin_amdgcn_s_wait_tensorcnt(0);
    __syncthreads();
  }
}

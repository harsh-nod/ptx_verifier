// A tensor completion does not publish a distinct ordinary LDS metadata store.
#include <hip/hip_runtime.h>
#include <stdint.h>
using UInt4 = unsigned __attribute__((ext_vector_type(4)));
using Int4 = int __attribute__((ext_vector_type(4)));
using Int8 = int __attribute__((ext_vector_type(8)));
__device__ __forceinline__ UInt4 descriptor(const float *global, unsigned lds) {
  uint64_t address = reinterpret_cast<uint64_t>(global);
  return {1, lds, unsigned(address), unsigned((address >> 32) & 0x1ffffffu) | 0x80000000u};
}
// Completion of the tensor's distinct tile does not publish this ordinary
// metadata store to the second wave. The CTA barrier is still required.
extern "C" __global__ __launch_bounds__(64) void tensor_completion_publication(const float *input,
                                                                               const float *scale,
                                                                               float *out) {
  __shared__ float tile[4];
  __shared__ float meta;
  unsigned tid = threadIdx.x;
  const Int8 d1 = {2 << 16, 4 << 16, 1 << 16, 4 << 16, 1, 4, 0, 0};
  const Int4 zero = {};
  if (tid == 0) {
    meta = scale[0];
    unsigned shared = unsigned(reinterpret_cast<uintptr_t>(tile));
    __builtin_amdgcn_tensor_load_to_lds(descriptor(input, shared), d1, zero, zero, 0);
  }
  __builtin_amdgcn_s_wait_tensorcnt(0);
  __syncthreads();
  if (tid == 32)
    out[0] = meta + tile[0];
}

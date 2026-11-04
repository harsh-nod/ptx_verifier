#include <hip/hip_runtime.h>

using Float4 = float __attribute__((ext_vector_type(4)));

extern "C" __device__ int abi_bound_global = 0;
extern "C" __device__ int abi_global_bias = 3;
extern "C" __constant__ int abi_constant_table[4] = {2, 3, 5, 7};
extern "C" __constant__ int abi_readonly_scalar = 11;

extern "C" __global__ void abi_module_globals(int *out) {
  const unsigned index = threadIdx.x;
  out[index] = abi_bound_global + abi_global_bias + abi_constant_table[index & 3];
}

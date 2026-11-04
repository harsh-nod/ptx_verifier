// Compiler syntax/ABI probe only. Runtime descriptor semantics are not yet validated.
#include <hip/hip_runtime.h>
typedef unsigned uint4v __attribute__((ext_vector_type(4)));
typedef int int4v __attribute__((ext_vector_type(4)));
typedef int int8v __attribute__((ext_vector_type(8)));
extern "C" __global__ __launch_bounds__(32)
void tensor_load_probe(uint4v d0, int8v d1, int4v d2, int4v d3) {
  if (threadIdx.x == 0) __builtin_amdgcn_tensor_load_to_lds(d0, d1, d2, d3, 0);
  __builtin_amdgcn_s_wait_tensorcnt(0);
}
extern "C" __global__ __launch_bounds__(32)
void tensor_store_probe(uint4v d0, int8v d1, int4v d2, int4v d3) {
  if (threadIdx.x == 0) __builtin_amdgcn_tensor_store_from_lds(d0, d1, d2, d3, 0);
  __builtin_amdgcn_s_wait_tensorcnt(0);
}

// Native defined module objects and exact direct PC-relative address sequences.
// The host may override bound_global/global_bias with --global. No undefined
// external object, GOT lookup or arbitrary source-PC arithmetic is required.
#include <hip/hip_runtime.h>
extern "C" __device__ int bound_global = 0;
extern "C" __device__ int global_bias = 3;
extern "C" __constant__ int constant_table[4] = {2,3,5,7};
extern "C" __global__ void module_globals(int *out) {
  unsigned t=threadIdx.x;
  out[t]=bound_global+global_bias+constant_table[t&3];
}

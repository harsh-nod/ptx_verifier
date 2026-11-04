#include <hip/hip_runtime.h>

using Float4 = float __attribute__((ext_vector_type(4)));

// Native B32 stores carry no dtype. Keep an explicit unsigned identity so the
// verifier need not guess whether a transported constant is integer or float.
__device__ __forceinline__ unsigned output_u32(unsigned value) {
  asm volatile("v_add_nc_u32 %0, 0, %0" : "+v"(value));
  return value;
}

extern "C" __global__ void abi_mixed_byvalue(float *out, float alpha, double beta, int count,
                                             short signed_half, unsigned char byte) {
  const unsigned index = threadIdx.x;
  if (index < static_cast<unsigned>(count))
    out[index] = alpha + static_cast<float>(beta) + static_cast<float>(signed_half) +
                 static_cast<float>(byte);
}

extern "C" __global__ void abi_grid_dimensions(unsigned *out) {
  if (threadIdx.x == 0 && threadIdx.y == 0 && threadIdx.z == 0) {
    out[0] = output_u32(gridDim.x);
    out[1] = output_u32(gridDim.y);
    out[2] = output_u32(gridDim.z);
    out[3] = output_u32(blockIdx.x);
    out[4] = output_u32(blockIdx.y);
    out[5] = output_u32(blockIdx.z);
    out[6] = output_u32(blockDim.x);
    out[7] = output_u32(blockDim.y);
    out[8] = output_u32(blockDim.z);
  }
}

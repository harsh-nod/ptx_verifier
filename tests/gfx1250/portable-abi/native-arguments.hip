#include <hip/hip_runtime.h>

using Float4 = float __attribute__((ext_vector_type(4)));

extern "C" __global__ void abi_mixed_byvalue(float *out, float alpha, double beta, int count,
                                             short signed_half, unsigned char byte) {
  const unsigned index = threadIdx.x;
  if (index < static_cast<unsigned>(count))
    out[index] = alpha + static_cast<float>(beta) + static_cast<float>(signed_half) +
                 static_cast<float>(byte);
}

extern "C" __global__ void abi_grid_dimensions(unsigned *out) {
  if (threadIdx.x == 0 && threadIdx.y == 0 && threadIdx.z == 0) {
    out[0] = gridDim.x;
    out[1] = gridDim.y;
    out[2] = gridDim.z;
    out[3] = blockIdx.x;
    out[4] = blockIdx.y;
    out[5] = blockIdx.z;
    out[6] = blockDim.x;
    out[7] = blockDim.y;
    out[8] = blockDim.z;
  }
}

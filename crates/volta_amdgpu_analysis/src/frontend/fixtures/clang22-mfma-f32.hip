#include <hip/hip_runtime.h>
typedef float float4v __attribute__((ext_vector_type(4)));
extern "C" __global__ void mfma_f32(const float *a, const float *b, float *out) {
 unsigned lane = threadIdx.x;
 float4v c = {0, 0, 0, 0};
 c = __builtin_amdgcn_mfma_f32_16x16x4f32(a[lane], b[lane], c, 0, 0, 0);
 out[4*lane] = c[0]; out[4*lane+1] = c[1]; out[4*lane+2] = c[2]; out[4*lane+3] = c[3];
}

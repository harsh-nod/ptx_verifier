// Common CDNA3 F32/F16 MFMA forms with complete one-wave fragments.
#include <hip/hip_runtime.h>
typedef _Float16 half4v __attribute__((ext_vector_type(4)));
typedef float float4v __attribute__((ext_vector_type(4)));

extern "C" __global__ __launch_bounds__(64)
void mfma_f32(const float *a, const float *b, float4v *out) {
  unsigned lane = threadIdx.x;
  float4v zero = {};
  out[lane] = __builtin_amdgcn_mfma_f32_16x16x4f32(a[lane], b[lane], zero, 0, 0, 0);
}

extern "C" __global__ __launch_bounds__(64)
void mfma_f16(const half4v *a, const half4v *b, float4v *out) {
  unsigned lane = threadIdx.x;
  float4v zero = {};
  out[lane] = __builtin_amdgcn_mfma_f32_16x16x16f16(a[lane], b[lane], zero, 0, 0, 0);
}

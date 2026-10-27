// Native gfx950-only MFMA forms. Inputs use instruction lane-fragment order;
// these are layout/encoding fixtures, not full row-major workload substitutes.
#include <hip/hip_runtime.h>
typedef _Float16 half8v __attribute__((ext_vector_type(8)));
typedef __bf16 bf16_8v __attribute__((ext_vector_type(8)));
typedef int int8v __attribute__((ext_vector_type(8)));
typedef float float4v __attribute__((ext_vector_type(4)));
typedef float float16v __attribute__((ext_vector_type(16)));

extern "C" __global__ void mfma_f16_k32(const half8v *a, const half8v *b,
                                       float4v *out) {
  unsigned lane = threadIdx.x;
  float4v c = {0, 0, 0, 0};
  out[lane] = __builtin_amdgcn_mfma_f32_16x16x32_f16(a[lane], b[lane], c, 0, 0, 0);
}

extern "C" __global__ void mfma_bf16_k32(const bf16_8v *a, const bf16_8v *b,
                                        float4v *out) {
  unsigned lane = threadIdx.x;
  float4v c = {0, 0, 0, 0};
  out[lane] = __builtin_amdgcn_mfma_f32_16x16x32_bf16(a[lane], b[lane], c, 0, 0, 0);
}

extern "C" __global__ void mfma_e4m3_k128(const int8v *a, const int8v *b,
                                         float4v *out) {
  unsigned lane = threadIdx.x;
  float4v c = {0, 0, 0, 0};
  // cbsz=blgp=0 selects FP8; scale bytes127 encode the E8M0 unit scale.
  out[lane] = __builtin_amdgcn_mfma_scale_f32_16x16x128_f8f6f4(
      a[lane], b[lane], c, 0, 0, 0, 127, 0, 127);
}

extern "C" __global__ void mfma_e4m3_32_k64(const int8v *a, const int8v *b,
                                            float16v *out) {
  unsigned lane = threadIdx.x;
  float16v c = {};
  out[lane] = __builtin_amdgcn_mfma_scale_f32_32x32x64_f8f6f4(
      a[lane], b[lane], c, 0, 0, 0, 127, 0, 127);
}

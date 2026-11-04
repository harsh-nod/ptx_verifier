// Native gfx1250 WMMA builtins, lane-fragment ABI. CPU validation only.
#include <hip/hip_runtime.h>
typedef float float2v __attribute__((ext_vector_type(2)));
typedef float float8v __attribute__((ext_vector_type(8)));
typedef _Float16 half16v __attribute__((ext_vector_type(16)));
typedef __bf16 bf16_16v __attribute__((ext_vector_type(16)));
extern "C" __global__ __launch_bounds__(32)
void wmma_f32(const float2v *a, const float2v *b, float8v *out) {
  unsigned lane = threadIdx.x;
  float8v zero = {};
  out[lane] = __builtin_amdgcn_wmma_f32_16x16x4_f32(false, a[lane], false, b[lane], 0, zero, false, false);
}
extern "C" __global__ __launch_bounds__(32)
void wmma_f16(const half16v *a, const half16v *b, float8v *out) {
  unsigned lane = threadIdx.x;
  float8v zero = {};
  out[lane] = __builtin_amdgcn_wmma_f32_16x16x32_f16(false, a[lane], false, b[lane], 0, zero, false, false);
}
extern "C" __global__ __launch_bounds__(32)
void wmma_bf16(const bf16_16v *a, const bf16_16v *b, float8v *out) {
  unsigned lane = threadIdx.x;
  float8v zero = {};
  out[lane] = __builtin_amdgcn_wmma_f32_16x16x32_bf16(false, a[lane], false, b[lane], 0, zero, false, false);
}

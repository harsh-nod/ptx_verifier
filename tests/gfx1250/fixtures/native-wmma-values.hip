// Concrete by-value vector operands distinguish BF16 encoding from IEEE F16.
// CPU-only validation: full wave32/256 outputs, no hardware execution.
#include <hip/hip_runtime.h>
typedef float float2v __attribute__((ext_vector_type(2)));
typedef float float8v __attribute__((ext_vector_type(8)));
typedef _Float16 half16v __attribute__((ext_vector_type(16)));
typedef __bf16 bf16_16v __attribute__((ext_vector_type(16)));
extern "C" __global__ __launch_bounds__(32)
void wmma_f32_values(float2v a, float2v b, float8v *out) {
  out[threadIdx.x] = __builtin_amdgcn_wmma_f32_16x16x4_f32(false, a, false, b, 0, float8v{}, false, false);
}
extern "C" __global__ __launch_bounds__(32)
void wmma_f16_values(half16v a, half16v b, float8v *out) {
  out[threadIdx.x] = __builtin_amdgcn_wmma_f32_16x16x32_f16(false, a, false, b, 0, float8v{}, false, false);
}
extern "C" __global__ __launch_bounds__(32)
void wmma_bf16_values(bf16_16v a, bf16_16v b, float8v *out) {
  out[threadIdx.x] = __builtin_amdgcn_wmma_f32_16x16x32_bf16(false, a, false, b, 0, float8v{}, false, false);
}

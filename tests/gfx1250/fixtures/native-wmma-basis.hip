// Genuine compiler basis source for all raw WMMA input coordinates.
// Each launch selects one A or B matrix coordinate; the other operand is a
// matching-K unit stripe. All256 outputs are independently checked by CPU.
#include <hip/hip_runtime.h>
typedef float float2v __attribute__((ext_vector_type(2)));
typedef float float8v __attribute__((ext_vector_type(8)));
typedef _Float16 half16v __attribute__((ext_vector_type(16)));
typedef __bf16 bf16_16v __attribute__((ext_vector_type(16)));
extern "C" __global__ __launch_bounds__(32)
void wmma_f32_basis(float8v *out, unsigned selected, unsigned selected_k, unsigned basis_b) {
  unsigned lane = threadIdx.x;
  float2v a, b;
  #pragma unroll
  for (unsigned item = 0; item < 2; ++item) {
    unsigned k = (lane / 16) * 2 + item;
    bool active_k = k == selected_k;
    bool coordinate = lane % 16 == selected;
    a[item] = active_k && (basis_b || coordinate) ? (float)1 : (float)0;
    b[item] = active_k && (!basis_b || coordinate) ? (float)1 : (float)0;
  }
  out[lane] = __builtin_amdgcn_wmma_f32_16x16x4_f32(false, a, false, b, 0, float8v{}, false, false);
}
extern "C" __global__ __launch_bounds__(32)
void wmma_f16_basis(float8v *out, unsigned selected, unsigned selected_k, unsigned basis_b) {
  unsigned lane = threadIdx.x;
  half16v a, b;
  #pragma unroll
  for (unsigned item = 0; item < 16; ++item) {
    unsigned k = (item / 8) * 16 + (lane / 16) * 8 + item % 8;
    bool active_k = k == selected_k;
    bool coordinate = lane % 16 == selected;
    a[item] = active_k && (basis_b || coordinate) ? (_Float16)1 : (_Float16)0;
    b[item] = active_k && (!basis_b || coordinate) ? (_Float16)1 : (_Float16)0;
  }
  out[lane] = __builtin_amdgcn_wmma_f32_16x16x32_f16(false, a, false, b, 0, float8v{}, false, false);
}
extern "C" __global__ __launch_bounds__(32)
void wmma_bf16_basis(float8v *out, unsigned selected, unsigned selected_k, unsigned basis_b) {
  unsigned lane = threadIdx.x;
  bf16_16v a, b;
  #pragma unroll
  for (unsigned item = 0; item < 16; ++item) {
    unsigned k = (item / 8) * 16 + (lane / 16) * 8 + item % 8;
    bool active_k = k == selected_k;
    bool coordinate = lane % 16 == selected;
    a[item] = active_k && (basis_b || coordinate) ? (__bf16)1 : (__bf16)0;
    b[item] = active_k && (!basis_b || coordinate) ? (__bf16)1 : (__bf16)0;
  }
  out[lane] = __builtin_amdgcn_wmma_f32_16x16x32_bf16(false, a, false, b, 0, float8v{}, false, false);
}

// Portable counterparts for the upstream BF16 fragment-layout and concrete
// high64 division examples. Native wave32 WMMA pads K16/N8 to K32/N16.
#include <hip/hip_runtime.h>
#include <stdint.h>
typedef __bf16 adapter_bf16_16 __attribute__((ext_vector_type(16)));
typedef float adapter_float8 __attribute__((ext_vector_type(8)));

// The PTX baseline loads eight consecutive BF16 A values and four B values
// per lane. These are fragments, not row-major matrix storage. Reconstruct
// the logical A[row,k]/B[k,column] without changing any original input index.
__device__ __forceinline__ unsigned adapter_a_index(unsigned row, unsigned k) {
  unsigned source_lane = (row % 8) * 4 + (k % 8) / 2;
  return source_lane * 8 + (row / 8) * 2 + (k / 8) * 4 + k % 2;
}
__device__ __forceinline__ unsigned adapter_b_index(unsigned k, unsigned column) {
  unsigned source_lane = column * 4 + (k % 8) / 2;
  return source_lane * 4 + (k / 8) * 2 + k % 2;
}
extern "C" __global__ __launch_bounds__(32) void bf16_m16n8k16_fragment_adapter(
    const __bf16 *a, const __bf16 *b, float *native_full, float *original_four) {
  unsigned lane = threadIdx.x;
  adapter_bf16_16 av = {}, bv = {};
#pragma unroll
  for (unsigned element = 0; element < 16; ++element) {
    unsigned k = (element / 8) * 16 + (lane / 16) * 8 + element % 8;
    if (k < 16) {
      av[element] = a[adapter_a_index(lane % 16, k)];
      if ((lane % 16) < 8)
        bv[element] = b[adapter_b_index(k, lane % 16)];
    }
  }
  adapter_float8 zero = {};
  adapter_float8 result =
      __builtin_amdgcn_wmma_f32_16x16x32_bf16(false, av, false, bv, 0, zero, false, false);
  asm volatile("v_nop\n\tv_nop\n\tv_nop\n\tv_nop" : "+v"(result) : "v"(av), "v"(bv) : "memory");
#pragma unroll
  for (unsigned component = 0; component < 8; ++component) {
    unsigned row = (lane / 16) * 8 + component, column = lane % 16;
    native_full[row * 16 + column] = result[component];
  }
  if (lane < 2)
    original_four[lane] = result[0];
  if (lane >= 16 && lane < 18)
    original_four[2 + lane - 16] = result[0];
}

// Keep the exact operands external so compilation cannot replace the native
// high-half product/shift/truncation with its known final constant.
extern "C" __global__ __launch_bounds__(1) void high64_division_projection(uint64_t dividend,
                                                                           uint64_t reciprocal,
                                                                           uint32_t *out) {
  unsigned __int128 product = static_cast<unsigned __int128>(dividend) * reciprocal;
  uint64_t quotient = uint64_t(product >> 64) >> 1;
  out[0] = uint32_t(quotient);
}

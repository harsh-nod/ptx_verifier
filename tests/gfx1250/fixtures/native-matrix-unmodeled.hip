// CPU-only model boundary: genuine matrix-B-reuse encoding, not a tested protocol.
#include <hip/hip_runtime.h>
typedef _Float16 boundary_half16 __attribute__((ext_vector_type(16)));
typedef float boundary_float8 __attribute__((ext_vector_type(8)));
extern "C" __global__ __launch_bounds__(32) void matrix_b_reuse_boundary(
    const boundary_half16 *a, const boundary_half16 *b, boundary_float8 *out) {
  unsigned lane = threadIdx.x;
  out[lane] = __builtin_amdgcn_wmma_f32_16x16x32_f16(
      false, a[lane], false, b[lane], 0, boundary_float8{}, false, true);
}

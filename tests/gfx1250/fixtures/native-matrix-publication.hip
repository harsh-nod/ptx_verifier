// A complete wave32 WMMA result is published through LDS to a second wave.
#include <hip/hip_runtime.h>

using Half16 = _Float16 __attribute__((ext_vector_type(16)));
using Float8 = float __attribute__((ext_vector_type(8)));

extern "C" __global__ __launch_bounds__(64)
void matrix_cross_wave_publication(const _Float16 *input, float *out) {
  __shared__ volatile float published[256];
  unsigned thread = threadIdx.x, lane = thread % 32;
  // A completed prior phase makes the missing-publication mutation execute a
  // complete candidate rather than aborting on an initially undefined byte.
  for (unsigned index = thread; index < 256; index += 64)
    published[index] = 0.0f;
  __syncthreads();
  if (thread < 32) {
    Half16 a = {}, b = {};
#pragma unroll
    for (unsigned component = 0; component < 16; ++component) {
      unsigned k = (component / 8) * 16 + (lane / 16) * 8 + component % 8;
      if (k < 16) {
        a[component] = input[(lane % 16) * 16 + k];
        b[component] = _Float16(k + 1);
      }
    }
    Float8 result = __builtin_amdgcn_wmma_f32_16x16x32_f16(
        false, a, false, b, 0, Float8{}, false, false);
    asm volatile("v_nop\n\tv_nop\n\tv_nop\n\tv_nop"
                 : "+v"(result) : "v"(a), "v"(b) : "memory");
#pragma unroll
    for (unsigned component = 0; component < 8; ++component)
      published[((lane / 16) * 8 + component) * 16 + lane % 16] = result[component];
  }
  __syncthreads();
  if (thread >= 32) {
#pragma unroll
    for (unsigned index = lane; index < 256; index += 32)
      out[index] = published[index];
  }
}

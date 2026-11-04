// Matrix input publication and unrelated metadata have distinct completion.
#include <hip/hip_runtime.h>
using OrderingHalf16 = _Float16 __attribute__((ext_vector_type(16)));
using OrderingFloat8 = float __attribute__((ext_vector_type(8)));

template<class Element>
__device__ __forceinline__ OrderingFloat8 weighted_tile(const Element *input, unsigned lane) {
  OrderingHalf16 a = {}, b = {};
#pragma unroll
  for (unsigned component = 0; component < 16; ++component) {
    unsigned k = (component / 8) * 16 + (lane / 16) * 8 + component % 8;
    if (k < 16) {
      a[component] = input[(lane % 16) * 16 + k];
      b[component] = _Float16(k + 1);
    }
  }
  OrderingFloat8 result = __builtin_amdgcn_wmma_f32_16x16x32_f16(
      false, a, false, b, 0, OrderingFloat8{}, false, false);
  asm volatile("v_nop\n\tv_nop\n\tv_nop\n\tv_nop"
               : "+v"(result) : "v"(a), "v"(b) : "memory");
  return result;
}

extern "C" __global__ __launch_bounds__(64)
void matrix_input_cross_wave(const _Float16 *input, float *out) {
  __shared__ volatile _Float16 tile[256];
  unsigned thread = threadIdx.x, lane = thread % 32;
  for (unsigned i = thread; i < 256; i += 64) tile[i] = 0;
  __syncthreads();
  if (thread < 32) {
#pragma unroll
    for (unsigned i = lane; i < 256; i += 32) tile[i] = input[i];
  }
  __syncthreads();
  if (thread >= 32) {
    OrderingFloat8 result = weighted_tile(tile, lane);
#pragma unroll
    for (unsigned component = 0; component < 8; ++component)
      out[((lane / 16) * 8 + component) * 16 + lane % 16] = result[component];
  }
}

extern "C" __global__ __launch_bounds__(64)
void matrix_completion_keeps_metadata_separate(const _Float16 *input, float *out,
                                              const unsigned *metadata_in,
                                              unsigned *metadata_out) {
  __shared__ volatile unsigned metadata;
  unsigned thread = threadIdx.x, lane = thread % 32;
  if (thread == 0) metadata = 0;
  __syncthreads();
  if (thread == 0) {
    unsigned word = metadata_in[0];
    asm volatile("v_add_nc_u32 %0, 0, %0" : "+v"(word));
    metadata = word;
  }
  if (thread < 32) {
    OrderingFloat8 result = weighted_tile(input, lane);
#pragma unroll
    for (unsigned component = 0; component < 8; ++component)
      out[((lane / 16) * 8 + component) * 16 + lane % 16] = result[component];
  }
  __syncthreads();
  if (thread == 32) {
    unsigned word = metadata;
    asm volatile("v_add_nc_u32 %0, 0, %0" : "+v"(word));
    metadata_out[0] = word;
  }
}

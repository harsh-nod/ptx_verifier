// Genuine wave32 DS/WMMA counterparts for exact portable layout assertions.
#include <hip/hip_runtime.h>
#include <stdint.h>
typedef _Float16 layout_half16 __attribute__((ext_vector_type(16)));
typedef float layout_float8 __attribute__((ext_vector_type(8)));

template<unsigned Pitch> __device__ __forceinline__ void strided_matrix(
    const _Float16 *input, float *out, _Float16 *fragment) {
  // Extra capacity keeps the deliberately overlapping Pitch8 CPU control in
  // bounds, so its actual conflicting writes remain the reason for rejection.
  __shared__ volatile _Float16 tile[16 * Pitch + 16];
  unsigned lane = threadIdx.x;
#pragma unroll
  for (unsigned i = lane; i < 256; i += 32)
    tile[(i / 16) * Pitch + i % 16] = input[i];
  __syncthreads();
  layout_half16 a = {}, b = {};
#pragma unroll
  for (unsigned element = 0; element < 16; ++element) {
    unsigned k = (element / 8) * 16 + (lane / 16) * 8 + element % 8;
    if (k < 16) {
      a[element] = tile[(lane % 16) * Pitch + k];
      fragment[(lane % 16) * 16 + k] = a[element];
      b[element] = _Float16(k + 1);
    }
  }
  layout_float8 result = __builtin_amdgcn_wmma_f32_16x16x32_f16(
      false, a, false, b, 0, layout_float8{}, false, false);
  // Keep both source tuples stable through the documented WMMA read window.
  asm volatile("v_nop\n\tv_nop\n\tv_nop\n\tv_nop" : "+v"(result) : "v"(a), "v"(b) : "memory");
#pragma unroll
  for (unsigned component = 0; component < 8; ++component)
    out[((lane / 16) * 8 + component) * 16 + lane % 16] = result[component];
}
#define STRIDED_KERNEL(bytes) \
extern "C" __global__ __launch_bounds__(32) void matrix_stride##bytes( \
    const _Float16 *input, float *out, _Float16 *fragment) { \
  strided_matrix<(bytes) / 2>(input, out, fragment); \
}
STRIDED_KERNEL(32)
STRIDED_KERNEL(48)
STRIDED_KERNEL(64)
STRIDED_KERNEL(40) // Native halfword accesses allow this PTX-incompatible pitch.
STRIDED_KERNEL(16) // CPU-only overlapping producer rows; never run on a GPU.

template<bool Raw> __device__ __forceinline__ void accumulator_identity(float *out, float *native) {
  unsigned lane = threadIdx.x;
  float one = 1.0f;
  if (Raw)
    asm volatile("v_mov_b32 %0, 0x3f800000" : "=v"(one));
  layout_float8 c;
#pragma unroll
  for (unsigned component = 0; component < 8; ++component)
    c[component] = lane % 4 == 0 ? one : 0.0f;
  layout_half16 a = {}, b = {};
  layout_float8 result = __builtin_amdgcn_wmma_f32_16x16x32_f16(
      false, a, false, b, 0, c, false, false);
  asm volatile("v_nop\n\tv_nop\n\tv_nop\n\tv_nop" : "+v"(result) : "v"(a), "v"(b) : "memory");
#pragma unroll
  for (unsigned component = 0; component < 8; ++component) {
    unsigned index = ((lane / 16) * 8 + component) * 16 + lane % 16;
    native[index] = result[component];
    if (index < 128) out[index] = result[component];
  }
}
extern "C" __global__ __launch_bounds__(32) void matrix_raw_accumulator(float *out, float *native) {
  accumulator_identity<true>(out, native);
}
extern "C" __global__ __launch_bounds__(32) void matrix_immediate_accumulator(float *out, float *native) {
  accumulator_identity<false>(out, native);
}

extern "C" __global__ __launch_bounds__(32) void matrix_four_fragment_pairs(
    const uint16_t *input, uint16_t *out) {
  __shared__ volatile uint16_t tile[256];
  unsigned lane = threadIdx.x;
#pragma unroll
  for (unsigned i = lane; i < 256; i += 32) tile[i] = input[i];
  __syncthreads();
#pragma unroll
  for (unsigned component = 0; component < 8; ++component) {
    unsigned index = lane * 8 + component;
    unsigned source = (component / 2) * 64 + lane * 2 + component % 2;
    out[index] = tile[source];
  }
}
extern "C" __global__ __launch_bounds__(32) void matrix_lane_word_placement(uint32_t *out) {
  __shared__ volatile uint32_t tile[32];
  unsigned lane = threadIdx.x;
  tile[lane] = 1000 + lane;
  __syncthreads();
  out[lane + 1] = tile[lane];
  if (lane == 0) out[0] = tile[5];
}

// Preserve original logical matrix shapes, concrete storage formats and C seeds.
#include <hip/hip_runtime.h>
#include <stdint.h>
typedef _Float16 numeric_half16 __attribute__((ext_vector_type(16)));
typedef float numeric_float8 __attribute__((ext_vector_type(8)));
__device__ __forceinline__ uint32_t numeric_bits(uint32_t bits) {
  asm volatile("" : "+v"(bits));
  return bits;
}
template<unsigned Mode, unsigned Columns = 8, bool DisableFirst = false>
__device__ __forceinline__ void numeric_half_matrix(float *out, float *native) {
  __shared__ volatile uint16_t a[128 * 16], b[16 * Columns];
  unsigned tid = threadIdx.x, lane = tid & 31, wave = tid >> 5;
  for (unsigned i = tid; i < 128 * 16; i += 256) {
    uint16_t bits = 0;
    if (Mode != 2 && i / 16 == 0)
      bits = Mode == 1 ? uint16_t(numeric_bits(0x3c00))
                       : __builtin_bit_cast(uint16_t, _Float16(i % 16 + 1));
    a[i] = bits;
  }
  for (unsigned i = tid; i < 16 * Columns; i += 256)
    b[i] = Mode != 2 && i % Columns == 0 ? uint16_t(numeric_bits(0x3c00)) : 0;
  __syncthreads();
#pragma unroll 1
  for (unsigned column_base = 0; column_base < Columns; column_base += 16) {
    numeric_half16 av = {}, bv = {};
#pragma unroll
    for (unsigned element = 0; element < 16; ++element) {
      unsigned k = (element / 8) * 16 + (lane / 16) * 8 + element % 8;
      if (k < 16) {
        av[element] = __builtin_bit_cast(_Float16, uint16_t(a[(wave * 16 + lane % 16) * 16 + k]));
        if (column_base + lane % 16 < Columns)
          bv[element] = __builtin_bit_cast(_Float16, uint16_t(b[k * Columns + column_base + lane % 16]));
      }
    }
    float one = 1.0f;
    if (Mode == 1) asm volatile("v_mov_b32 %0, 0x3f800000" : "=v"(one));
    numeric_float8 c;
#pragma unroll
    for (unsigned i = 0; i < 8; ++i) c[i] = Mode == 1 && lane % 16 < Columns ? one : 0.0f;
    numeric_float8 result = __builtin_amdgcn_wmma_f32_16x16x32_f16(
        false, av, false, bv, 0, c, false, false);
    asm volatile("v_nop\n\tv_nop\n\tv_nop\n\tv_nop" : "+v"(result) : "v"(av), "v"(bv) : "memory");
#pragma unroll
    for (unsigned i = 0; i < 8; ++i) {
      unsigned row = wave * 16 + (lane / 16) * 8 + i;
      unsigned column = column_base + lane % 16;
      // Every native padded coordinate is observable independently.
      native[row * ((Columns + 15) / 16 * 16) + column] = result[i];
      if (column < Columns && !(DisableFirst && row == 0 && column == 0))
        out[row * Columns + column] = result[i];
    }
  }
}
#define HALF_KERNEL(name, mode) \
extern "C" __global__ __launch_bounds__(256) void name(float *out, float *native) { \
  numeric_half_matrix<mode>(out, native); \
}
HALF_KERNEL(matrix_numeric136, 0)
HALF_KERNEL(matrix_raw17, 1)
HALF_KERNEL(matrix_zero_128x8, 2)
extern "C" __global__ __launch_bounds__(256) void matrix_zero_128x256(float *out, float *native) {
  numeric_half_matrix<2, 256>(out, native);
}
extern "C" __global__ __launch_bounds__(256) void matrix_disabled_first_output(float *out, float *native) {
  numeric_half_matrix<0, 8, true>(out, native);
}
// CPU-only definedness control: the disabled producer never initializes cell0.
extern "C" __global__ __launch_bounds__(256) void matrix_disabled_lds_read(float *out, float *native) {
  __shared__ volatile float logical[128 * 8];
  // Keep actual global matrix outputs and LDS publication in separate loops.
  // A generic Shared/Global pointer merge would exercise mixed-aperture FLAT
  // dispatch before the intended missing-producer definedness property.
  numeric_half_matrix<0, 8, true>(out, native);
  for (unsigned i = threadIdx.x; i < 128 * 8; i += 256)
    if (i != 0) logical[i] = native[(i / 8) * 16 + i % 8];
  __syncthreads();
  if (threadIdx.x == 0) out[0] = logical[0];
}

template<bool WrongBFormat> __device__ __forceinline__ void mixed_fp8_matrix(float *out, float *native) {
  // Keep the original 128-byte gap between the two 16-K cores explicit.
  __shared__ volatile uint8_t a[128 * 256], b[8 * 256];
  unsigned tid = threadIdx.x, lane = tid & 31, wave = tid >> 5;
  const uint8_t e4[16] = {0x38,0x40,0x44,0x48,0x4a,0x4c,0x4e,0x50,
                         0x51,0x52,0x53,0x54,0x55,0x56,0x57,0x58};
  for (unsigned i = tid; i < 128 * 32; i += 256) {
    unsigned k = i % 32;
    a[(i / 32) * 256 + (k / 16) * 128 + k % 16] = i / 32 == 0 ? e4[k % 16] : 0;
  }
  for (unsigned i = tid; i < 8 * 32; i += 256) {
    unsigned k = i % 32;
    b[(i / 32) * 256 + (k / 16) * 128 + k % 16] = i / 32 == 0 ? (k < 16 ? 0x3c : 0x40) : 0;
  }
  __syncthreads();
  numeric_half16 av = {}, bv = {};
#pragma unroll
  for (unsigned i = 0; i < 16; ++i) {
    unsigned k = (i / 8) * 16 + (lane / 16) * 8 + i % 8;
    unsigned offset = (k / 16) * 128 + k % 16;
    unsigned abits = a[(wave * 16 + lane % 16) * 256 + offset];
    av[i] = _Float16(__builtin_amdgcn_cvt_f32_fp8(abits, 0));
    if (lane % 16 < 8) {
      unsigned bbits = b[(lane % 16) * 256 + offset];
      bv[i] = _Float16(WrongBFormat ? __builtin_amdgcn_cvt_f32_fp8(bbits, 0)
                                  : __builtin_amdgcn_cvt_f32_bf8(bbits, 0));
    }
  }
  numeric_float8 result = __builtin_amdgcn_wmma_f32_16x16x32_f16(
      false, av, false, bv, 0, numeric_float8{}, false, false);
  asm volatile("v_nop\n\tv_nop\n\tv_nop\n\tv_nop" : "+v"(result) : "v"(av), "v"(bv) : "memory");
#pragma unroll
  for (unsigned i = 0; i < 8; ++i) {
    unsigned row = wave * 16 + (lane / 16) * 8 + i, column = lane % 16;
    native[row * 16 + column] = result[i];
    if (column < 8) out[row * 8 + column] = result[i];
  }
}
extern "C" __global__ __launch_bounds__(256) void matrix_mixed408(float *out, float *native) {
  mixed_fp8_matrix<false>(out, native);
}
extern "C" __global__ __launch_bounds__(256) void matrix_wrong_b476(float *out, float *native) {
  mixed_fp8_matrix<true>(out, native);
}

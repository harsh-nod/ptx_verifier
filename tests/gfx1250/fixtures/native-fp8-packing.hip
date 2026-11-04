// OCP E4M3 byte selectors and F16 transport preserve each original payload.
#include <hip/hip_runtime.h>

using Half = _Float16;
using Half2 = Half __attribute__((ext_vector_type(2)));
using Word2 = unsigned __attribute__((ext_vector_type(2)));
__device__ __forceinline__ unsigned keep_word(unsigned value) {
  asm volatile("" : "+v"(value));
  return value;
}
__device__ __forceinline__ float keep_float(float value) {
  asm volatile("" : "+v"(value));
  return value;
}
template <unsigned byte>
__device__ __forceinline__ float decode(unsigned word) {
  // The actual instruction needs a compile-time selector, so the callers use
  // literal selectors and force inlining. Its format is target OCP E4M3.
  return __builtin_amdgcn_cvt_f32_fp8(word, byte);
}
extern "C" __global__ __launch_bounds__(1)
void fp8_concrete_pair(float *out) {
  unsigned word = keep_word(0xb838);
  out[0] = decode<0>(word);
  out[1] = decode<1>(word);
}
extern "C" __global__ __launch_bounds__(1)
void fp8_concrete_relu(float *out) {
  unsigned word = keep_word(0xb838);
  out[0] = __builtin_fmaxf(decode<0>(word), 0.0f);
  out[1] = __builtin_fmaxf(decode<1>(word), 0.0f);
}
extern "C" __global__ __launch_bounds__(1)
void fp8_vector_bytes(const volatile Word2 *input, float *out) {
  Word2 words = input[0];
  unsigned word = keep_word(words[0]);
  out[0] = decode<0>(word);
  out[1] = decode<1>(word);
  out[2] = decode<2>(word);
  out[3] = decode<3>(word);
}
extern "C" __global__ __launch_bounds__(1)
void fp8_selected_halves(const volatile unsigned *input, float *out) {
  unsigned word = keep_word(input[0]);
  out[0] = decode<0>(word);
  out[1] = decode<2>(word);
}
extern "C" __global__ __launch_bounds__(1)
void fp8_zero_extended_byte(const volatile unsigned char *input, float *out) {
  unsigned word = keep_word(input[0]);
  out[0] = decode<0>(word);
}
extern "C" __global__ __launch_bounds__(1)
void fp8_byte_low_and_high(const volatile unsigned char *input, float *out) {
  unsigned word = keep_word(input[0]);
  out[0] = decode<0>(word);
  out[1] = decode<1>(word);
}
extern "C" __global__ __launch_bounds__(1)
void fp8_nan_decode(float *out) {
  unsigned word = keep_word(0x7f00);
  out[0] = decode<1>(word);
}
extern "C" __global__ __launch_bounds__(1)
void fp8_pack_half_values(Half2 *out) {
  out[0] = Half2{Half(keep_float(2.5f)), Half(keep_float(1.5f))};
}
extern "C" __global__ __launch_bounds__(1)
void fp8_relu_to_half(const float *input, volatile Half *out) {
  out[0] = Half(__builtin_fmaxf(keep_float(input[0]), 0.0f));
}

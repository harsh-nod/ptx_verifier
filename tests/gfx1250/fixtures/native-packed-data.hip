// Original packed-payload computations expressed for gfx1250, not retargeted ISA.
#include <hip/hip_runtime.h>
#include <stdint.h>

using Float2 = float __attribute__((ext_vector_type(2)));
using Word2 = unsigned __attribute__((ext_vector_type(2)));
using Half = _Float16;
using Half2 = Half __attribute__((ext_vector_type(2)));

__device__ __forceinline__ uint64_t keep_words(uint64_t value) {
  asm volatile("" : "+v"(value));
  return value;
}
__device__ __forceinline__ unsigned integer_word(unsigned value) {
  asm volatile("v_add_nc_u32 %0, 0, %0" : "+v"(value));
  return value;
}
__device__ __forceinline__ Float2 pair_value(Float2 value) {
  return __builtin_bit_cast(Float2, keep_words(__builtin_bit_cast(uint64_t, value)));
}
__device__ __forceinline__ Float2 fma_pair(Float2 value) {
  return __builtin_elementwise_fma(value, value, value);
}

extern "C" __global__ __launch_bounds__(2)
void packed_scalar_reference(const float *input, float *out) {
  unsigned first = threadIdx.x * 2;
  float low = input[first], high = input[first + 1];
  out[first] = __builtin_fmaf(low, low, low);
  out[first + 1] = __builtin_fmaf(high, high, high);
}
extern "C" __global__ __launch_bounds__(2)
void packed_register_fma(const float *input, float *out) {
  unsigned first = threadIdx.x * 2;
  Float2 value = pair_value(Float2{input[first], input[first + 1]});
  Float2 result = fma_pair(value);
  out[first] = result[0];
  out[first + 1] = result[1];
}
extern "C" __global__ __launch_bounds__(2)
void packed_memory_fma(const Float2 *input, Float2 *out) {
  out[threadIdx.x] = fma_pair(input[threadIdx.x]);
}
extern "C" __global__ __launch_bounds__(2)
void packed_unfused(const Float2 *input, Float2 *out) {
  Float2 value = pair_value(input[threadIdx.x]);
  Float2 product = value * value;
  asm volatile("" : "+v"(product));
  out[threadIdx.x] = product + value;
}
extern "C" __global__ __launch_bounds__(2)
void packed_constant_operand(const Float2 *input, Float2 *out) {
  Float2 value = input[threadIdx.x];
  Float2 ones = __builtin_bit_cast(Float2, keep_words(0x3f8000003f800000ull));
  Float2 doubled = __builtin_elementwise_fma(value, ones, value);
  Float2 recovered = pair_value(doubled - value);
  out[threadIdx.x] = fma_pair(recovered);
}
extern "C" __global__ __launch_bounds__(2)
void packed_wrong_math(const Float2 *input, Float2 *out) {
  Float2 value = pair_value(input[threadIdx.x]);
  out[threadIdx.x] = value * value;
}
extern "C" __global__ __launch_bounds__(2)
void packed_shift_or(const Float2 *input, Float2 *out) {
  Word2 words = __builtin_bit_cast(Word2, input[threadIdx.x]);
  uint64_t low = keep_words(uint64_t(words[0]));
  uint64_t high = keep_words(uint64_t(words[1]));
  uint64_t packed = keep_words(low | (high << 32));
  out[threadIdx.x] = fma_pair(__builtin_bit_cast(Float2, packed));
}
extern "C" __global__ __launch_bounds__(2)
void packed_zero_extend(const Float2 *input, Float2 *out) {
  Word2 words = __builtin_bit_cast(Word2, input[threadIdx.x]);
  uint64_t low = keep_words(uint64_t(words[0]));
  uint64_t high = keep_words(uint64_t(words[1]));
  Word2 rebuilt = {unsigned(low), unsigned(high)};
  out[threadIdx.x] = fma_pair(__builtin_bit_cast(Float2, rebuilt));
}
extern "C" __global__ __launch_bounds__(2)
void packed_high_shift(const Float2 *input, Float2 *out) {
  uint64_t packed = keep_words(__builtin_bit_cast(uint64_t, input[threadIdx.x]));
  uint64_t high = keep_words(packed >> 32);
  Word2 rebuilt = {unsigned(packed), unsigned(high)};
  out[threadIdx.x] = fma_pair(__builtin_bit_cast(Float2, rebuilt));
}
extern "C" __global__ __launch_bounds__(1)
void packed_pointer_direct(const float *input, float *out) {
  out[2] = input[0] + 0.0f;
}
extern "C" __global__ __launch_bounds__(1)
void packed_pointer_reassembled(const float *input, float *out) {
  uint64_t pointer = keep_words(reinterpret_cast<uintptr_t>(out));
  uint64_t displacement = keep_words(uint64_t(integer_word(8)));
  auto *target = reinterpret_cast<float *>(pointer + displacement);
  *target = input[0] + 0.0f;
}
extern "C" __global__ __launch_bounds__(1)
void packed_half_pack(const Half *input, Half2 *out) {
  Half2 pair = {input[0], input[1]};
  unsigned word = __builtin_bit_cast(unsigned, pair);
  asm volatile("" : "+v"(word));
  out[0] = __builtin_bit_cast(Half2, word);
}
extern "C" __global__ __launch_bounds__(1)
void packed_half_unpack(const Half2 *input, volatile Half *out) {
  Half2 pair = input[0];
  unsigned word = __builtin_bit_cast(unsigned, pair);
  asm volatile("" : "+v"(word));
  Half2 unpacked = __builtin_bit_cast(Half2, word);
  out[0] = unpacked[0];
  out[1] = unpacked[1];
}
extern "C" __global__ __launch_bounds__(1)
void packed_integer_halves(uint64_t *out) {
  uint64_t low = integer_word(5), high = integer_word(3);
  out[0] = (high << 32) | low;
}
extern "C" __global__ __launch_bounds__(1)
void packed_raw_halfwords(volatile unsigned short *out) {
  unsigned word = integer_word(0x1234abcd);
  out[0] = integer_word(word & 0xffff);
  out[1] = integer_word(word >> 16);
}

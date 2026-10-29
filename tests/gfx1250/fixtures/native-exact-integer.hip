// Native counterparts for the original fixed-width scalar assertions.
// Register barriers preserve the original constant operations in compiler output.
#include <hip/hip_runtime.h>
#include <stdint.h>

template <class T> __device__ __forceinline__ T register_value(T value) {
  asm volatile("" : "+v"(value));
  return value;
}
__device__ __forceinline__ uint32_t integer_word(uint32_t value) {
  // Global stores are untyped. The identity keeps unsigned32 provenance.
  asm volatile("v_add_nc_u32 %0, 0, %1" : "=v"(value) : "v"(value));
  return value;
}
__device__ __forceinline__ float floating_word(float value) {
  asm volatile("v_add_f32 %0, 0, %1" : "=v"(value) : "v"(value));
  return value;
}
extern "C" __global__ __launch_bounds__(1) void exact_b16_shift_count_u32(const uint32_t *,
                                                                         uint32_t *out) {
  uint32_t shift = register_value(0x10000u);
  uint32_t a = register_value(1u), b = register_value(0x8000u);
  out[0] = integer_word(shift < 16 ? uint16_t(a << shift) : 0u);
  out[1] = integer_word(shift < 16 ? uint16_t(b) >> shift : 0u);
  out[2] = integer_word(shift < 16 ? uint16_t(int16_t(b) >> shift) : 65535u);
}
extern "C" __global__ __launch_bounds__(1) void exact_b64_shift_u32(const uint64_t *, uint64_t *out) {
  uint64_t value = register_value(uint64_t(3));
  uint32_t shift = register_value(40u);
  uint64_t left = value << shift;
  out[0] = left;
  out[1] = left >> shift;
}
__device__ __forceinline__ uint32_t extract_unsigned(uint32_t value, uint32_t start, uint32_t width) {
  if (start >= 32 || width == 0)
    return 0;
  uint32_t available = 32 - start;
  uint32_t length = width < available ? width : available;
  uint32_t mask = length == 32 ? ~0u : (1u << length) - 1;
  return (value >> start) & mask;
}
__device__ __forceinline__ uint32_t extract_signed(uint32_t value, uint32_t start, uint32_t width) {
  if (width == 0)
    return 0;
  if (start >= 32)
    return uint32_t(int32_t(value) >> 31);
  uint32_t available = 32 - start;
  uint32_t length = width < available ? width : available;
  return uint32_t(int32_t(value << (available - length)) >> (32 - length));
}
extern "C" __global__ __launch_bounds__(1) void exact_bfe_clipping(uint32_t *out) {
  uint32_t ten = register_value(10u), ones = register_value(~0u);
  out[0] = integer_word(extract_unsigned(ten, register_value(0u), register_value(4u)));
  out[1] = integer_word(extract_signed(ten, register_value(0u), register_value(4u)));
  out[2] = integer_word(extract_signed(ones, register_value(40u), register_value(4u)));
  out[3] = integer_word(extract_unsigned(ones, register_value(4u), register_value(0u)));
}
__device__ __forceinline__ uint32_t insert_clipped(uint32_t insert, uint32_t base, uint32_t start,
                                                uint32_t width) {
  if (start >= 32 || width == 0)
    return base;
  uint32_t available = 32 - start;
  uint32_t length = width < available ? width : available;
  uint32_t mask = length == 32 ? ~0u : (1u << length) - 1;
  mask <<= start;
  return (base & ~mask) | ((insert << start) & mask);
}
extern "C" __global__ __launch_bounds__(1) void exact_bfi_clipping(uint32_t *out) {
  out[0] = integer_word(insert_clipped(register_value(3u), register_value(0u), register_value(4u),
                                       register_value(2u)));
  out[1] = integer_word(insert_clipped(register_value(0u), register_value(5u), register_value(4u),
                                       register_value(64u)));
  out[2] = integer_word(insert_clipped(register_value(~0u), register_value(5u), register_value(64u),
                                       register_value(4u)));
  out[3] = integer_word(insert_clipped(register_value(~0u), register_value(7u), register_value(40u),
                                       register_value(0u)));
}
extern "C" __global__ __launch_bounds__(64) void exact_declined_cancel_one_pass(const float *input,
                                                                               float *out) {
  // Specialize the original model's explicit never-steal premise. There is no
  // native cancellation/scheduler mechanism being claimed by this counterpart.
  uint32_t index = blockIdx.x * blockDim.x + threadIdx.x;
  out[index] = input[index] + input[index];
}
extern "C" __global__ __launch_bounds__(1) void exact_int_abs_signed_width(const uint32_t *,
                                                                           uint32_t *out) {
  uint32_t values[2] = {register_value(0xfffffffbu), register_value(0x80000000u)};
#pragma unroll
  for (uint32_t i = 0; i < 2; ++i) {
    uint32_t mask = 0u - (values[i] >> 31);
    out[i] = integer_word((values[i] ^ mask) - mask);
  }
}
extern "C" __global__ __launch_bounds__(1) void exact_load_s8_sign_extends(volatile uint8_t *scratch,
                                                                          uint32_t *out) {
  scratch[0] = uint8_t(register_value(255u));
  int32_t value = reinterpret_cast<volatile int8_t *>(scratch)[0];
  out[0] = integer_word(uint32_t(value));
}
extern "C" __global__ __launch_bounds__(1) void exact_load_s8_direct_minus_one(uint8_t *,
                                                                             uint32_t *out) {
  out[0] = integer_word(register_value(~0u));
}
extern "C" __global__ __launch_bounds__(1) void exact_mov_minus_one(uint32_t *out) {
  out[0] = integer_word(register_value(~0u));
}
extern "C" __global__ __launch_bounds__(1) void exact_not_zero(uint32_t *out) {
  out[0] = integer_word(~register_value(0u));
}
extern "C" __global__ __launch_bounds__(1) void exact_mul_high_u32(const uint32_t *, uint32_t *out) {
  uint64_t a = register_value(~0u), b = register_value(2u);
  out[0] = integer_word(uint32_t((a * b) >> 32));
}
extern "C" __global__ __launch_bounds__(1) void exact_mul_wide_u16(const uint32_t *, uint32_t *out) {
  uint16_t value = uint16_t(register_value(14u));
  uint16_t multiplier = uint16_t(register_value(uint32_t(uint16_t(-17873))));
  uint32_t quotient = (uint32_t(value) * multiplier) >> 19;
  uint16_t product = uint16_t(uint16_t(quotient) * uint16_t(11));
  out[0] = integer_word(quotient);
  out[1] = integer_word(uint16_t(value - product));
}
#define RING_KERNEL(NAME, EXPRESSION)                                                                \
  extern "C" __global__ __launch_bounds__(1) void NAME(const uint32_t *input, uint32_t *out) {         \
    uint32_t value = input[0];                                                                        \
    out[0] = integer_word(EXPRESSION);                                                                \
  }
// Signed and unsigned PTX variants share the same wrapping native bit operation.
RING_KERNEL(exact_ring_add_s32_neg1, value + uint32_t(-1))
RING_KERNEL(exact_ring_add_u32_neg1, value + uint32_t(-1))
RING_KERNEL(exact_ring_sub_s32_neg7, value - uint32_t(-7))
RING_KERNEL(exact_ring_sub_u32_neg7, value - uint32_t(-7))
RING_KERNEL(exact_ring_sub_u32_1, value - 1u)
RING_KERNEL(exact_ring_mul_s32_neg3, value * uint32_t(-3))
RING_KERNEL(exact_ring_mul_u32_neg3, value * uint32_t(-3))
extern "C" __global__ __launch_bounds__(1) void exact_select_minus_one(const uint32_t *input,
                                                                       uint32_t *out) {
  out[0] = integer_word(int32_t(input[0]) == -1 ? ~0u : 0u);
}
extern "C" __global__ __launch_bounds__(1) void exact_select_complement(const uint32_t *input,
                                                                        uint32_t *out) {
  uint32_t complement = ~register_value(0u);
  out[0] = integer_word(int32_t(input[0]) == int32_t(complement) ? complement : 0u);
}
extern "C" __global__ __launch_bounds__(1) void exact_funnel_clamp_wrap(const uint32_t *,
                                                                        uint32_t *out) {
  uint32_t low = register_value(0x11111111u), high = register_value(0x22222222u);
  uint32_t raw_count = register_value(~0u);
  uint32_t clamped = raw_count < 32 ? raw_count : 32;
  uint32_t wrapped = raw_count & 31;
  uint64_t pair = uint64_t(high) << 32 | low;
  out[0] = integer_word(uint32_t((pair << clamped) >> 32));
  out[1] = integer_word(uint32_t(pair >> clamped));
  out[2] = integer_word(uint32_t((pair << wrapped) >> 32));
  out[3] = integer_word(uint32_t(pair >> wrapped));
}
extern "C" __global__ __launch_bounds__(1) void exact_store_u8_truncates(volatile uint8_t *scratch,
                                                                        uint32_t *out) {
  uint32_t value = register_value(44u) + 256u;
  scratch[0] = uint8_t(value);
  out[0] = integer_word(scratch[0]);
}
extern "C" __global__ __launch_bounds__(1) void exact_unsigned_byte_identity(const uint8_t *scratch,
                                                                            uint32_t *out) {
  out[0] = integer_word(scratch[0]);
}
extern "C" __global__ __launch_bounds__(1) void exact_vector_immediates(const float *input,
                                                                       float *out) {
  float4 value = {input[0], floating_word(0.), input[1], floating_word(1.)};
  *reinterpret_cast<float4 *>(out) = value;
}

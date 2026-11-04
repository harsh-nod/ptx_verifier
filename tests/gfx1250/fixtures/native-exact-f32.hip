// Exact original scalar controls, compiled as genuine gfx1250 kernels.
#include <hip/hip_runtime.h>
#include <hip/hip_fp16.h>
#include <stdint.h>

__device__ __forceinline__ float encoded(uint32_t bits) {
  union { uint32_t bits; float value; } word = {bits};
  float value = word.value;
  asm volatile("" : "+v"(value));
  return value;
}
__device__ __forceinline__ float typed(float value) {
  asm volatile("v_add_f32 %0, 0, %1" : "=v"(value) : "v"(value));
  return value;
}
__device__ __forceinline__ float reciprocal(float value) {
  float result;
  asm volatile("v_rcp_f32 %0, %1" : "=v"(result) : "v"(value));
  return result;
}
__device__ __forceinline__ float natural_exp(float value) {
  // Pinned existing CompilerExp2Idiom abstraction; physical evaluation rounds.
  value = value * encoded(0x3fb8aa3b);
  asm volatile("v_exp_f32 %0, %1" : "=v"(value) : "v"(value));
  return value;
}
__device__ __forceinline__ float clamp(float value) {
  asm volatile("v_add_f32 %0, 0, %1 clamp" : "=v"(value) : "v"(value));
  return value;
}

extern "C" __global__ __launch_bounds__(1) void exact_add_sat(float *out) {
  float a = encoded(0x3f400000), b = encoded(0xbf400000), c = encoded(0x3e800000);
  out[0] = clamp(a + a);
  out[1] = clamp(b + c);
}
extern "C" __global__ __launch_bounds__(1) void exact_copysign(float *out) {
  float a = encoded(0x40000000), b = encoded(0x40400000);
  float c = encoded(0xc0000000), d = encoded(0xc0400000);
  float plus = typed(__builtin_copysignf(b, a)) + typed(__builtin_copysignf(d, a));
  float minus = typed(__builtin_copysignf(b, c)) + typed(__builtin_copysignf(d, c));
  out[0] = plus + minus;
}
extern "C" __global__ __launch_bounds__(1) void exact_source_integer_format(long long *out) {
  uint32_t a = uint32_t(-5), b = 3;
  asm volatile("" : "+v"(a), "+v"(b));
  out[0] = int32_t(a & uint32_t(-4));
  out[1] = uint64_t(uint32_t(b - 11));
}
extern "C" __global__ __launch_bounds__(1) void exact_div768(const float *input, float *out) {
  out[0] = input[0] * reciprocal(encoded(0x44400000));
}
extern "C" __global__ __launch_bounds__(1) void exact_mul_recip768(const float *input, float *out) {
  float inverse = reciprocal(encoded(0x44400000));
  asm volatile("" : "+v"(inverse));
  out[0] = input[0] * inverse;
}
extern "C" __global__ __launch_bounds__(1) void exact_div_recip3(const float *input, float *out) {
  out[0] = input[0] * reciprocal(encoded(0x40400000));
}
extern "C" __global__ __launch_bounds__(1) void exact_rcp3(const float *input, float *out) {
  float inverse = reciprocal(encoded(0x40400000));
  asm volatile("" : "+v"(inverse));
  out[0] = input[0] * inverse;
}
extern "C" __global__ __launch_bounds__(1) void exact_abs_bits(const float *input, float *out) {
  out[0] = typed(__builtin_fabsf(encoded(0xc0a00000)));
  out[1] = typed(__builtin_fabsf(encoded(0xff800000)));
  out[2] = typed(__builtin_fabsf(input[0]));
}
extern "C" __global__ __launch_bounds__(1) void exact_raw_math(const float *input, float *out) {
  float one = encoded(0x3f800000), four = encoded(0x40800000);
  float minus = encoded(0xbf800000);
  out[0] = __builtin_fmaf(one, one, one);
  out[1] = reciprocal(four);
  float root;
  asm volatile("v_sqrt_f32 %0, %1" : "=v"(root) : "v"(four));
  out[2] = root;
  uint32_t half_bits = 0x3c00;
  asm volatile("" : "+v"(half_bits));
  union { uint16_t bits; _Float16 value; } half = {uint16_t(half_bits)};
  out[3] = float(half.value);
  out[4] = typed(__builtin_copysignf(four, minus));
  out[5] = typed(__builtin_copysignf(input[0], minus));
}
extern "C" __global__ __launch_bounds__(1) void exact_mixed_fma(const float *, float *out) {
  uint32_t a = 0x3c00, b = 0x4000;
  asm volatile("" : "+v"(a), "+v"(b));
  union { uint16_t bits; _Float16 value; } x = {uint16_t(a)}, y = {uint16_t(b)};
  out[0] = __builtin_fmaf(float(x.value), float(y.value), encoded(0x3f800000));
}
extern "C" __global__ __launch_bounds__(1) void exact_neg_bits(const float *input, float *out) {
  uint32_t a = 0xfffffffb, b = 0x80000000;
  asm volatile("" : "+v"(a), "+v"(b));
  uint32_t *integer = reinterpret_cast<uint32_t *>(out);
  integer[0] = -a;
  integer[1] = -b;
  out[2] = typed(-encoded(0xc0a00000));
  out[3] = typed(-encoded(0xff800000));
  out[4] = typed(-input[0]);
}
extern "C" __global__ __launch_bounds__(2) void exact_relu_explicit(const float *input, _Float16 *out) {
  out[threadIdx.x] = _Float16(__builtin_fmaxf(input[threadIdx.x], 0.f));
}
extern "C" __global__ __launch_bounds__(2) void exact_relu_fused(const float *input, _Float16 *out) {
  out[threadIdx.x] = _Float16(__builtin_fmaxf(0.f, input[threadIdx.x]));
}
extern "C" __global__ __launch_bounds__(1) void exact_exp(const float *input, float *out) {
  out[0] = natural_exp(input[0]);
}
__device__ __forceinline__ float tanh_fragment(float value) {
  float e = natural_exp(2.f * value);
  return (e - 1.f) * reciprocal(e + 1.f);
}
extern "C" __global__ __launch_bounds__(1) void exact_tanh(const float *input, float *out) {
  out[0] = tanh_fragment(input[0]);
}
extern "C" __global__ __launch_bounds__(1) void exact_tanh_zero(float *out) {
  out[0] = tanh_fragment(encoded(0));
}
extern "C" __global__ __launch_bounds__(1) void exact_zero(float *out) {
  out[0] = typed(encoded(0));
}
extern "C" __global__ __launch_bounds__(1) void exact_fence_identity(float *out) {
  // Original TCGEN fences carry no data effect in this assertion. Native
  // standalone VALU/global store has no tensor operation requiring that fence.
  out[0] = typed(encoded(0x3f800000));
}

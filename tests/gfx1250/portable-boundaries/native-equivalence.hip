// Genuine gfx1250 software-equivalence controls. Mutants are CPU-only tests.
#include <hip/hip_runtime.h>

using Half = _Float16;

__device__ __forceinline__ float vector_value(float value) {
  asm volatile("" : "+v"(value));
  return value;
}
__device__ __forceinline__ unsigned integer_value(unsigned value) {
  asm volatile("v_add_nc_u32 %0, 0, %0" : "+v"(value));
  return value;
}
__device__ __forceinline__ float product_then_add(float a, float b, float c) {
  asm volatile("v_mul_f32 %0, %0, %1" : "+v"(a) : "v"(b));
  asm volatile("v_add_f32 %0, %0, %1" : "+v"(a) : "v"(c));
  return a;
}
__device__ __forceinline__ float exponential(float value) {
  // Same disclosed mathematical exp abstraction as current Volta native ports.
  return __builtin_amdgcn_exp2f(value * 0x1.715476p+0f);
}

extern "C" __global__ void constant_ref(const float *x, float *out) {
  out[0] = vector_value(x[0]) * 0.5f;
}
extern "C" __global__ void constant_mut(const float *x, float *out) {
  out[0] = vector_value(x[0]) * 0x1.000004p-1f;
}
extern "C" __global__ void sum_ref(const float *x, float *out) {
  out[0] = ((vector_value(x[0]) + x[1]) + x[2]) + x[3];
}
extern "C" __global__ void sum_dropped(const float *x, float *out) {
  out[0] = (vector_value(x[0]) + x[1]) + x[2];
}
extern "C" __global__ void sum_balanced(const float *x, float *out) {
  out[0] = (vector_value(x[0]) + x[1]) + (x[2] + x[3]);
}
extern "C" __global__ void sum_doubled_leaf(const float *x, float *out) {
  out[0] = (vector_value(x[0]) + x[1]) + (x[2] + (x[3] + x[3]));
}
extern "C" __global__ void noncommutative_ref(const float *x, float *out) {
  const float a = vector_value(x[0]);
  const float b = vector_value(x[1]);
  out[0] = a - b;
  out[1] = a * __builtin_amdgcn_rcpf(b);
}
extern "C" __global__ void noncommutative_mut(const float *x, float *out) {
  const float a = vector_value(x[0]);
  const float b = vector_value(x[1]);
  out[0] = b - a;
  out[1] = b * __builtin_amdgcn_rcpf(a);
}
extern "C" __global__ void index_ref(const float *x, float *out) {
  out[threadIdx.x] = x[threadIdx.x];
}
extern "C" __global__ void index_mut(const float *x, float *out) {
  out[threadIdx.x] = x[threadIdx.x + 1];
}
extern "C" __global__ void relu_ref(const Half *x, Half *out) {
  const float value = __builtin_fmaf(vector_value(float(x[0])), float(x[1]), float(x[2]));
  out[0] = Half(__builtin_fmaxf(value, 0.0f));
}
extern "C" __global__ void relu_mut(const Half *x, Half *out) {
  out[0] = Half(__builtin_fmaf(vector_value(float(x[0])), float(x[1]), float(x[2])));
}
extern "C" __global__ void sentinel_ref(unsigned *out) { out[0] = integer_value(0xffffffffu); }
extern "C" __global__ void sentinel_mut(unsigned *out) { out[0] = integer_value(0xfffffffeu); }
extern "C" __global__ void sentinel_not_control(unsigned *out) { out[0] = integer_value(~0u); }
extern "C" __global__ void fma_ref(const float *x, float *out) {
  out[0] = __builtin_fmaf(vector_value(x[0]), x[1], x[2]);
}
extern "C" __global__ void fma_mut(const float *x, float *out) {
  out[0] = product_then_add(x[0], x[1], x[3]);
}
extern "C" __global__ void fma_control(const float *x, float *out) {
  out[0] = product_then_add(x[0], x[1], x[2]);
}
extern "C" __global__ void maximum_ref(const float *x, float *out) {
  out[0] = __builtin_fmaxf(vector_value(x[0]), x[1]);
}
extern "C" __global__ void minimum_mut(const float *x, float *out) {
  out[0] = __builtin_fminf(vector_value(x[0]), x[1]);
}
extern "C" __global__ void exp_product_ref(const float *x, float *out) {
  out[0] = exponential(vector_value(x[0])) * exponential(vector_value(x[1]));
}
extern "C" __global__ void exp_sum_control(const float *x, float *out) {
  out[0] = exponential(vector_value(x[0]) + x[1]);
}
extern "C" __global__ void exp_product_mut(const float *x, float *out) {
  out[0] = exponential(vector_value(x[0]) * x[1]);
}
extern "C" __global__ void sign_xor_ref(const unsigned *x, unsigned *out) {
  out[0] = integer_value(x[0] ^ 0x80000000u);
}
extern "C" __global__ void sign_negate_mut(const unsigned *x, unsigned *out) {
  out[0] = integer_value(0u - x[0]);
}

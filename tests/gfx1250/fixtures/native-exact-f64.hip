// Exact binary64 counterparts for the four original scalar fixtures.
// The compiler barriers keep coefficients in registers instead of replacing
// the operations with host/compiler pre-rounded constant expressions.
#include <hip/hip_runtime.h>
#include <stdint.h>

__device__ __forceinline__ double encoded_f64(uint64_t bits) {
  union {
    uint64_t bits;
    double value;
  } encoded = {bits};
  double value = encoded.value;
  asm volatile("" : "+v"(value));
  return value;
}

extern "C" __global__ __launch_bounds__(1) void exact_f64_fma(double *out) {
  double a = encoded_f64(0x3fb999999999999aULL);
  double b = encoded_f64(0x3fc999999999999aULL);
  double c = encoded_f64(0x3fd3333333333333ULL);
  out[0] = __builtin_fma(a, b, c);
}

extern "C" __global__ __launch_bounds__(1) void exact_f64_mul_add(double *out) {
  double a = encoded_f64(0x3fb999999999999aULL);
  double b = encoded_f64(0x3fc999999999999aULL);
  double c = encoded_f64(0x3fd3333333333333ULL);
  double product = a * b;
  asm volatile("" : "+v"(product));
  out[0] = product + c;
}

extern "C" __global__ __launch_bounds__(1) void exact_f64_runtime_sum(double *out) {
  double a = encoded_f64(0x3fb999999999999aULL);
  double b = encoded_f64(0x3fc999999999999aULL);
  out[0] = a + b;
}

extern "C" __global__ __launch_bounds__(1) void exact_f64_prerounded_literal(double *out) {
  double value = encoded_f64(0x3fd3333333333334ULL);
  // Native stores carry no dtype. An exact floating +0 transport establishes
  // F64 provenance for the same encoded literal without changing its value.
  asm volatile("v_add_f64 %0, 0, %1" : "=v"(value) : "v"(value));
  out[0] = value;
}

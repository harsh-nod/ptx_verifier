// Native scalar representation fixtures, independent of matrix operations.
// Launch64threads; each array/output plane contains64elements.
#include <hip/hip_runtime.h>

extern "C" __global__ void int_ring_signed(const int *x, int *plus,
                                          int *minus, int *times) {
  unsigned t = threadIdx.x;
  int value = x[t];
  plus[t] = value + (-1);
  minus[t] = value - (-7);
  times[t] = value * (-3);
}
extern "C" __global__ void int_ring_unsigned(const unsigned *x, unsigned *plus,
                                            unsigned *minus, unsigned *times) {
  unsigned t = threadIdx.x;
  unsigned value = x[t];
  plus[t] = value + (unsigned)(-1);
  minus[t] = value - (unsigned)(-7);
  times[t] = value * (unsigned)(-3);
}
extern "C" __global__ void scalar_f64(const double *x, const double *y,
                                     const double *z, double *out) {
  unsigned t = threadIdx.x;
  double a = x[t], b = y[t], c = z[t];
  out[t] = a + b;
  out[64 + t] = a * b;
  out[128 + t] = __builtin_fma(a, b, c);
  out[192 + t] = __builtin_amdgcn_rcp(a);
  out[256 + t] = __builtin_amdgcn_sqrt(a);
  out[320 + t] = (double)(float)a;
}

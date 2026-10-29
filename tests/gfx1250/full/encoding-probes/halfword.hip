#include <hip/hip_runtime.h>

extern "C" __global__ void halfword_policy(unsigned *out) {
  if (threadIdx.x != 0) return;
  unsigned a = 0x2aaa4000u, b = 0x2aaa4200u;
  unsigned x = 0x35553c00u;
  asm volatile("v_fmac_f16_e32 %0, %1, %2" : "+v"(x) : "v"(a), "v"(b));
  out[0] = x;
  x = 0x35553c00u;
  asm volatile("v_add_f16_e32 %0, %1, %2" : "+v"(x) : "v"(a), "v"(b));
  out[1] = x;
  x = 0x35553c00u;
  asm volatile("v_mul_f16_e32 %0, %1, %2" : "+v"(x) : "v"(a), "v"(b));
  out[2] = x;
  x = 0x35553c00u;
  asm volatile("v_fmac_f16_e64 %0, %1, %2" : "+v"(x) : "v"(a), "v"(b));
  out[3] = x;
  x = 0x35553c00u;
  asm volatile("v_add_f16_e64 %0, %1, %2" : "+v"(x) : "v"(a), "v"(b));
  out[4] = x;
  x = 0x35553c00u;
  asm volatile("v_mul_f16_e64 %0, %1, %2" : "+v"(x) : "v"(a), "v"(b));
  out[5] = x;
}

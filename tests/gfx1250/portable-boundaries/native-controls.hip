// Legal native controls for static validation. Trap execution is CPU-only.
#include <hip/hip_runtime.h>
using Float4 = float __attribute__((ext_vector_type(4)));
extern "C" __global__ void control_end() {}
extern "C" __global__ void control_wait() { asm volatile("s_wait_loadcnt 0"); }
extern "C" __global__ void control_trap() { asm volatile("s_trap 7"); }
extern "C" __global__ void control_vector(const volatile Float4 *x, volatile Float4 *out) {
  *out = *x;
}

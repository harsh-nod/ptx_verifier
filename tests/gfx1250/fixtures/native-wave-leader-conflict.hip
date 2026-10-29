#include <hip/hip_runtime.h>

// A CPU-analysis negative control. Both original logical leaders reach one
// native store instruction, so wave instruction order cannot order the writers.
extern "C" __global__ __launch_bounds__(32)
void exact_wave_leader_conflict(float *out) {
  const unsigned lane = threadIdx.x;
  if (lane == 0 || lane == 16) {
    float value = lane == 16 ? 2.f : 1.f;
    asm volatile("v_add_f32 %0, 0, %1" : "=v"(value) : "v"(value));
    out[0] = value;
  }
}

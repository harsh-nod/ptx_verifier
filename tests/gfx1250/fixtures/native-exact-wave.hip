#include <hip/hip_runtime.h>

__device__ __forceinline__ float typed_float(float value) {
  asm volatile("v_add_f32 %0, 0, %1" : "=v"(value) : "v"(value));
  return value;
}

extern "C" __global__ __launch_bounds__(32) void exact_wave_elect(float *out) {
  const unsigned lane = threadIdx.x;
  const unsigned first = __builtin_amdgcn_readfirstlane(lane);
  out[lane] = typed_float(lane == first ? float(1000 + first) : 0.f);
}

extern "C" __global__ __launch_bounds__(32) void exact_wave_elect_skip(float *out) {
  const unsigned lane = threadIdx.x;
  if (lane == 0) return;
  const unsigned first = __builtin_amdgcn_readfirstlane(lane);
  out[lane] = typed_float(lane == first ? float(1000 + first) : 0.f);
}

extern "C" __global__ __launch_bounds__(2) void exact_wave_exchange(const float *input,
                                                                  float *out) {
  const unsigned lane = threadIdx.x;
  out[lane] = typed_float(__shfl(input[lane], int(lane ^ 1), 32));
}

extern "C" __global__ __launch_bounds__(32) void exact_wave_tail_sum(const float *input,
                                                                    float *out) {
  const unsigned lane = threadIdx.x;
  if (lane >= 16) return;
  float value = input[lane];
#pragma unroll
  for (unsigned distance = 8; distance; distance >>= 1) {
    // The original discards results from exited source lanes. Native DS reads
    // instead select the caller in those unused slots, keeping every read defined.
    const bool contributes = lane + distance < 16;
    const unsigned source = contributes ? lane + distance : lane;
    const float next = __shfl(value, int(source), 32);
    if (contributes) value += next;
  }
  if (lane == 0) out[0] = typed_float(value);
}

extern "C" __global__ __launch_bounds__(1) void exact_wave_tail_reference(const float *input,
                                                                         float *out) {
  float value = input[0];
#pragma unroll
  for (unsigned i = 1; i < 16; ++i) value += input[i];
  out[0] = typed_float(value);
}

extern "C" __global__ __launch_bounds__(32) void exact_wave_divergent_leaders(float *out) {
  const unsigned lane = threadIdx.x;
  if (lane < 16) {
    const unsigned first = __builtin_amdgcn_readfirstlane(lane);
    if (lane == first) out[0] = typed_float(1.f);
  } else {
    const unsigned first = __builtin_amdgcn_readfirstlane(lane);
    if (lane == first) out[1] = typed_float(2.f);
  }
}

extern "C" __global__ __launch_bounds__(64) void exact_wave_memory_exchange(const float *input,
                                                                           float *out) {
  __shared__ volatile float staged[64];
  const unsigned lane = threadIdx.x;
  staged[lane] = input[lane];
  float exchanged = __shfl(float(lane), int((lane & 31) ^ 1), 32);
  asm volatile("" : "+v"(exchanged));
  __syncthreads();
  out[lane] = typed_float(staged[lane ^ 32] + exchanged * 0.f);
}

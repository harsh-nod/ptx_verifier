#include <hip/hip_runtime.h>

extern "C" __global__ void phase_identity(const float *in, float *out) {
  __syncthreads();
  if (threadIdx.x == 0)
    out[0] = in[0];
}

extern "C" __global__ void remaining_wave_progress(const float *in, float *out) {
  if (threadIdx.x >= 32)
    return;
  __syncthreads();
  out[threadIdx.x] = in[threadIdx.x];
}

// CPU-only publication control: completion before END does not itself pin
// an arrive-release contract for the implicitly dropped workgroup barrier.
extern "C" __global__ void exited_writer_no_arrival(const float *in, float *out) {
  __shared__ float words[32];
  unsigned index = threadIdx.x & 31;
  if (threadIdx.x >= 32) {
    words[index] = in[index];
    asm volatile("s_wait_dscnt 0" ::: "memory");
    return;
  }
  __syncthreads();
  out[index] = words[index];
}

extern "C" __global__ void arrived_writer_then_exit(const float *in, float *out) {
  __shared__ float words[32];
  unsigned index = threadIdx.x & 31;
  if (threadIdx.x >= 32)
    words[index] = in[index];
  __syncthreads();
  if (threadIdx.x >= 32)
    return;
  out[index] = words[index];
}

extern "C" __global__ void two_generation_two_consumers(const float *in, float *out) {
  __shared__ float word;
  const unsigned role = threadIdx.x >> 5;
  const unsigned lane = threadIdx.x & 31;
#pragma unroll
  for (unsigned generation = 0; generation < 2; ++generation) {
    if (role == 0 && lane == 0)
      word = in[generation];
    __syncthreads();
    if (role != 0 && lane == 0)
      out[(role - 1) * 2 + generation] = word;
    __syncthreads();
  }
}

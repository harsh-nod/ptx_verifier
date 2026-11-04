#include <hip/hip_runtime.h>
#include <stdint.h>

// Deliberately harmful controls are for CPU analysis only.
extern "C" __global__ __launch_bounds__(32)
void payload_same_value(const float *input, float *output) {
  __shared__ volatile float slot;
  const unsigned t = threadIdx.x;
  if (t < 2) slot = input[0] * 2.f;
  __syncthreads();
  if (t == 0) output[0] = slot;
}

extern "C" __global__ __launch_bounds__(32)
void payload_different_values(const float *, float *output) {
  __shared__ volatile float slot;
  const unsigned t = threadIdx.x;
  if (t < 2) slot = float(t);
  __syncthreads();
  if (t == 0) output[0] = slot;
}

extern "C" __global__ __launch_bounds__(32)
void payload_shared_writers() {
  __shared__ volatile unsigned slot[2];
  const unsigned t = threadIdx.x;
  if (t < 2) slot[0] = t;
}

extern "C" __global__ __launch_bounds__(32)
void payload_address_alias(unsigned *output) {
  const unsigned t = threadIdx.x;
  if (t < 2) output[(4 | 4) / sizeof(unsigned)] = t + 1;
}

// Logical actors0/1 map to physical workitems0/32. Initialization is a
// separate completed phase, keeping the publication-removal candidate defined.
extern "C" __global__ __launch_bounds__(64)
void payload_neighbor_exchange(const float *input, float *output) {
  __shared__ volatile float slot[2];
  const unsigned t = threadIdx.x;
  if (t == 0) { slot[0] = 0.f; slot[1] = 0.f; }
  __syncthreads();
  if (t == 0 || t == 32) slot[t / 32] = input[t / 32];
  __syncthreads();
  if (t == 0 || t == 32) output[t / 32] = slot[(t / 32) ^ 1];
}

extern "C" __global__ __launch_bounds__(64)
void payload_ordered_equal_values(const float *input, float *output) {
  __shared__ volatile float slot;
  const unsigned t = threadIdx.x;
  if (t == 0) slot = input[0] * 2.f;
  __syncthreads();
  if (t == 32) slot = input[0] * 2.f;
  __syncthreads();
  if (t == 0) output[0] = slot;
}

extern "C" __global__ __launch_bounds__(64)
void payload_publish_42(unsigned *output) {
  __shared__ volatile unsigned slot;
  const unsigned t = threadIdx.x;
  if (t == 0) slot = 42;
  __syncthreads();
  if (t == 32) {
    unsigned value = slot;
    asm volatile("v_add_nc_u32 %0, 0, %1" : "=v"(value) : "v"(value));
    output[0] = value;
  }
}

extern "C" __global__ __launch_bounds__(64)
void payload_address_broadcast() {
  __shared__ volatile unsigned object;
  __shared__ volatile unsigned address_slot;
  const unsigned t = threadIdx.x;
  if (t == 0) address_slot = unsigned(uintptr_t(&object));
  unsigned lane_value = __shfl(t, 0, 32);
  asm volatile("" : "+v"(lane_value));
  __syncthreads();
  if (t >= 32 && t < 63) {
    const unsigned address = address_slot;
    asm volatile("" : : "v"(address));
  }
}

extern "C" __global__ __launch_bounds__(64)
void payload_collective_then_publish(float *output) {
  __shared__ volatile unsigned slot;
  const unsigned t = threadIdx.x;
  if (t == 1) slot = 1;
  unsigned lane_value = __shfl(t, 0, 32);
  asm volatile("" : "+v"(lane_value));
  __syncthreads();
  if (t == 32) output[0] = float(slot);
}

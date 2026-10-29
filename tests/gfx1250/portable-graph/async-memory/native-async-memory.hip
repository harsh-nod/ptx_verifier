#include <hip/hip_runtime.h>
#include <stdint.h>

using UInt4 = unsigned __attribute__((ext_vector_type(4)));
using Int4 = int __attribute__((ext_vector_type(4)));
using Int8 = int __attribute__((ext_vector_type(8)));

__device__ __forceinline__ UInt4 descriptor(const float *global, unsigned lds) {
  uint64_t address = reinterpret_cast<uint64_t>(global);
  return {1, lds, unsigned(address), unsigned((address >> 32) & 0x1ffffffu) | 0x80000000u};
}

__device__ __forceinline__ float real_value(float value) {
  asm volatile("v_add_f32 %0, 0, %0" : "+v"(value));
  return value;
}

template <unsigned N, bool CrossWave>
__device__ __forceinline__ void copy_payload(const float *input, float *out) {
  __shared__ volatile float tile[N];
  unsigned tid = threadIdx.x;
  const Int8 shape = {2 << 16, N << 16, 1 << 16, N << 16, 1, N, 0, 0};
  const Int4 zero = {};
  if (tid == 0)
    __builtin_amdgcn_tensor_load_to_lds(
        descriptor(input, unsigned(reinterpret_cast<uintptr_t>(tile))), shape, zero, zero, 0);
  __builtin_amdgcn_s_wait_tensorcnt(0);
  if (CrossWave)
    __syncthreads();
  if (tid == (CrossWave ? 32 : 0)) {
#pragma unroll
    for (unsigned i = 0; i < N; ++i)
      out[i] = tile[i];
  }
}

extern "C" __global__ __launch_bounds__(64) void async_copy4_same_actor(const float *input, float *out) {
  copy_payload<1, false>(input, out);
}
extern "C" __global__ __launch_bounds__(64) void async_copy16_same_actor(const float *input, float *out) {
  copy_payload<4, false>(input, out);
}
extern "C" __global__ __launch_bounds__(64) void async_copy4_cross_wave(const float *input, float *out) {
  copy_payload<1, true>(input, out);
}
extern "C" __global__ __launch_bounds__(64) void async_copy16_cross_wave(const float *input, float *out) {
  copy_payload<4, true>(input, out);
}

template <bool CrossWave>
__device__ __forceinline__ void destination_reuse(const float *input, float *out) {
  __shared__ volatile float tile[1];
  unsigned tid = threadIdx.x;
  const Int8 shape = {2 << 16, 1 << 16, 1 << 16, 1 << 16, 1, 1, 0, 0};
  const Int4 zero = {};
  if (tid == 0)
    __builtin_amdgcn_tensor_load_to_lds(
        descriptor(input, unsigned(reinterpret_cast<uintptr_t>(tile))), shape, zero, zero, 0);
  __builtin_amdgcn_s_wait_tensorcnt(0);
  if (CrossWave)
    __syncthreads();
  if (tid == (CrossWave ? 32 : 0)) {
    tile[0] = real_value(input[1]);
    out[0] = real_value(tile[0]);
  }
}

extern "C" __global__ __launch_bounds__(64) void async_copy4_destination_reuse_same_actor(
    const float *input, float *out) {
  destination_reuse<false>(input, out);
}
extern "C" __global__ __launch_bounds__(64) void async_copy4_destination_reuse_cross_wave(
    const float *input, float *out) {
  destination_reuse<true>(input, out);
}

extern "C" __global__ __launch_bounds__(64) void async_copy16_source_reuse(const float *input,
                                                                         float *out) {
  __shared__ volatile float tile[4];
  unsigned tid = threadIdx.x;
  if (tid < 4)
    tile[tid] = real_value(input[tid]);
  __syncthreads();
  const Int8 shape = {2 << 16, 4 << 16, 1 << 16, 4 << 16, 1, 4, 0, 0};
  const Int4 zero = {};
  if (tid == 0)
    __builtin_amdgcn_tensor_store_from_lds(
        descriptor(out, unsigned(reinterpret_cast<uintptr_t>(tile))), shape, zero, zero, 0);
  __builtin_amdgcn_s_wait_tensorcnt(0);
  __syncthreads();
  if (tid == 32) {
    tile[0] = real_value(input[4]);
    out[4] = real_value(tile[0]);
  }
}

extern "C" __global__ __launch_bounds__(64) void async_two_16byte_regions(const float *input,
                                                                        float *out) {
  __shared__ volatile float tile[8];
  unsigned tid = threadIdx.x;
  const Int8 shape = {2 << 16, 4 << 16, 1 << 16, 4 << 16, 1, 4, 0, 0};
  const Int4 zero = {};
  if (tid == 0) {
    unsigned shared = unsigned(reinterpret_cast<uintptr_t>(tile));
    __builtin_amdgcn_tensor_load_to_lds(descriptor(input, shared), shape, zero, zero, 0);
    __builtin_amdgcn_tensor_load_to_lds(descriptor(input + 4, shared + 16), shape, zero, zero, 0);
  }
  __builtin_amdgcn_s_wait_tensorcnt(0);
  __syncthreads();
  out[tid] = tile[4];
}

extern "C" __global__ __launch_bounds__(64) void async_no_output128_reuse(const float *input,
                                                                        float *unused) {
  __shared__ volatile float tile[32];
  unsigned tid = threadIdx.x;
  const Int8 shape = {2 << 16, 32 << 16, 1 << 16, 32 << 16, 1, 32, 0, 0};
  const Int4 zero = {};
  if (tid == 0)
    __builtin_amdgcn_tensor_load_to_lds(
        descriptor(input, unsigned(reinterpret_cast<uintptr_t>(tile))), shape, zero, zero, 0);
  __builtin_amdgcn_s_wait_tensorcnt(0);
  __syncthreads();
  if (tid >= 32)
    tile[tid - 32] = real_value(input[tid]);
}

extern "C" __global__ __launch_bounds__(64) void async_copy4_global_source_reuse(
    volatile float *input, float *out) {
  __shared__ volatile float tile[1];
  unsigned tid = threadIdx.x;
  const Int8 shape = {2 << 16, 1 << 16, 1 << 16, 1 << 16, 1, 1, 0, 0};
  const Int4 zero = {};
  if (tid == 0)
    __builtin_amdgcn_tensor_load_to_lds(
        descriptor(const_cast<const float *>(input), unsigned(reinterpret_cast<uintptr_t>(tile))),
        shape, zero, zero, 0);
  __builtin_amdgcn_s_wait_tensorcnt(0);
  __syncthreads();
  if (tid == 32) {
    input[0] = input[1];
    out[0] = tile[0];
  }
}

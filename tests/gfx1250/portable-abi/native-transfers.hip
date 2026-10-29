#include <hip/hip_runtime.h>

using Float4 = float __attribute__((ext_vector_type(4)));

// An explicit unsigned identity disambiguates B32 constants after raw memory
// transport; it preserves every bit and does not infer a dtype from a pointer.
__device__ __forceinline__ unsigned output_u32(unsigned value) {
  asm volatile("v_add_nc_u32 %0, 0, %0" : "+v"(value));
  return value;
}

extern "C" __global__ void abi_shared_words(const float *x, float *out) {
  __shared__ __align__(16) volatile float words[4];
  words[0] = x[0];
  words[1] = x[1];
  words[2] = x[2];
  words[3] = x[3];
  __syncthreads();
  const Float4 value = *reinterpret_cast<const volatile Float4 *>(words);
  out[0] = value[0];
  out[1] = value[1];
  out[2] = value[2];
  out[3] = value[3];
}

extern "C" __global__ void abi_half_pair(const _Float16 *x, _Float16 *out) {
  __shared__ volatile _Float16 words[2];
  words[0] = x[0];
  words[1] = x[1];
  __syncthreads();
  out[0] = words[0];
  out[1] = words[1];
}

extern "C" __global__ void abi_byte_pair(const unsigned char *x, unsigned char *out) {
  __shared__ volatile unsigned char words[2];
  words[0] = x[0];
  words[1] = x[1];
  __syncthreads();
  out[0] = words[0];
  out[1] = words[1];
}

extern "C" __global__ void abi_scalar_granule(const _Float16 *x, float *out) {
  __shared__ volatile unsigned word;
  word = 0;
  volatile _Float16 *halves = reinterpret_cast<volatile _Float16 *>(&word);
  halves[1] = x[0];
  __syncthreads();
  out[0] = static_cast<float>(halves[0]) + static_cast<float>(halves[1]);
}

extern "C" __global__ void abi_pair_truncation(unsigned *out) {
  __shared__ __align__(4) volatile unsigned short words[3];
  words[0] = 1;
  words[1] = 2;
  const unsigned packed = *reinterpret_cast<volatile unsigned *>(words);
  words[2] = static_cast<unsigned short>(packed);
  __syncthreads();
  out[0] = output_u32(words[0]);
  out[1] = output_u32(words[1]);
  out[2] = output_u32(words[2]);
}

extern "C" __global__ void abi_logical_partitions(unsigned *out) {
  __shared__ volatile unsigned words[64];
  const unsigned index = threadIdx.x;
  words[index] = index / 32;
  __syncthreads();
  out[index] = words[index];
}

extern "C" __global__ void abi_global_vector_last(const float *x, float *out) {
  const Float4 value = *reinterpret_cast<const volatile Float4 *>(x);
  out[0] = value[3];
}

extern "C" __global__ void abi_half_at_two_mod_four(const _Float16 *x, _Float16 *out) {
  out[1] = x[1];
}

extern "C" __global__ void abi_upper_address(const float *x, float *out) { out[0] = x[4]; }

extern "C" __global__ void abi_negative_index(const float *x, float *out) { out[0] = x[-1]; }

extern "C" __global__ void abi_rank_zero_offsets(unsigned *out) {
  out[threadIdx.x] = threadIdx.x * 4;
}

extern "C" __global__ void abi_shared_array_tail(unsigned *out) {
  __shared__ volatile unsigned words[48];
  const unsigned index = threadIdx.x;
  if (index < 48)
    words[index] = index;
  __syncthreads();
  out[index] = words[index];
}

extern "C" __global__ void abi_region_edge(unsigned *out) {
  using UInt4 = unsigned __attribute__((ext_vector_type(4)));
  __shared__ __align__(16) volatile unsigned words[12];
  words[8] = 1;
  words[9] = 2;
  words[10] = 3;
  words[11] = 7;
  __syncthreads();
  const UInt4 value = *reinterpret_cast<const volatile UInt4 *>(words + 8);
  out[0] = output_u32(words[11]);
  out[1] = output_u32(value[0]);
}

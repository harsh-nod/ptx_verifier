// Shared descriptor publication is ordinary AMD memory ordering. TDM receives
// scalar register descriptors, unlike a memory-backed NVIDIA tensor map.
#include <hip/hip_runtime.h>
#include <stdint.h>
using Half = _Float16;
using UInt4 = unsigned __attribute__((ext_vector_type(4)));
using Int4 = int __attribute__((ext_vector_type(4)));
using Int8 = int __attribute__((ext_vector_type(8)));
struct alignas(32) DescriptorWords {
  UInt4 d0;
  Int8 d1;
  Int4 zero;
};

__device__ __forceinline__ UInt4 descriptor(const Half *global, unsigned lds) {
  uint64_t address = reinterpret_cast<uint64_t>(global);
  return {1, lds, unsigned(address), unsigned((address >> 32) & 0x1ffffffu) | 0x80000000u};
}

__device__ __forceinline__ Half half_zero() {
  Half value = 0;
  asm volatile("v_add_f16 %0, %0, %0" : "+v"(value));
  return value;
}

template <bool ConcurrentFieldWrite, bool RewriteAfterCapture>
__device__ __forceinline__ void published_crop(const Half *input, Half *out, unsigned origin) {
  __shared__ Half crop[4];
  __shared__ Half padded[16];
  __shared__ volatile DescriptorWords metadata;
  unsigned tid = threadIdx.x;
  if (tid < 16)
    padded[tid] = half_zero();
  if (tid == 0) {
    metadata.d0 = descriptor(input + origin, unsigned(reinterpret_cast<uintptr_t>(crop)));
    metadata.d1 = Int8{1 << 16, 2 << 16, 2 << 16, 2 << 16, 2, 8, 0, 0};
    metadata.zero = Int4{};
  }
  if (ConcurrentFieldWrite && tid == 32)
    metadata.d0 = descriptor(input + 53, unsigned(reinterpret_cast<uintptr_t>(crop)));
  __syncthreads();
  if (tid == 32) {
    UInt4 d0 = metadata.d0;
    Int8 d1 = metadata.d1;
    Int4 zero = metadata.zero;
    __builtin_amdgcn_tensor_load_to_lds(d0, d1, zero, zero, 0);
    if (RewriteAfterCapture)
      metadata.d0[2] = unsigned(reinterpret_cast<uintptr_t>(input + 53));
  }
  __builtin_amdgcn_s_wait_tensorcnt(0);
  __syncthreads();
  if (tid < 4)
    padded[(tid / 2) * 4 + tid % 2] = crop[tid];
  __syncthreads();
  if (tid < 16)
    out[tid] = padded[tid];
}

extern "C" __global__ __launch_bounds__(64) void tensor_metadata_ordered(const Half *input,
                                                                         Half *out) {
  published_crop<false, false>(input, out, 54);
}
extern "C" __global__ __launch_bounds__(64) void tensor_metadata_field_race(const Half *input,
                                                                            Half *out) {
  published_crop<true, false>(input, out, 54);
}
extern "C" __global__
__launch_bounds__(64) void tensor_metadata_rewrite_after_capture(const Half *input, Half *out) {
  published_crop<false, true>(input, out, 54);
}

extern "C" __global__ __launch_bounds__(64) void tensor_metadata_wrong_object(const Half *input,
                                                                              Half *out) {
  published_crop<false, false>(input, out, 53);
}

// Two ordinary shared-memory descriptor objects make the copy's source read and
// destination write explicit. They are not NVIDIA proxy-domain objects.
template <bool ConcurrentReplace>
__device__ __forceinline__ void copied_crop(const Half *input, Half *out) {
  __shared__ Half crop[4];
  __shared__ Half padded[16];
  __shared__ volatile DescriptorWords source;
  __shared__ volatile DescriptorWords destination;
  unsigned tid = threadIdx.x;
  if (tid < 16)
    padded[tid] = half_zero();
  if (tid == 0) {
    source.d0 = descriptor(input + 54, unsigned(reinterpret_cast<uintptr_t>(crop)));
    source.d1 = Int8{1 << 16, 2 << 16, 2 << 16, 2 << 16, 2, 8, 0, 0};
    source.zero = Int4{};
  }
  __syncthreads();
  if (tid == 0) {
    destination.d0 = source.d0;
    destination.d1 = source.d1;
    destination.zero = source.zero;
  }
  if (ConcurrentReplace && tid == 32) {
    UInt4 replacement = descriptor(input + 53, unsigned(reinterpret_cast<uintptr_t>(crop)));
    source.d0 = replacement;
    destination.d0 = replacement;
  }
  __syncthreads();
  if (tid == 32) {
    UInt4 d0 = destination.d0;
    Int8 d1 = destination.d1;
    Int4 zero = destination.zero;
    __builtin_amdgcn_tensor_load_to_lds(d0, d1, zero, zero, 0);
  }
  __builtin_amdgcn_s_wait_tensorcnt(0);
  __syncthreads();
  if (tid < 4)
    padded[(tid / 2) * 4 + tid % 2] = crop[tid];
  __syncthreads();
  if (tid < 16)
    out[tid] = padded[tid];
}

extern "C" __global__ __launch_bounds__(64) void tensor_metadata_copied(const Half *input,
                                                                        Half *out) {
  copied_crop<false>(input, out);
}
extern "C" __global__
__launch_bounds__(64) void tensor_metadata_copy_replace_race(const Half *input, Half *out) {
  copied_crop<true>(input, out);
}

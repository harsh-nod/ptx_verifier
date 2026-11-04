#include <hip/hip_runtime.h>

using float4_native = float __attribute__((ext_vector_type(4)));

extern "C" __global__ void copy_scalar_same_wave(const float *in, float *out) {
  __shared__ volatile float word;
  if (threadIdx.x == 0) {
    word = in[0];
    asm volatile("s_wait_dscnt 0" ::: "memory");
    out[0] = word;
  }
}

extern "C" __global__ void copy_scalar_cross_wave(const float *in, float *out) {
  __shared__ volatile float word;
  if (threadIdx.x == 0)
    word = in[0];
  __syncthreads();
  if (threadIdx.x == 32)
    out[0] = word;
}

extern "C" __global__ void copy_both_regions_before_publication(const float *in,
                                                              float *out) {
  __shared__ __align__(16) float words[8];
  if (threadIdx.x == 0) {
    *reinterpret_cast<volatile float4_native *>(words) =
        *reinterpret_cast<const float4_native *>(in);
    *reinterpret_cast<volatile float4_native *>(words + 4) =
        *reinterpret_cast<const float4_native *>(in + 4);
  }
  __syncthreads();
  out[threadIdx.x] = reinterpret_cast<volatile float *>(words)[4];
}

extern "C" __global__ void copy_two_completed_regions(const float *in,
                                                     float *out) {
  __shared__ __align__(16) float words[8];
  if (threadIdx.x == 0) {
    *reinterpret_cast<volatile float4_native *>(words) =
        *reinterpret_cast<const float4_native *>(in);
    asm volatile("s_wait_dscnt 0" ::: "memory");
    out[0] = reinterpret_cast<volatile float *>(words)[0];
    asm volatile("s_wait_dscnt 0" ::: "memory");
    *reinterpret_cast<volatile float4_native *>(words + 4) =
        *reinterpret_cast<const float4_native *>(in + 4);
    asm volatile("s_wait_dscnt 0" ::: "memory");
    out[1] = reinterpret_cast<volatile float *>(words)[4];
  }
}

extern "C" __global__ void copy_result_dependency_ids(float *out) {
  __shared__ volatile float words[32];
  const unsigned id = threadIdx.x;
  words[id] = static_cast<float>(id);
  asm volatile("s_wait_dscnt 0" ::: "memory");
  out[id] = words[id];
}

extern "C" __global__ void copy_every_actual_reader_waits(const float *in) {
  __shared__ __align__(16) float words[4];
  if (threadIdx.x == 0)
    *reinterpret_cast<volatile float4_native *>(words) =
        *reinterpret_cast<const float4_native *>(in);
  __syncthreads();
  if (threadIdx.x >= 32)
    (void)reinterpret_cast<volatile float *>(words)[0];
}

#include <hip/hip_runtime.h>

using UInt2 = unsigned __attribute__((ext_vector_type(2)));

__device__ __forceinline__ unsigned integer_value(unsigned value) {
  asm volatile("v_add_nc_u32 %0, 0, %0" : "+v"(value));
  return value;
}

extern "C" __global__ __launch_bounds__(64) void ended_reader(unsigned *out, unsigned ordered) {
  __shared__ volatile unsigned word;
  unsigned tid = threadIdx.x;
  if (tid == 0)
    word = integer_value(42);
  __syncthreads();
  if (tid == 0) {
    unsigned value = word;
    asm volatile("" : : "v"(value) : "memory");
  }
  asm volatile("s_wait_dscnt 0" : : : "memory");
  if (ordered)
    __syncthreads();
  if (tid < 32)
    return;
  __builtin_amdgcn_wave_barrier();
  if (tid == 32)
    word = integer_value(7);
}

extern "C" __global__ __launch_bounds__(64) void ended_writer(unsigned *out, unsigned ordered) {
  __shared__ volatile unsigned word;
  unsigned tid = threadIdx.x;
  if (tid == 0)
    word = integer_value(0);
  __syncthreads();
  if (tid == 0)
    word = integer_value(42);
  asm volatile("s_wait_dscnt 0" : : : "memory");
  if (ordered)
    __syncthreads();
  if (tid < 32)
    return;
  __builtin_amdgcn_wave_barrier();
  if (tid == 32)
    out[0] = integer_value(word);
}

extern "C" __global__ __launch_bounds__(64) void metadata_eight_bytes(unsigned *out,
                                                                    unsigned ordered) {
  __shared__ volatile UInt2 metadata;
  unsigned tid = threadIdx.x;
  if (tid == 32) {
    metadata = UInt2{integer_value(1), integer_value(0)};
  }
  asm volatile("s_wait_dscnt 0" : : : "memory");
  if (ordered)
    __syncthreads();
  if (tid == 0) {
    metadata = UInt2{integer_value(42), integer_value(0)};
    UInt2 value = metadata;
    out[0] = integer_value(value[0]);
    out[1] = integer_value(value[1]);
  }
}

extern "C" __global__ __launch_bounds__(32) void undefined_shuffle_source(const unsigned *input,
                                                                         unsigned *out,
                                                                         unsigned initialize_all) {
  unsigned tid = threadIdx.x;
  if (initialize_all || tid < 16) {
    unsigned value = integer_value(input[tid]);
    asm volatile("v_mov_b32 v20, %0" : : "v"(value) : "v20");
  }
  unsigned shuffled;
  unsigned index = (tid + 8) * 4;
  asm volatile("ds_bpermute_b32 %0, %1, v20\n\ts_wait_dscnt 0"
               : "=v"(shuffled) : "v"(index) : "v20", "memory");
  if (tid < 16)
    out[tid] = integer_value(shuffled);
}

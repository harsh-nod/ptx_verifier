// Two wave32 WMMA tiles, two K32 stages, complete row-major M32 N16 K64.
// Both waves publish each next LDS buffer; the first stage's register operands
// are captured before the other buffer is published. No target runtime used.
#include <hip/hip_runtime.h>
typedef _Float16 half16v __attribute__((ext_vector_type(16)));
typedef float float8v __attribute__((ext_vector_type(8)));
extern "C" __global__ __launch_bounds__(64)
void gemm_pipeline_f16(const _Float16 *a, const _Float16 *b, float *out) {
  __shared__ _Float16 as[2][32 * 32];
  __shared__ _Float16 bs[2][16 * 32];
  unsigned t = threadIdx.x, lane = t & 31, wave = t / 32;
  for (unsigned j = t; j < 32 * 32; j += 64)
    as[0][j] = a[(j / 32) * 64 + j % 32];
  for (unsigned j = t; j < 16 * 32; j += 64)
    bs[0][j] = b[(j / 32) * 64 + j % 32];
  __syncthreads();
  float8v accum = {};
  #pragma unroll
  for (unsigned stage = 0; stage < 2; ++stage) {
    half16v av, bv;
    #pragma unroll
    for (unsigned j = 0; j < 16; ++j) {
      unsigned k = (j / 8) * 16 + (lane / 16) * 8 + j % 8;
      av[j] = as[stage][(wave * 16 + lane % 16) * 32 + k];
      bv[j] = bs[stage][(lane % 16) * 32 + k];
    }
    if (stage == 0) {
      for (unsigned j = t; j < 32 * 32; j += 64)
        as[1][j] = a[(j / 32) * 64 + 32 + j % 32];
      for (unsigned j = t; j < 16 * 32; j += 64)
        bs[1][j] = b[(j / 32) * 64 + 32 + j % 32];
      __syncthreads();
    }
    accum = __builtin_amdgcn_wmma_f32_16x16x32_f16(
        false, av, false, bv, 0, accum, false, false);
  }
  #pragma unroll
  for (unsigned j = 0; j < 8; ++j)
    out[(wave * 16 + (lane / 16) * 8 + j) * 16 + lane % 16] = accum[j];
}

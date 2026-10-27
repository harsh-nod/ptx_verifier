// Actual FlashSinkhornFusedSchurMatvec:32 fixed rows,1024 reduction rows,D64.
// Output f=0.5*(f_hat-LSE(2*dot(x,y)+g_hat+log_b)); symmetric g update supported.
// Encoded base2 scoring/LSE constants and the final denominator floor are kept.
#include <hip/hip_runtime.h>
typedef _Float16 half4v __attribute__((ext_vector_type(4)));
typedef _Float16 half8v __attribute__((ext_vector_type(8)));
typedef float float4v __attribute__((ext_vector_type(4)));

__device__ __forceinline__ float sinkhorn_max16(float value) {
#pragma unroll
  for (unsigned d = 8; d; d >>= 1) value = fmaxf(value, __shfl_xor(value, d, 16));
  return value;
}
__device__ __forceinline__ float sinkhorn_sum16(float value) {
#pragma unroll
  for (unsigned d = 8; d; d >>= 1) value += __shfl_xor(value, d, 16);
  return value;
}
extern "C" __global__ __launch_bounds__(128)
void flash_sinkhorn_full(const _Float16 *x, const _Float16 *y,
                         const float *f_hat, const float *g_hat,
                         const float *log_a, const float *log_b,
                         float *f_out, float *g_out) {
  __shared__ _Float16 stage[2][1024];
  unsigned t = threadIdx.x, lane = t & 63, wave = t >> 6;
  bool update_f = blockIdx.x < 32;
  unsigned fixed_base = (blockIdx.x & 31) * 32;
  const _Float16 *fixed = update_f ? x : y;
  const _Float16 *reduction = update_f ? y : x;
  const float *fixed_potential = update_f ? f_hat : g_hat;
  const float *potential = update_f ? g_hat : f_hat;
  const float *log_weight = update_f ? log_b : log_a;
  float *out = update_f ? f_out : g_out;
#pragma unroll
  for (unsigned j = 0; j < 8; ++j) stage[0][t + j * 128] = reduction[t + j * 128];
  __syncthreads();
  float4v maximum = {}, denominator = {};
#pragma unroll 1
  for (unsigned tile = 0; tile < 64; ++tile) {
    half8v next;
    if (tile + 1 < 64) {
#pragma unroll
      for (unsigned j = 0; j < 8; ++j) next[j] = reduction[(tile + 1) * 1024 + t + j * 128];
    }
    unsigned slot = tile & 1;
    float4v score = {};
#pragma unroll
    for (unsigned feature_tile = 0; feature_tile < 4; ++feature_tile) {
      half4v a, b;
#pragma unroll
      for (unsigned j = 0; j < 4; ++j) {
        unsigned d = feature_tile * 16 + (lane >> 4) * 4 + j;
        a[j] = fixed[(fixed_base + wave * 16 + (lane & 15)) * 64 + d];
        b[j] = stage[slot][(lane & 15) * 64 + d];
      }
      score = __builtin_amdgcn_mfma_f32_16x16x16f16(a, b, score, 0, 0, 0);
    }
    unsigned key = tile * 16 + (lane & 15);
    float bias = __builtin_fmaf(potential[key], 0x1.715476p+0f,
                                log_weight[key] * 0x1.715476p+0f);
#pragma unroll
    for (unsigned j = 0; j < 4; ++j) {
      score[j] = __builtin_fmaf(score[j], 0x1.715476p+1f, bias);
      float local_max = sinkhorn_max16(score[j]);
      float next_max = tile == 0 ? local_max : fmaxf(maximum[j], local_max);
      float alpha = tile == 0 ? 0.0f : __builtin_amdgcn_exp2f(maximum[j] - next_max);
      float p = __builtin_amdgcn_exp2f(score[j] - next_max);
      denominator[j] = __builtin_fmaf(denominator[j], alpha, sinkhorn_sum16(p));
      maximum[j] = next_max;
    }
    __syncthreads();
    if (tile + 1 < 64) {
#pragma unroll
      for (unsigned j = 0; j < 8; ++j) stage[slot ^ 1][t + j * 128] = next[j];
    }
    __syncthreads();
  }
  if ((lane & 15) == 0) {
#pragma unroll
    for (unsigned j = 0; j < 4; ++j) {
      unsigned row = fixed_base + wave * 16 + (lane >> 4) * 4 + j;
      float safe_sum = fmaxf(denominator[j], __builtin_bit_cast(float, 0x000116c2u));
      float lse = (maximum[j] + __builtin_amdgcn_logf(safe_sum)) * 0x1.62e43p-1f;
      out[row] = __builtin_fmaf(lse, -0.5f, fixed_potential[row] * 0.5f);
    }
  }
}

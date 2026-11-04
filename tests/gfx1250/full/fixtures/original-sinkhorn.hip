// Original Sinkhorn selected workgroup:32 rows,1024 reduction keys,D64,F16 inputs.
// Scalar potentials remain F32. The unused original ABI pointers are preserved.
#include <hip/hip_runtime.h>
typedef _Float16 sinkhorn_half16 __attribute__((ext_vector_type(16)));
typedef float sinkhorn_float8 __attribute__((ext_vector_type(8)));

__device__ __forceinline__ float sinkhorn_reduce_max(float value) {
#pragma unroll
  for (unsigned delta = 8; delta; delta >>= 1)
    value = fmaxf(value, __shfl_xor(value, delta, 16));
  return value;
}
__device__ __forceinline__ float sinkhorn_reduce_sum(float value) {
#pragma unroll
  for (unsigned delta = 8; delta; delta >>= 1)
    value += __shfl_xor(value, delta, 16);
  return value;
}
extern "C" __global__ __launch_bounds__(256) void sinkhorn_original(
    const _Float16 *x, const _Float16 *y, const float *f_hat, const float *g_hat,
    const float *log_a, const float *log_b, float *f_out, float *g_out, const void *label_x,
    const void *label_y, const void *weight) {
  __shared__ _Float16 stage[2][1024];
  unsigned thread = threadIdx.x, lane = thread & 31, wave = thread / 32;
  bool update_f = blockIdx.x < 32;
  unsigned fixed_base = (blockIdx.x & 31) * 32;
  const _Float16 *fixed = update_f ? x : y, *reduction = update_f ? y : x;
  const float *fixed_potential = update_f ? f_hat : g_hat;
  const float *potential = update_f ? g_hat : f_hat, *log_weight = update_f ? log_b : log_a;
  float *output = update_f ? f_out : g_out;
  for (unsigned i = thread; i < 1024; i += 256)
    stage[0][i] = reduction[i];
  __syncthreads();
  sinkhorn_float8 maximum = {}, denominator = {};
#pragma unroll 1
  for (unsigned tile = 0; tile < 64; ++tile) {
    unsigned slot = tile & 1;
    if (tile + 1 < 64)
      for (unsigned i = thread; i < 1024; i += 256)
        stage[slot ^ 1][i] = reduction[(tile + 1) * 1024 + i];
    if (wave < 2) {
      sinkhorn_float8 score = {};
#pragma unroll
      for (unsigned feature_tile = 0; feature_tile < 2; ++feature_tile) {
        sinkhorn_half16 a, b;
#pragma unroll
        for (unsigned element = 0; element < 16; ++element) {
          unsigned feature = feature_tile * 32 + (element / 8) * 16 + (lane / 16) * 8 + element % 8;
          a[element] = fixed[(fixed_base + wave * 16 + lane % 16) * 64 + feature];
          b[element] = stage[slot][(lane % 16) * 64 + feature];
        }
        score = __builtin_amdgcn_wmma_f32_16x16x32_f16(false, a, false, b, 0, score, false, false);
      }
      unsigned key = tile * 16 + lane % 16;
      float bias = __builtin_fmaf(potential[key], 0x1.715476p+0f, log_weight[key] * 0x1.715476p+0f);
#pragma unroll
      for (unsigned element = 0; element < 8; ++element) {
        score[element] = __builtin_fmaf(score[element], 0x1.715476p+1f, bias);
        float local_max = sinkhorn_reduce_max(score[element]);
        float next_max = tile == 0 ? local_max : fmaxf(maximum[element], local_max);
        float alpha = tile == 0 ? 0 : __builtin_amdgcn_exp2f(maximum[element] - next_max);
        float p = __builtin_amdgcn_exp2f(score[element] - next_max);
        denominator[element] = __builtin_fmaf(denominator[element], alpha, sinkhorn_reduce_sum(p));
        maximum[element] = next_max;
      }
    }
    __syncthreads();
  }
  if (wave < 2 && (lane & 15) == 0) {
#pragma unroll
    for (unsigned element = 0; element < 8; ++element) {
      unsigned row = fixed_base + wave * 16 + (lane / 16) * 8 + element;
      float safe_sum = fmaxf(denominator[element], __builtin_bit_cast(float, 0x000116c2u));
      float lse = (maximum[element] + __builtin_amdgcn_logf(safe_sum)) * 0x1.62e43p-1f;
      output[row] = __builtin_fmaf(lse, -0.5f, fixed_potential[row] * 0.5f);
    }
  }
}

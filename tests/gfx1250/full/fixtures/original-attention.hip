// Original FlashAttention/ForgettingAttention/SageAttention computations.
// Genuine gfx1250 wave32 WMMA, full selected128 query rows and full sequence.
// Q/K/V/O widths, per-key scales, online max/sum and F16 P-before-PV retained.
#include <hip/hip_runtime.h>
typedef _Float16 attention_half16 __attribute__((ext_vector_type(16)));
typedef float attention_float8 __attribute__((ext_vector_type(8)));

__device__ __forceinline__ float attention_max16(float x) {
#pragma unroll
  for (unsigned d = 8; d; d >>= 1)
    x = fmaxf(x, __shfl_xor(x, d, 16));
  return x;
}
__device__ __forceinline__ float attention_sum16(float x) {
#pragma unroll
  for (unsigned d = 8; d; d >>= 1)
    x += __shfl_xor(x, d, 16);
  return x;
}
template <unsigned Mode>
__device__ __forceinline__ _Float16 attention_input(const void *p, unsigned i) {
  if constexpr (Mode == 2)
    return (_Float16)float(static_cast<const signed char *>(p)[i]);
  else
    return static_cast<const _Float16 *>(p)[i];
}
template <unsigned Mode, unsigned Threads>
__device__ __forceinline__ void attention_stage(const void *k, const _Float16 *v, _Float16 *sk,
                                                _Float16 *sv, unsigned base, unsigned tile,
                                                unsigned t) {
  for (unsigned i = t; i < 1024; i += Threads) {
    sk[i] = attention_input<Mode>(k, base + tile * 1024 + i);
    sv[i] = v[base + tile * 1024 + i];
  }
}
// Mode0:FlashAttention natural-score scale1/8; Mode1:Forgetting base2 score
// dot*LOG2_E/8-lambda_key*LOG2_E; Mode2:Sage signed-I8 with per64-key scales.
template <unsigned Mode, unsigned Threads>
__device__ __forceinline__ void
attention_original(const void *q, const void *k, const _Float16 *v, const float *lambda,
                   const float *qscale, const float *kscale, _Float16 *out, float *lse,
                   _Float16 *sk, _Float16 *sv, _Float16 *probability) {
  constexpr unsigned Waves = Threads / 32, QueryBlocks = 128 / (Waves * 16);
  unsigned t = threadIdx.x, lane = t & 31, wave = t / 32;
  unsigned sequence = Mode == 0 ? gridDim.x * 64 : (Mode == 1 ? 1024 : 128);
  unsigned head = Mode == 0 ? blockIdx.y : blockIdx.z * 16 + blockIdx.y;
  unsigned kvhead = Mode == 2 ? blockIdx.z * 2 + (blockIdx.y >> 3) : head;
  unsigned qbase = head * (Mode == 2 ? 1024 : sequence) * 64;
  unsigned kvbase = kvhead * sequence * 64;
  if constexpr (Mode == 0)
    if (blockIdx.x & 1)
      return;
#pragma unroll 1
  for (unsigned query_tile = 0; query_tile < QueryBlocks; ++query_tile) {
    unsigned first_row = blockIdx.x * (Mode == 0 ? 64 : 128) + query_tile * Waves * 16 + wave * 16;
    attention_stage<Mode, Threads>(k, v, sk, sv, kvbase, 0, t);
    __syncthreads();
    attention_float8 maximum = {}, denominator = {}, accumulator[4] = {};
#pragma unroll 1
    for (unsigned tile = 0; tile < sequence / 16; ++tile) {
      unsigned slot = tile & 1;
      if (tile + 1 < sequence / 16)
        attention_stage<Mode, Threads>(k, v, sk + (slot ^ 1) * 1024, sv + (slot ^ 1) * 1024, kvbase,
                                       tile + 1, t);
      attention_float8 score = {};
#pragma unroll
      for (unsigned feature_tile = 0; feature_tile < 2; ++feature_tile) {
        attention_half16 a, b;
#pragma unroll
        for (unsigned element = 0; element < 16; ++element) {
          unsigned feature = feature_tile * 32 + (element / 8) * 16 + (lane / 16) * 8 + element % 8;
          a[element] = attention_input<Mode>(q, qbase + (first_row + lane % 16) * 64 + feature);
          b[element] = sk[slot * 1024 + (lane % 16) * 64 + feature];
        }
        score = __builtin_amdgcn_wmma_f32_16x16x32_f16(false, a, false, b, 0, score, false, false);
      }
      attention_float8 alpha;
#pragma unroll
      for (unsigned element = 0; element < 8; ++element) {
        if constexpr (Mode == 0)
          score[element] *= 0.125f;
        if constexpr (Mode == 1) {
          float bias = lambda[head * sequence + tile * 16 + lane % 16] * -0x1.715476p+0f;
          score[element] = __builtin_fmaf(score[element], 0x1.715476p-3f, bias);
        }
        if constexpr (Mode == 2)
          score[element] *= qscale[head * 8 + blockIdx.x] * kscale[kvhead * 2 + tile / 4];
        float tile_max = attention_max16(score[element]);
        float next_max = tile == 0 ? tile_max : fmaxf(maximum[element], tile_max);
        float delta = maximum[element] - next_max, value = score[element] - next_max;
        if constexpr (Mode == 0) {
          delta *= 0x1.715476p+0f;
          value *= 0x1.715476p+0f;
        }
        alpha[element] = tile == 0 ? 0 : __builtin_amdgcn_exp2f(delta);
        float p = __builtin_amdgcn_exp2f(value);
        unsigned row = (lane / 16) * 8 + element;
        probability[wave * 256 + row * 16 + lane % 16] = (_Float16)p;
        denominator[element] = denominator[element] * alpha[element] + attention_sum16(p);
        maximum[element] = next_max;
      }
      __syncthreads();
      attention_half16 p;
#pragma unroll
      for (unsigned element = 0; element < 16; ++element) {
        unsigned key = (element / 8) * 16 + (lane / 16) * 8 + element % 8;
        p[element] = key < 16 ? probability[wave * 256 + (lane % 16) * 16 + key] : (_Float16)0;
      }
#pragma unroll
      for (unsigned feature_tile = 0; feature_tile < 4; ++feature_tile) {
        attention_half16 b;
#pragma unroll
        for (unsigned element = 0; element < 16; ++element) {
          unsigned key = (element / 8) * 16 + (lane / 16) * 8 + element % 8;
          b[element] =
              key < 16 ? sv[slot * 1024 + key * 64 + feature_tile * 16 + lane % 16] : (_Float16)0;
        }
#pragma unroll
        for (unsigned element = 0; element < 8; ++element)
          accumulator[feature_tile][element] *= alpha[element];
        accumulator[feature_tile] = __builtin_amdgcn_wmma_f32_16x16x32_f16(
            false, p, false, b, 0, accumulator[feature_tile], false, false);
      }
      __syncthreads();
    }
#pragma unroll
    for (unsigned element = 0; element < 8; ++element) {
      unsigned row = first_row + (lane / 16) * 8 + element;
      float inverse = __builtin_amdgcn_rcpf(denominator[element]);
#pragma unroll
      for (unsigned feature_tile = 0; feature_tile < 4; ++feature_tile)
        out[qbase + row * 64 + feature_tile * 16 + lane % 16] =
            (_Float16)(accumulator[feature_tile][element] * inverse);
      if constexpr (Mode != 2) {
        if ((lane & 15) == 0) {
          float logarithm = __builtin_amdgcn_logf(denominator[element]);
          if constexpr (Mode == 0)
            lse[head * sequence + row] = maximum[element] + logarithm * 0x1.62e43p-1f;
          else
            lse[head * sequence + row] = __builtin_fmaf(maximum[element] + logarithm, 0x1.62e43p-1f,
                                                        lambda[head * sequence + row]);
        }
      }
    }
    __syncthreads();
  }
}
extern "C" __global__
__launch_bounds__(128) void flash_attention_original(const _Float16 *q, const _Float16 *k,
                                                     const _Float16 *v, const void *bias,
                                                     _Float16 *out, float *lse, const void *tmp) {
  __shared__ _Float16 sk[2048], sv[2048], p[1024];
  attention_original<0, 128>(q, k, v, nullptr, nullptr, nullptr, out, lse, sk, sv, p);
}
extern "C" __global__
__launch_bounds__(256) void forgetting_attention_original(const _Float16 *q, const _Float16 *k,
                                                          const _Float16 *v, const float *lambda,
                                                          float *lse, _Float16 *out) {
  __shared__ _Float16 sk[2048], sv[2048], p[2048];
  attention_original<1, 256>(q, k, v, lambda, nullptr, nullptr, out, lse, sk, sv, p);
}
extern "C" __global__ __launch_bounds__(256) void sage_attention_original(
    const signed char *q, const signed char *k, const _Float16 *v, const float *qscale,
    const float *kscale, _Float16 *out, const void *mask, const void *unused_lse) {
  __shared__ _Float16 sk[2048], sv[2048], p[2048];
  attention_original<2, 256>(q, k, v, nullptr, qscale, kscale, out, nullptr, sk, sv, p);
}

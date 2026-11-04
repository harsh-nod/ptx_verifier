// SageAttention actual full128x128,D64 signed-I8 Q/K, F16 V/output.
// Each signed byte is exactly converted to F16 before F32-accumulating MFMA.
// D64 integer dot magnitude<=2^20, so this conversion preserves its exact value.
// Actual per64-key Q/K scales and base2 softmax are retained; no LSE is written.
// Native online/PV partitions differ; IEEE rounding remains abstracted by the verifier.
#include <hip/hip_runtime.h>
typedef _Float16 half4v __attribute__((ext_vector_type(4)));
typedef _Float16 half8v __attribute__((ext_vector_type(8)));
typedef float float4v __attribute__((ext_vector_type(4)));

__device__ __forceinline__ float sage_exp2(float value) {
  return __builtin_amdgcn_exp2f(value);
}
__device__ __forceinline__ float row_max16(float value) {
#pragma unroll
  for (unsigned delta = 8; delta; delta >>= 1)
    value = fmaxf(value, __shfl_xor(value, delta, 16));
  return value;
}
__device__ __forceinline__ float row_sum16(float value) {
#pragma unroll
  for (unsigned delta = 8; delta; delta >>= 1)
    value += __shfl_xor(value, delta, 16);
  return value;
}

template <unsigned Sequence, unsigned QueryBlocks>
__device__ __forceinline__ void sage_attention(
    const signed char *q, const signed char *k, const _Float16 *v,
    const float *q_scale, const float *k_scale, _Float16 *out, _Float16 *shared_k, _Float16 *shared_v,
    _Float16 *shared_probability) {
  unsigned t = threadIdx.x, lane = t & 63, wave = t / 64;
  unsigned head = blockIdx.z * 16 + blockIdx.y;
  unsigned kv_head = blockIdx.z * 2 + (blockIdx.y >> 3);
  unsigned q_base = head * 1024 * 64;
  unsigned kv_base = kv_head * 128 * 64;
#pragma unroll 1
  for (unsigned query_block = 0; query_block < QueryBlocks; ++query_block) {
    unsigned query_base = blockIdx.x * 128 + query_block * 32 + wave * 16;
#pragma unroll
    for (unsigned component = 0; component < 8; ++component) {
      unsigned linear = t + component * 128;
      shared_k[linear] = (_Float16)(float)k[kv_base + linear];
      shared_v[linear] = v[kv_base + linear];
    }
    __syncthreads();
    float4v maximum = {0, 0, 0, 0}, denominator = {0, 0, 0, 0};
    float4v accumulator[4] = {{0,0,0,0},{0,0,0,0},{0,0,0,0},{0,0,0,0}};
#pragma unroll 1
    for (unsigned key_tile = 0; key_tile < Sequence / 16; ++key_tile) {
      half8v next_k, next_v;
      if (key_tile + 1 < Sequence / 16) {
#pragma unroll
        for (unsigned component = 0; component < 8; ++component) {
          unsigned linear = t + component * 128;
          unsigned index = kv_base + (key_tile + 1) * 1024 + linear;
          next_k[component] = (_Float16)(float)k[index];
          next_v[component] = v[index];
        }
      }
      unsigned buffer = (key_tile & 1) * 1024;
      float4v score = {0, 0, 0, 0};
#pragma unroll
      for (unsigned feature_tile = 0; feature_tile < 4; ++feature_tile) {
        half4v qa, kb;
#pragma unroll
        for (unsigned component = 0; component < 4; ++component) {
          unsigned feature = feature_tile * 16 + (lane / 16) * 4 + component;
          qa[component] = (_Float16)(float)q[q_base + (query_base + (lane & 15)) * 64 + feature];
          kb[component] = shared_k[buffer + (lane & 15) * 64 + feature];
        }
        score = __builtin_amdgcn_mfma_f32_16x16x16f16(qa, kb, score, 0, 0, 0);
      }
      float4v alpha;
#pragma unroll
      for (unsigned component = 0; component < 4; ++component) {
        // Actual source uses base2 scores with no additional head-dimension scale.
        score[component] *= q_scale[head * 8 + blockIdx.x]
                          * k_scale[kv_head * 2 + key_tile / 4];
        float tile_maximum = row_max16(score[component]);
        float new_maximum = key_tile == 0 ? tile_maximum
                                         : fmaxf(maximum[component], tile_maximum);
        alpha[component] = key_tile == 0 ? 0.0f
                             : sage_exp2(maximum[component] - new_maximum);
        float probability = sage_exp2(score[component] - new_maximum);
        unsigned row = (lane / 16) * 4 + component;
        shared_probability[wave * 256 + row * 16 + (lane & 15)] = (_Float16)probability;
        denominator[component] = denominator[component] * alpha[component]
                                + row_sum16(probability);
        maximum[component] = new_maximum;
      }
      __syncthreads();
      half4v probability;
#pragma unroll
      for (unsigned component = 0; component < 4; ++component)
        probability[component] = shared_probability[wave * 256 + (lane & 15) * 16
                                      + (lane / 16) * 4 + component];
#pragma unroll
      for (unsigned output_tile = 0; output_tile < 4; ++output_tile) {
        half4v vb;
#pragma unroll
        for (unsigned component = 0; component < 4; ++component) {
          unsigned key = (lane / 16) * 4 + component;
          vb[component] = shared_v[buffer + key * 64 + output_tile * 16 + (lane & 15)];
          accumulator[output_tile][component] *= alpha[component];
        }
        accumulator[output_tile] = __builtin_amdgcn_mfma_f32_16x16x16f16(
            probability, vb, accumulator[output_tile], 0, 0, 0);
      }
      // Both waves finish consuming this K/V tile before its buffer is reused.
      __syncthreads();
      if (key_tile + 1 < Sequence / 16) {
        unsigned next_buffer = ((key_tile + 1) & 1) * 1024;
#pragma unroll
        for (unsigned component = 0; component < 8; ++component) {
          unsigned linear = t + component * 128;
          shared_k[next_buffer + linear] = next_k[component];
          shared_v[next_buffer + linear] = next_v[component];
        }
      }
      __syncthreads();
    }
#pragma unroll
    for (unsigned component = 0; component < 4; ++component) {
      unsigned row = query_base + (lane / 16) * 4 + component;
      float inverse = __builtin_amdgcn_rcpf(denominator[component]);
#pragma unroll
      for (unsigned output_tile = 0; output_tile < 4; ++output_tile)
        out[q_base + row * 64 + output_tile * 16 + (lane & 15)] =
            (_Float16)(accumulator[output_tile][component] * inverse);

    }
    __syncthreads();
  }
}

extern "C" __global__ __launch_bounds__(128)
void sage_attention_full(const signed char *q, const signed char *k,
                         const _Float16 *v, const float *q_scale,
                         const float *k_scale, _Float16 *out) {
  __shared__ _Float16 shared_k[2048], shared_v[2048], probability[512];
  sage_attention<128, 4>(q, k, v, q_scale, k_scale, out,
                         shared_k, shared_v, probability);
}

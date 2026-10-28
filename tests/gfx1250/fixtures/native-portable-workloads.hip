// Bounded mathematical workload counterparts, compiled natively for gfx1250.
// These are not original-shape, original-dtype or instruction-for-instruction
// ports of the PTX artifacts. See portable-cases.json for exact scopes/premises.
// Float input elements are already decoded finite real values in this model.
#include <hip/hip_runtime.h>

__device__ __forceinline__ float ex(float x) {
  return __builtin_amdgcn_exp2f(x * 0x1.715476p+0f);
}
__device__ __forceinline__ float inv(float x) { return __builtin_amdgcn_rcpf(x); }
__device__ __forceinline__ float ln(float x) {
  return __builtin_amdgcn_logf(x) * 0x1.62e43p-1f;
}

extern "C" __global__ void portable_relu(const float *x, float *out) {
  unsigned i = threadIdx.x;
  if (i < 64) out[i] = fmaxf(x[i], 0.0f);
}
extern "C" __global__ void portable_sigmoid(const float *x, float *out) {
  unsigned i = threadIdx.x;
  if (i < 64) out[i] = inv(1.0f + ex(-x[i]));
}
extern "C" __global__ void portable_silu(const float *x, float *out) {
  unsigned i = threadIdx.x;
  if (i < 64) out[i] = x[i] * inv(1.0f + ex(-x[i]));
}
extern "C" __global__ void portable_swiglu(const float *gate, const float *value, float *out) {
  unsigned i = threadIdx.x;
  if (i < 64) out[i] = gate[i] * inv(1.0f + ex(-gate[i])) * value[i];
}
extern "C" __global__ void portable_rope(const float *x, const float *cosine,
                                        const float *sine, float *out) {
  unsigned i = threadIdx.x;
  if (i < 32) {
    unsigned half = i / 16, component = i % 16;
    float partner = x[(1 - half) * 16 + component];
    out[i] = x[i] * cosine[i] + (half ? partner : -partner) * sine[i];
  }
}
extern "C" __global__ void portable_reduction(const float *x, float *out) {
  unsigned row = threadIdx.x;
  if (row < 2) {
    float sum = 0;
#pragma unroll 1
    for (unsigned k = 0; k < 32; ++k) sum += x[row * 32 + k];
    out[row] = sum;
  }
}
extern "C" __global__ void portable_softmax(const float *x, float *out) {
  unsigned i = threadIdx.x, row = i / 32;
  if (i < 64) {
    float maximum = x[row * 32], total = 0;
#pragma unroll 1
    for (unsigned k = 1; k < 32; ++k) maximum = fmaxf(maximum, x[row * 32 + k]);
#pragma unroll 1
    for (unsigned k = 0; k < 32; ++k) total += ex(x[row * 32 + k] - maximum);
    out[i] = ex(x[i] - maximum) * inv(total);
  }
}
extern "C" __global__ void portable_rmsnorm(const float *x, const float *weight, float *out) {
  unsigned i = threadIdx.x, row = i / 32;
  if (i < 64) {
    float square_sum = 0;
#pragma unroll 1
    for (unsigned k = 0; k < 32; ++k) square_sum += x[row * 32 + k] * x[row * 32 + k];
    out[i] = x[i] * weight[i] * __builtin_amdgcn_rsqf(square_sum * (1.0f / 32) + 1.0e-6f);
  }
}
extern "C" __global__ void portable_matvec(const float *a, const float *x, float *out) {
  unsigned row = threadIdx.x;
  if (row < 4) {
    float value = 0;
#pragma unroll 1
    for (unsigned k = 0; k < 32; ++k) value += a[row * 32 + k] * x[k];
    out[row] = value;
  }
}
extern "C" __global__ void portable_gemm(const float *a, const float *b, float *out) {
  unsigned i = threadIdx.x, row = i / 8, column = i % 8;
  if (i < 32) {
    float value = 0;
#pragma unroll 1
    for (unsigned k = 0; k < 16; ++k) value += a[row * 16 + k] * b[k * 8 + column];
    out[i] = value;
  }
}
extern "C" __global__ void portable_gemm_add_silu(const float *a, const float *b,
                                                  const float *addend, float *out) {
  unsigned i = threadIdx.x, row = i / 8, column = i % 8;
  if (i < 32) {
    float value = 0;
#pragma unroll 1
    for (unsigned k = 0; k < 16; ++k) value += a[row * 16 + k] * b[k * 8 + column];
    value += addend[i];
    out[i] = value * inv(1.0f + ex(-value));
  }
}
// Packed words are concrete IndexInput elements i=i. A remains symbolic.
// Output is column-major so independent named slices can express every column
// without adding bitwise input operators to the mathematical spec language.
extern "C" __global__ void portable_bitdelta(const float *a, const unsigned *packed, float *out) {
  unsigned t = threadIdx.x, row = t % 2, column = t / 2;
  if (t < 8) {
    unsigned word = packed[column];
    float value = 0;
#pragma unroll 1
    for (unsigned k = 0; k < 32; ++k)
      value += a[row * 32 + k] * ((word >> k) & 1 ? 1.0f : -1.0f);
    out[t] = value;
  }
}
extern "C" __global__ void portable_bitdelta_batched(const float *a, const unsigned *packed, float *out) {
  unsigned t = threadIdx.x, batch = t / 8, row = t % 2, column = (t / 2) % 4;
  if (t < 16) {
    unsigned word = packed[batch * 4 + column];
    float value = 0;
#pragma unroll 1
    for (unsigned k = 0; k < 32; ++k)
      value += a[(batch * 2 + row) * 32 + k] * ((word >> k) & 1 ? 1.0f : -1.0f);
    out[t] = value;
  }
}
extern "C" __global__ void portable_convolution(const float *x, const float *weight, float *out) {
  unsigned i = threadIdx.x, channel = i / 9, h = (i / 3) % 3, w = i % 3;
  if (i < 18) {
    float value = 0;
#pragma unroll 1
    for (unsigned c = 0; c < 2; ++c)
#pragma unroll 1
      for (unsigned r = 0; r < 3; ++r)
#pragma unroll 1
        for (unsigned s = 0; s < 3; ++s)
          value += x[c * 25 + (h + r) * 5 + w + s] * weight[((channel * 2 + c) * 3 + r) * 3 + s];
    out[i] = value;
  }
}
extern "C" __global__ void portable_mamba_state(const float *x, const float *b, const float *dt,
                                                const float *da, float *states) {
  unsigned i = threadIdx.x, row = i / 4, column = i % 4;
  if (i < 16) {
    float value = 0;
#pragma unroll 1
    for (unsigned t = 0; t < 8; ++t)
      value += x[t * 4 + row] * b[t * 4 + column] * dt[t] * ex(fminf(da[7] - da[t], 0.0f));
    states[i] = value;
  }
}
extern "C" __global__ void portable_mamba_scan(const float *cb, const float *x, const float *c,
                                               const float *prev, const float *dt, const float *da,
                                               float *out, float *out_x) {
  unsigned i = threadIdx.x, row = i / 4, column = i % 4;
  if (i < 8) {
    float initial = 0, value = 0;
#pragma unroll 1
    for (unsigned j = 0; j < 4; ++j) initial += c[row * 4 + j] * prev[column * 4 + j];
#pragma unroll 1
    for (unsigned t = 0; t < 8; ++t)
      value += cb[row * 8 + t] * ex(fminf(da[row] - da[t], 0.0f)) * dt[t] * x[t * 4 + column];
    out[i] = ex(da[row]) * initial + value;
    out_x[i] = 0;
  }
}
template<int Mode>
__device__ __forceinline__ float score(const float *q, const float *k, const float *extra,
                                       const float *q_scale, const float *k_scale, unsigned row, unsigned key) {
  float dot = 0;
#pragma unroll 1
  for (unsigned a = 0; a < 4; ++a) dot += q[row * 4 + a] * k[key * 4 + a];
  if constexpr (Mode == 1) return dot * 0.125f - extra[key];
  if constexpr (Mode == 2) return dot * q_scale[0] * k_scale[key / 4];
  return dot * 0.125f;
}
template<int Mode>
__device__ __forceinline__ void attention(const float *q, const float *k, const float *v,
    const float *extra, const float *q_scale, const float *k_scale, float *out, float *lse) {
  unsigned i = threadIdx.x, row = i / 4, column = i % 4;
  if (i < 8) {
    float maximum = score<Mode>(q,k,extra,q_scale,k_scale,row,0), total = 0, value = 0;
#pragma unroll 1
    for (unsigned j = 1; j < 8; ++j) maximum = fmaxf(maximum,score<Mode>(q,k,extra,q_scale,k_scale,row,j));
#pragma unroll 1
    for (unsigned j = 0; j < 8; ++j) {
      float p = ex(score<Mode>(q,k,extra,q_scale,k_scale,row,j) - maximum);
      total += p; value += p * v[j * 4 + column];
    }
    out[i] = value * inv(total);
    if constexpr (Mode != 2) {
      if (column == 0) lse[row] = maximum + ln(total) + (Mode == 1 ? extra[row] : 0.0f);
    }
  }
}
extern "C" __global__ void portable_flash_attention(const float *q, const float *k,
    const float *v, float *out, float *lse) { attention<0>(q,k,v,nullptr,nullptr,nullptr,out,lse); }
extern "C" __global__ void portable_forgetting_attention(const float *q, const float *k,
    const float *v, const float *log_lambda, float *out, float *lse) {
  attention<1>(q,k,v,log_lambda,nullptr,nullptr,out,lse);
}
extern "C" __global__ void portable_sage_attention(const float *q, const float *k,
    const float *v, const float *q_scale, const float *k_scale, float *out) {
  attention<2>(q,k,v,nullptr,q_scale,k_scale,out,nullptr);
}
extern "C" __global__ void portable_sinkhorn(const float *x, const float *y, const float *f_hat,
    const float *g_hat, const float *log_b, float *f_out) {
  unsigned row = threadIdx.x;
  if (row < 2) {
    float scores[8], maximum, total = 0;
#pragma unroll
    for (unsigned key = 0; key < 8; ++key) {
      float dot = 0;
#pragma unroll 1
      for (unsigned d = 0; d < 4; ++d) dot += x[row * 4 + d] * y[key * 4 + d];
      scores[key] = 2 * dot + g_hat[key] + log_b[key];
    }
    maximum = scores[0];
#pragma unroll
    for (unsigned key = 1; key < 8; ++key) maximum = fmaxf(maximum,scores[key]);
#pragma unroll
    for (unsigned key = 0; key < 8; ++key) total += ex(scores[key] - maximum);
    f_out[row] = 0.5f * f_hat[row] - 0.5f * (maximum + ln(total));
  }
}

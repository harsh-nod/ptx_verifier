// Reconstructed portable computations from ai_compiler_kernels/* Float16 PTX.
// See PORTABLE-CORPUS.txt for each original shape, mapping, and remaining gaps.
#include <hip/hip_runtime.h>

typedef _Float16 half8v __attribute__((ext_vector_type(8)));
typedef _Float16 half4v __attribute__((ext_vector_type(4)));

__device__ __forceinline__ float fast_exp(float x) {
  // PTX's 0f3fb8aa3b is the rounded float log2(e), not an exact real constant.
  return __builtin_amdgcn_exp2f(x * 0x1.715476p+0f);
}
__device__ __forceinline__ float recip(float x) {
  return __builtin_amdgcn_rcpf(x);
}
template <int Width>
__device__ __forceinline__ float xor_sum(float x) {
#pragma unroll
  for (int d = Width / 2; d; d >>= 1)
    x += __shfl_xor(x, d, Width);
  return x;
}
template <int Width>
__device__ __forceinline__ float xor_max(float x) {
#pragma unroll
  for (int d = Width / 2; d; d >>= 1)
    x = fmaxf(x, __shfl_xor(x, d, Width));
  return x;
}

// Original block: 128 threads, eight adjacent halves per thread, 1024 outputs.
extern "C" __global__ void relu_f16(const half8v *x, half8v *out) {
  unsigned i = blockIdx.x * 128 + threadIdx.x;
  half8v a = x[i];
#pragma unroll
  for (int k = 0; k < 8; ++k)
    a[k] = a[k] > (_Float16)0 ? a[k] : (_Float16)0;
  out[i] = a;
}

// Original block: 128 threads, four adjacent halves per thread, 512 outputs.
extern "C" __global__ void silu_f16(const half4v *x, half4v *out) {
  unsigned i = blockIdx.x * 128 + threadIdx.x;
  half4v a = x[i];
#pragma unroll
  for (int k = 0; k < 4; ++k) {
    float v = (float)a[k];
    a[k] = (_Float16)(v * recip(1.0f + fast_exp(-v)));
  }
  out[i] = a;
}

// Original block: 256 threads, four adjacent halves per thread, 1024 outputs.
extern "C" __global__ void sigmoid_f16(const half4v *x, half4v *out) {
  unsigned i = blockIdx.x * 256 + threadIdx.x;
  half4v a = x[i];
#pragma unroll
  for (int k = 0; k < 4; ++k)
    a[k] = (_Float16)recip(1.0f + fast_exp(-(float)a[k]));
  out[i] = a;
}

// Original block: 128 threads, eight gates/values each, 1024 outputs.
extern "C" __global__ void swiglu_f16(const half8v *gate, const half8v *value,
                                     half8v *out) {
  unsigned i = blockIdx.x * 128 + threadIdx.x;
  half8v g = gate[i], v = value[i], result;
#pragma unroll
  for (int k = 0; k < 8; ++k) {
    float f = (float)g[k];
    result[k] = (_Float16)(f * recip(1.0f + fast_exp(-f)) * (float)v[k]);
  }
  out[i] = result;
}

// Original BFI maps adjacent lanes to opposite 64-element halves. Preserve the
// exact permutation and coefficient repetition instead of using adjacent pairs.
extern "C" __global__ void rope_f16(const _Float16 *x, const _Float16 *cosine,
                                   const _Float16 *sine, _Float16 *out) {
  unsigned t = threadIdx.x;
  unsigned local = (t >> 1) | ((t & 1) << 6);
  unsigned i = blockIdx.x * 128 + local;
  float a = (float)x[i];
  float partner = __shfl_xor(a, 1, 64);
  if ((t & 1) == 0)
    partner = -partner;
  out[i] = (_Float16)(a * (float)cosine[i & 32767] +
                       partner * (float)sine[i & 32767]);
}

// The baseline reduces 256 halves using only its first 32 lanes and atomically
// ADDS to an existing FP32 output. Retain that inout/atomic behavior explicitly.
extern "C" __global__ void reduction_f16(const half8v *x, float *out) {
  unsigned t = threadIdx.x;
  if (t >= 32)
    return;
  half8v a = x[blockIdx.y * 512 + blockIdx.x * 32 + t];
  float sum = 0;
#pragma unroll
  for (int k = 0; k < 8; ++k)
    sum += (float)a[k];
  sum = xor_sum<32>(sum);
  if (t == 0)
    atomicAdd(out + blockIdx.y, sum);
}

// Preserve four independent 32-lane rows/block and runtime row strides. Every
// row has the baseline's unmasked 256-column tile. n_cols is retained ABI data;
// this native reconstruction has the same fixed-256-column precondition.
extern "C" __global__ void softmax_f16(_Float16 *out, const _Float16 *x,
                                      unsigned input_row_stride,
                                      unsigned output_row_stride,
                                      unsigned n_rows, unsigned n_cols) {
  unsigned warp = threadIdx.x / 32, lane = threadIdx.x & 31;
  for (unsigned row = blockIdx.x * 4 + warp; row < n_rows;
       row += gridDim.x * 4) {
    half8v a = *reinterpret_cast<const half8v *>(x + row * input_row_stride + lane * 8);
    float m = (float)a[0];
#pragma unroll
    for (int k = 1; k < 8; ++k)
      m = fmaxf(m, (float)a[k]);
    m = xor_max<32>(m);
    float e[8], total = 0;
#pragma unroll
    for (int k = 0; k < 8; ++k) {
      // The original subtracts in half, then converts back to FP32.
      _Float16 difference = (_Float16)(a[k] - (_Float16)m);
      e[k] = fast_exp((float)difference);
      total += e[k];
    }
    total = xor_sum<32>(total);
    half8v result;
#pragma unroll
    for (int k = 0; k < 8; ++k)
      result[k] = (_Float16)(e[k] * recip(total));
    *reinterpret_cast<half8v *>(out + row * output_row_stride + lane * 8) = result;
  }
}

// Preserve 512 threads x eight values = 4096 elements per row. AMD wave64
// yields eight LDS partials; the original used sixteen NVIDIA warp32 partials.
extern "C" __global__ void rmsnorm_f16(const half8v *x, const half8v *weight,
                                      half8v *out) {
  __shared__ float partial[8];
  unsigned t = threadIdx.x, lane = t & 63;
  unsigned i = blockIdx.x * 512 + t;
  half8v a = x[i], w = weight[i];
  float sum = 0;
#pragma unroll
  for (int k = 0; k < 8; ++k) {
    float v = (float)a[k];
    sum += v * v;
  }
  sum = xor_sum<64>(sum);
  if (lane == 0)
    partial[t / 64] = sum;
  __syncthreads();
  sum = xor_sum<8>(partial[lane & 7]);
  float scale = __builtin_amdgcn_rsqf(sum * (1.0f / 4096.0f) + 1.0e-6f);
  half8v result;
#pragma unroll
  for (int k = 0; k < 8; ++k)
    result[k] = (_Float16)((float)a[k] * scale * (float)w[k]);
  out[i] = result;
}

// Reduced arithmetic/reference matvec: original has 32 output rows/workgroup
// and K=4096. This version keeps those dimensions but uses one wave per row
// with an explicit LDS vector tile; MFMA pipelining is a separate corpus gate.
extern "C" __global__ void matvec_f16(const _Float16 *a, const _Float16 *x,
                                     _Float16 *out) {
  __shared__ _Float16 tile[4096];
  unsigned t = threadIdx.x;
  for (unsigned k = t; k < 4096; k += 128)
    tile[k] = x[k];
  __syncthreads();
  for (unsigned row = t / 64; row < 32; row += 2) {
    float value = 0;
    for (unsigned k = t & 63; k < 4096; k += 64)
      value += (float)a[(blockIdx.x * 32 + row) * 4096 + k] * (float)tile[k];
    value = xor_sum<64>(value);
    if ((t & 63) == 0)
      out[blockIdx.x * 32 + row] = (_Float16)value;
  }
}

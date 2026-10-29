// OCP E4M3 inputs and FP16 outputs, matching the actual Float8 PTX artifacts.
// FNUZ is a different format and is intentionally not used here.
#include <hip/hip_runtime.h>
typedef unsigned int uint2v __attribute__((ext_vector_type(2)));
typedef float float4v __attribute__((ext_vector_type(4)));
typedef _Float16 half4v __attribute__((ext_vector_type(4)));
typedef _Float16 half8v __attribute__((ext_vector_type(8)));

__device__ __forceinline__ float4v decode4(unsigned value) {
  return {__builtin_amdgcn_cvt_f32_fp8(value, 0),
          __builtin_amdgcn_cvt_f32_fp8(value, 1),
          __builtin_amdgcn_cvt_f32_fp8(value, 2),
          __builtin_amdgcn_cvt_f32_fp8(value, 3)};
}
__device__ __forceinline__ float decode1(unsigned char value) {
  return __builtin_amdgcn_cvt_f32_fp8((unsigned)value, 0);
}
__device__ __forceinline__ float fp8_exp(float value) {
  return __builtin_amdgcn_exp2f(value * 0x1.715476p+0f);
}
__device__ __forceinline__ float fp8_recip(float value) {
  return __builtin_amdgcn_rcpf(value);
}
template <int Width>
__device__ __forceinline__ float fp8_xor_sum(float value) {
#pragma unroll
  for (int delta = Width / 2; delta; delta >>= 1)
    value += __shfl_xor(value, delta, Width);
  return value;
}

// Original Float8 ReLU: 128 threads cover two1024-element slices, output half.
extern "C" __global__ void relu_f8(const uint2v *x, half8v *out) {
  unsigned index = blockIdx.x * 256 + threadIdx.x;
#pragma unroll
  for (unsigned tile = 0; tile < 2; ++tile) {
    uint2v packed = x[index + tile * 128];
    float4v lo = decode4(packed[0]), hi = decode4(packed[1]);
    half8v result;
#pragma unroll
    for (unsigned component = 0; component < 4; ++component) {
      result[component] = (_Float16)fmaxf(lo[component], 0.0f);
      result[component + 4] = (_Float16)fmaxf(hi[component], 0.0f);
    }
    out[index + tile * 128] = result;
  }
}

extern "C" __global__ void silu_f8(const unsigned *x, half4v *out) {
  unsigned index = blockIdx.x * 256 + threadIdx.x;
  float4v values = decode4(x[index]);
  half4v result;
#pragma unroll
  for (unsigned component = 0; component < 4; ++component) {
    float value = values[component];
    result[component] = (_Float16)(value * fp8_recip(1 + fp8_exp(-value)));
  }
  out[index] = result;
}

extern "C" __global__ void sigmoid_f8(const uint2v *x, half8v *out) {
  unsigned index = blockIdx.x * 128 + threadIdx.x;
  uint2v packed = x[index];
  float4v lo = decode4(packed[0]), hi = decode4(packed[1]);
  half8v result;
#pragma unroll
  for (unsigned component = 0; component < 4; ++component) {
    result[component] = (_Float16)fp8_recip(1 + fp8_exp(-lo[component]));
    result[component + 4] = (_Float16)fp8_recip(1 + fp8_exp(-hi[component]));
  }
  out[index] = result;
}

extern "C" __global__ void swiglu_f8(const unsigned *gate, const unsigned *value,
                                    half4v *out) {
  unsigned index = blockIdx.x * 512 + threadIdx.x;
  float4v g = decode4(gate[index]), v = decode4(value[index]);
  half4v result;
#pragma unroll
  for (unsigned component = 0; component < 4; ++component) {
    float f = g[component];
    result[component] = (_Float16)(f * fp8_recip(1 + fp8_exp(-f)) * v[component]);
  }
  out[index] = result;
}

extern "C" __global__ void rope_f8(const unsigned char *x,
                                  const unsigned char *cosine,
                                  const unsigned char *sine, _Float16 *out) {
  unsigned t = threadIdx.x, i = blockIdx.x * 128 + t;
  float a = decode1(x[i]), partner = decode1(x[i ^ 64]);
  float c = decode1(cosine[i & 32767]), s = decode1(sine[i & 32767]);
  if (t < 64)
    partner = -partner;
  // Preserve the baseline's quarter-scaled half products and final rescaling.
  _Float16 first = (_Float16)((_Float16)(a * 0.25f) * (_Float16)c);
  _Float16 second = (_Float16)((_Float16)(partner * 0.25f) * (_Float16)s);
  out[i] = (_Float16)((_Float16)(first + second) * (_Float16)4);
}

extern "C" __global__ void rmsnorm_f8(const uint2v *x, const uint2v *weight,
                                     half8v *out) {
  __shared__ float partial[16];
  unsigned t = threadIdx.x, lane = t & 31, i = blockIdx.x * 512 + t;
  uint2v a = x[i], w = weight[i];
  float4v alo = decode4(a[0]), ahi = decode4(a[1]);
  float4v wlo = decode4(w[0]), whi = decode4(w[1]);
  float sum = 0;
#pragma unroll
  for (unsigned component = 0; component < 4; ++component)
    sum += alo[component] * alo[component] + ahi[component] * ahi[component];
  sum = fp8_xor_sum<32>(sum);
  if (lane == 0)
    partial[t / 32] = sum;
  __syncthreads();
  sum = fp8_xor_sum<16>(partial[lane & 15]);
  float scale = __builtin_amdgcn_rsqf(sum * (1.0f / 4096.0f) + 1.0e-6f);
  half8v result;
#pragma unroll
  for (unsigned component = 0; component < 4; ++component) {
    result[component] = (_Float16)(alo[component] * scale * wlo[component]);
    result[component + 4] = (_Float16)(ahi[component] * scale * whi[component]);
  }
  out[i] = result;
}

// Original 64 output rows/workgroup and full K4096 with native wave32
// reductions. External OCP E4M3 input and F16 output storage are preserved.
// Native WMMA/TDM pipeline mechanisms have separate full workload gates.
extern "C" __global__ void matvec_f8(const unsigned char *a,
                                    const unsigned char *x, _Float16 *out) {
  __shared__ unsigned char tile[4096];
  unsigned t = threadIdx.x;
  for (unsigned k = t; k < 4096; k += 128)
    tile[k] = x[k];
  __syncthreads();
  for (unsigned row = t / 32; row < 64; row += 4) {
    float value = 0;
    for (unsigned k = t & 31; k < 4096; k += 32)
      value += decode1(a[(blockIdx.x * 64 + row) * 4096 + k]) * decode1(tile[k]);
    value = fp8_xor_sum<32>(value);
    if ((t & 31) == 0)
      out[blockIdx.x * 64 + row] = (_Float16)value;
  }
}

// Original FP8 reduction: one 32-lane logical warp processes four 512-byte
// slices, covering all 2048 source bytes; preserve the F32 inout atomic add.
typedef unsigned int uint4v __attribute__((ext_vector_type(4)));
extern "C" __global__ void reduction_f8(const unsigned char *x, float *out) {
  unsigned lane = threadIdx.x;
  if (lane >= 32)
    return;
  const unsigned char *tile = x + blockIdx.y * 4096 + blockIdx.x * 2048;
  float total = 0;
#pragma unroll
  for (unsigned slice = 0; slice < 4; ++slice) {
    uint4v packed = *reinterpret_cast<const uint4v *>(tile + slice * 512 + lane * 16);
#pragma unroll
    for (unsigned word = 0; word < 4; ++word) {
      float4v decoded = decode4(packed[word]);
#pragma unroll
      for (unsigned element = 0; element < 4; ++element)
        total += decoded[element];
    }
  }
  total = fp8_xor_sum<32>(total);
  if (lane == 0)
    atomicAdd(out + blockIdx.y, total);
}

// Original block32x4: each logical row owns 256 unmasked FP8 inputs and writes
// 256 F16 outputs. Grid-stride rows preserve the runtime row/column strides.
extern "C" __global__ void softmax_f8(_Float16 *out, const unsigned char *x,
                                     unsigned input_row_stride,
                                     unsigned output_row_stride,
                                     unsigned n_rows, unsigned n_cols) {
  unsigned lane = threadIdx.x;
  for (unsigned row = blockIdx.x * 4 + threadIdx.y; row < n_rows;
       row += gridDim.x * 4) {
    uint2v packed = *reinterpret_cast<const uint2v *>(x + row * input_row_stride + lane * 8);
    float4v lo = decode4(packed[0]), hi = decode4(packed[1]);
    float values[8] = {lo[0],lo[1],lo[2],lo[3],hi[0],hi[1],hi[2],hi[3]};
    float maximum = values[0];
#pragma unroll
    for (unsigned i = 1; i < 8; ++i)
      maximum = fmaxf(maximum, values[i]);
#pragma unroll
    for (unsigned delta = 16; delta; delta >>= 1)
      maximum = fmaxf(maximum, __shfl_xor(maximum, delta, 32));
    float exponentials[8], total = 0;
#pragma unroll
    for (unsigned i = 0; i < 8; ++i) {
      exponentials[i] = fp8_exp(values[i] - maximum);
      total += exponentials[i];
    }
    total = fp8_xor_sum<32>(total);
    half8v result;
#pragma unroll
    for (unsigned i = 0; i < 8; ++i)
      result[i] = (_Float16)(exponentials[i] * fp8_recip(total));
    *reinterpret_cast<half8v *>(out + row * output_row_stride + lane * 8) = result;
  }
}

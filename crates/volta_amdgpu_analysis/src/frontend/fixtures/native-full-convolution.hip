// Full original Convolution2DKernel CTA:128spatial positions x128output channels.
// NCHW56x56,Cin64,OIHW128x64x3x3,valid54x54,stride1; allK576 terms.
// Native block512 partitions the full tile across8wave64s without private spills.
#include <hip/hip_runtime.h>
typedef _Float16 half4v __attribute__((ext_vector_type(4)));
typedef float float4v __attribute__((ext_vector_type(4)));

template <bool FP8>
__device__ __forceinline__ _Float16 conv_load(const void *pointer, unsigned index) {
  if constexpr (FP8)
    return (_Float16)__builtin_amdgcn_cvt_f32_fp8(
        (unsigned)static_cast<const unsigned char *>(pointer)[index], 0);
  else
    return static_cast<const _Float16 *>(pointer)[index];
}

template <bool FP8>
__device__ __forceinline__ _Float16 image_element(const void *x, unsigned pixel,
                                                 unsigned k) {
  unsigned batch = pixel / 2916, position = pixel % 2916;
  unsigned channel = k / 9, filter = k % 9;
  unsigned row = position / 54 + filter / 3;
  unsigned column = position % 54 + filter % 3;
  return conv_load<FP8>(x, (batch * 64 + channel) * 3136 + row * 56 + column);
}


template<bool FP8>
__device__ __forceinline__ void conv_full_prefetch(
    const void *x, const void *weight, unsigned t, unsigned tile,
    half4v &a, half4v &b) {
#pragma unroll
  for (unsigned j = 0; j < 4; ++j) {
    unsigned linear = t + j * 512;
    unsigned k = tile * 16 + linear % 16;
    a[j] = image_element<FP8>(x, blockIdx.x * 128 + linear / 16, k);
    b[j] = conv_load<FP8>(weight, (blockIdx.y * 128 + linear / 16) * 576 + k);
  }
}
__device__ __forceinline__ void conv_full_publish(
    _Float16 *sa, _Float16 *sb, unsigned t, half4v a, half4v b) {
#pragma unroll
  for (unsigned j = 0; j < 4; ++j) {
    sa[t + j * 512] = a[j];
    sb[t + j * 512] = b[j];
  }
}
template<bool FP8>
__device__ __forceinline__ void convolution_full(
    const void *x, const void *weight, volatile _Float16 *out,
    _Float16 *sa, _Float16 *sb) {
  unsigned t = threadIdx.x, lane = t & 63, wave = t >> 6;
  half4v a0, b0;
  conv_full_prefetch<FP8>(x, weight, t, 0, a0, b0);
  conv_full_publish(sa, sb, t, a0, b0);
  __syncthreads();
  float4v acc[8] = {};
#pragma unroll 1
  for (unsigned tile = 0; tile < 36; ++tile) {
    unsigned slot = (tile & 1) * 2048;
    half4v next_a, next_b;
    if (tile + 1 < 36)
      conv_full_prefetch<FP8>(x, weight, t, tile + 1, next_a, next_b);
    half4v a;
#pragma unroll
    for (unsigned j = 0; j < 4; ++j)
      a[j] = sa[slot + (wave * 16 + (lane & 15)) * 16 + (lane >> 4) * 4 + j];
#pragma unroll
    for (unsigned column = 0; column < 8; ++column) {
      half4v b;
#pragma unroll
      for (unsigned j = 0; j < 4; ++j)
        b[j] = sb[slot + (column * 16 + (lane & 15)) * 16 + (lane >> 4) * 4 + j];
      acc[column] = __builtin_amdgcn_mfma_f32_16x16x16f16(a, b, acc[column], 0, 0, 0);
    }
    if (tile + 1 < 36)
      conv_full_publish(sa + (slot ^ 2048), sb + (slot ^ 2048), t, next_a, next_b);
    __syncthreads();
  }
#pragma unroll
  for (unsigned column = 0; column < 8; ++column) {
#pragma unroll
    for (unsigned j = 0; j < 4; ++j) {
      unsigned spatial = blockIdx.x * 128 + wave * 16 + (lane >> 4) * 4 + j;
      unsigned channel = blockIdx.y * 128 + column * 16 + (lane & 15);
      // Volatile keeps each actual half transfer separate at the54-column row
      // boundaries, so the affine reference slices do not change native stores.
      out[((spatial / 2916) * 128 + channel) * 2916 + spatial % 2916] = (_Float16)acc[column][j];
    }
  }
}
extern "C" __global__ __launch_bounds__(512)
void convolution_f16_full(const void *x, const void *weight, _Float16 *out) {
  __shared__ _Float16 sa[4096], sb[4096];
  convolution_full<false>(x, weight, out, sa, sb);
}
extern "C" __global__ __launch_bounds__(512)
void convolution_f8_full(const void *x, const void *weight, _Float16 *out) {
  __shared__ _Float16 sa[4096], sb[4096];
  convolution_full<true>(x, weight, out, sa, sb);
}

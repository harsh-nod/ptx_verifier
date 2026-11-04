// Reconstructed from both baseline Convolution2DKernel PTX artifacts.
// NCHW56x56,Cin64; OIHW128x64x3x3; valid54x54, stride1, no padding.
// Reduced CTA tile:32 spatial positions x16 output channels, full K=576.
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

template <bool FP8>
__device__ __forceinline__ void convolution(const void *x, const void *weight,
                                           _Float16 *out, _Float16 *tile_a,
                                           _Float16 *tile_b) {
  unsigned t = threadIdx.x, lane = t & 63, wave = t / 64;
  unsigned pixel = blockIdx.x * 32 + (1 - wave) * 16 + lane / 4;
#pragma unroll
  for (unsigned component = 0; component < 4; ++component) {
    unsigned linear = lane * 4 + component;
    tile_a[t * 4 + component] = image_element<FP8>(x, pixel, (lane & 3) * 4 + component);
    tile_b[t * 4 + component] = conv_load<FP8>(weight,
        (blockIdx.y * 16 + linear % 16) * 576 + linear / 16);
  }
  __syncthreads();
  float4v c = {0, 0, 0, 0};
  // Keep36 native MFMA iterations. This is the original64x3x3 reduction,
  // not a shortened channel/filter computation presented as full evidence.
#pragma unroll 1
  for (unsigned tile = 0; tile < 36; ++tile) {
    half4v next_a, next_b;
    if (tile + 1 < 36) {
#pragma unroll
      for (unsigned component = 0; component < 4; ++component) {
        unsigned linear = lane * 4 + component;
        next_a[component] = image_element<FP8>(x, pixel,
            (tile + 1) * 16 + (lane & 3) * 4 + component);
        next_b[component] = conv_load<FP8>(weight,
            (blockIdx.y * 16 + linear % 16) * 576 + (tile + 1) * 16 + linear / 16);
      }
    }
    unsigned buffer = (tile & 1) * 512;
    unsigned a_index = (1 - wave) * 256 + (lane & 15) * 16 + (lane / 16) * 4;
    unsigned b_index = (1 - wave) * 256 + (lane / 16) * 64 + (lane & 15);
    half4v av, bv;
#pragma unroll
    for (unsigned component = 0; component < 4; ++component) {
      av[component] = tile_a[buffer + a_index + component];
      bv[component] = tile_b[buffer + b_index + component * 16];
    }
    c = __builtin_amdgcn_mfma_f32_16x16x16f16(av, bv, c, 0, 0, 0);
    __syncthreads();
    if (tile + 1 < 36) {
      unsigned next_buffer = ((tile + 1) & 1) * 512;
#pragma unroll
      for (unsigned component = 0; component < 4; ++component) {
        tile_a[next_buffer + t * 4 + component] = next_a[component];
        tile_b[next_buffer + t * 4 + component] = next_b[component];
      }
    }
    __syncthreads();
  }
#pragma unroll
  for (unsigned component = 0; component < 4; ++component) {
    unsigned spatial = blockIdx.x * 32 + wave * 16 + (lane / 16) * 4 + component;
    unsigned channel = blockIdx.y * 16 + (lane & 15);
    out[((spatial / 2916) * 128 + channel) * 2916 + spatial % 2916] = (_Float16)c[component];
  }
}

extern "C" __global__ __launch_bounds__(128)
void convolution_f16(const void *x, const void *weight, _Float16 *out) {
  __shared__ _Float16 tile_a[1024], tile_b[1024];
  convolution<false>(x, weight, out, tile_a, tile_b);
}

extern "C" __global__ __launch_bounds__(128)
void convolution_f8(const void *x, const void *weight, _Float16 *out) {
  __shared__ _Float16 tile_a[1024], tile_b[1024];
  convolution<true>(x, weight, out, tile_a, tile_b);
}

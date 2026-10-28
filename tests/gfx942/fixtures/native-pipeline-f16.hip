// Portable two-wave source compiled independently for CDNA3 gfx942.
// Reduced native Float16 GEMM: M=32,N=16,K=32, two wave64s, two16-wide tiles.
// Cross-wave LDS producers, double buffers and repeated barriers are retained.
#include <hip/hip_runtime.h>
typedef _Float16 half4v __attribute__((ext_vector_type(4)));
typedef float float4v __attribute__((ext_vector_type(4)));

extern "C" __global__ __launch_bounds__(128)
void pipelined_mfma_f16(const _Float16 *a, const _Float16 *b, _Float16 *out) {
  __shared__ _Float16 tile_a[2][512], tile_b[2][512];
  unsigned t = threadIdx.x, lane = t & 63, wave = t / 64;
  unsigned producer_row = (1 - wave) * 16 + lane / 4;
#pragma unroll
  for (unsigned component = 0; component < 4; ++component) {
    unsigned linear = lane * 4 + component;
    tile_a[0][t * 4 + component] = a[producer_row * 32 + (lane & 3) * 4 + component];
    tile_b[0][t * 4 + component] = b[(linear / 16) * 16 + linear % 16];
  }
  __syncthreads();
  float4v c = {0, 0, 0, 0};
#pragma unroll
  for (unsigned tile = 0; tile < 2; ++tile) {
    half4v next_a, next_b;
    if (tile == 0) {
#pragma unroll
      for (unsigned component = 0; component < 4; ++component) {
        unsigned linear = lane * 4 + component;
        next_a[component] = a[producer_row * 32 + 16 + (lane & 3) * 4 + component];
        next_b[component] = b[(16 + linear / 16) * 16 + linear % 16];
      }
    }
    unsigned a_index = (1 - wave) * 256 + (lane & 15) * 16 + (lane / 16) * 4;
    unsigned b_index = (1 - wave) * 256 + (lane / 16) * 64 + (lane & 15);
    half4v av, bv;
#pragma unroll
    for (unsigned component = 0; component < 4; ++component) {
      av[component] = tile_a[tile & 1][a_index + component];
      bv[component] = tile_b[tile & 1][b_index + component * 16];
    }
    c = __builtin_amdgcn_mfma_f32_16x16x16f16(av, bv, c, 0, 0, 0);
    __syncthreads();
    if (tile == 0) {
#pragma unroll
      for (unsigned component = 0; component < 4; ++component) {
        tile_a[1][t * 4 + component] = next_a[component];
        tile_b[1][t * 4 + component] = next_b[component];
      }
    }
    __syncthreads();
  }
#pragma unroll
  for (unsigned component = 0; component < 4; ++component)
    out[(wave * 16 + (lane / 16) * 4 + component) * 16 + (lane & 15)] = (_Float16)c[component];
}

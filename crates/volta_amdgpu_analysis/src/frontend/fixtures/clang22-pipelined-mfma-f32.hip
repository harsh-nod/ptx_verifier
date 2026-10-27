// Reduced native matrix/synchronization fixture: M=32, N=16, K=8, two wave64s.
// Two 4-wide tiles preserve LDS permutation, alternate buffers and repeated
// producer/consumer barriers. This FP32 fixture is not FP16 workload parity.
#include <hip/hip_runtime.h>
typedef float float4v __attribute__((ext_vector_type(4)));

extern "C" __global__ __launch_bounds__(128)
void pipelined_mfma_f32(const float *a, const float *b, float *out) {
  __shared__ float tile_a[2][128], tile_b[2][128];
  unsigned t = threadIdx.x, lane = t & 63, wave = t / 64;
  // Each wave produces the other wave's A rows. Cross-wave readers make the
  // workgroup rendezvous essential, unlike a same-wave-only toy pipeline.
  unsigned row = (1 - wave) * 16 + lane / 4, k = lane & 3;
  tile_a[0][t] = a[row * 8 + k];
  tile_b[0][t] = b[(lane / 16) * 16 + (lane & 15)];
  __syncthreads();
  float4v c = {0, 0, 0, 0};
#pragma unroll
  for (unsigned tile = 0; tile < 2; ++tile) {
    float next_a = 0, next_b = 0;
    if (tile == 0) {
      next_a = a[row * 8 + 4 + k];
      next_b = b[(4 + lane / 16) * 16 + (lane & 15)];
    }
    // A producer's lane differs from the MFMA reader's lane, forcing real LDS
    // exchange instead of same-lane register forwarding.
    unsigned a_index = (1 - wave) * 64 + (lane & 15) * 4 + lane / 16;
    unsigned b_index = (1 - wave) * 64 + lane;
    c = __builtin_amdgcn_mfma_f32_16x16x4f32(
        tile_a[tile & 1][a_index], tile_b[tile & 1][b_index], c, 0, 0, 0);
    __syncthreads();
    if (tile == 0) {
      tile_a[1][t] = next_a;
      tile_b[1][t] = next_b;
    }
    __syncthreads();
  }
  // CDNA4 MFMA output fragments: four adjacent rows for each lane group,
  // column from lane modulo16. Basis/coordinate hardware tests validate this.
#pragma unroll
  for (unsigned component = 0; component < 4; ++component)
    out[(wave * 16 + (lane / 16) * 4 + component) * 16 + (lane & 15)] = c[component];
}

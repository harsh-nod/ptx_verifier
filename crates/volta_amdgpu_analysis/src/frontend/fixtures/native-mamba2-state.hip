// Reconstructed from Mamba2ChunkStateForward's actual PTX and harness.
// Complete64x128 FP32 state, all256 time steps, original512-element input pitch.
// B is weighted in FP32 and rounded to F16 before its matrix consumption.
#include <hip/hip_runtime.h>
typedef _Float16 half8v __attribute__((ext_vector_type(8)));
typedef _Float16 half16v __attribute__((ext_vector_type(16)));
typedef float float16v __attribute__((ext_vector_type(16)));

__device__ __forceinline__ void state_prefetch(
    const _Float16 *x, const _Float16 *b, const float *dt, const float *da,
    float last, unsigned base, unsigned t, half8v &px, half16v &pb) {
#pragma unroll
  for (unsigned j = 0; j < 8; ++j) {
    unsigned linear = t + j * 128;
    px[j] = x[(base + linear / 64) * 512 + linear % 64];
  }
#pragma unroll
  for (unsigned j = 0; j < 16; ++j) {
    unsigned step = base + j;
    float decay = fminf(last - da[step], 0.0f);
    float weight = dt[step] * __builtin_amdgcn_exp2f(decay * 0x1.715476p+0f);
    pb[j] = (_Float16)((float)b[step * 512 + t] * weight);
  }
}
__device__ __forceinline__ void state_publish(_Float16 *sx, _Float16 *sb,
                                             unsigned t, half8v px, half16v pb) {
#pragma unroll
  for (unsigned j = 0; j < 8; ++j) {
    unsigned linear = t + j * 128;
    sx[(linear % 64) * 16 + linear / 64] = px[j];
  }
#pragma unroll
  for (unsigned j = 0; j < 16; ++j)
    sb[t * 16 + j] = pb[j];
}

extern "C" __global__ __launch_bounds__(128)
void mamba2_chunk_state_full(const _Float16 *x, const _Float16 *b,
                              float *states, const float *dt, const float *da) {
  __shared__ __align__(16) _Float16 sx[2][1024], sb[2][2048];
  unsigned t = threadIdx.x, lane = t & 63, wave = t >> 6;
  // Preserve the original bijective batch/chunk/head workgroup ordering.
  unsigned tile = blockIdx.z * 512 + blockIdx.y;
  unsigned head = tile & 7, batch = tile >> 6, chunk = (tile >> 3) & 7;
  x += batch * 1048576 + chunk * 131072 + head * 64;
  b += batch * 1048576 + chunk * 131072 + (head >> 1) * 128;
  states += batch * 524288 + chunk * 65536 + head * 8192;
  dt += batch * 16384 + chunk * 256 + head * 2048;
  da += batch * 16384 + chunk * 256 + head * 2048;
  float last = da[255];
  half8v first_x;
  half16v first_b;
  state_prefetch(x, b, dt, da, last, 0, t, first_x, first_b);
  state_publish(sx[0], sb[0], t, first_x, first_b);
  __syncthreads();
  float16v acc[4] = {};
#pragma unroll 1
  for (unsigned base = 0; base < 256; base += 16) {
    unsigned slot = (base / 16) & 1;
    half8v next_x;
    half16v next_b;
    if (base + 16 < 256)
      state_prefetch(x, b, dt, da, last, base + 16, t, next_x, next_b);
    unsigned k = (lane >> 5) * 8;
    half8v av = *reinterpret_cast<const half8v *>(&sx[slot][(wave * 32 + (lane & 31)) * 16 + k]);
#pragma unroll
    for (unsigned column = 0; column < 4; ++column) {
      half8v bv = *reinterpret_cast<const half8v *>(&sb[slot][(column * 32 + (lane & 31)) * 16 + k]);
      acc[column] = __builtin_amdgcn_mfma_f32_32x32x16_f16(av, bv, acc[column], 0, 0, 0);
    }
    if (base + 16 < 256)
      state_publish(sx[slot ^ 1], sb[slot ^ 1], t, next_x, next_b);
    __syncthreads();
  }
#pragma unroll
  for (unsigned column = 0; column < 4; ++column) {
#pragma unroll
    for (unsigned j = 0; j < 16; ++j) {
      unsigned row = wave * 32 + (lane >> 5) * 4 + (j & 3) + (j / 4) * 8;
      unsigned col = column * 32 + (lane & 31);
      states[row * 128 + col] = acc[column][j];
    }
  }
}

// Original Mamba2 state and scan computations on native gfx1250 wave32 WMMA.
// All source pitches, FP32 weights, and pre-WMMA FP16 conversions are retained.
#include <hip/hip_runtime.h>
typedef _Float16 mamba_half16 __attribute__((ext_vector_type(16)));
typedef float mamba_float8 __attribute__((ext_vector_type(8)));

__device__ __forceinline__ void state_stage(const _Float16 *x, const _Float16 *b, const float *dt,
                                            const float *da, float last, unsigned base,
                                            unsigned thread, _Float16 *sx, _Float16 *sb) {
#pragma unroll 1
  for (unsigned i = thread; i < 2048; i += 64)
    sx[i] = x[(base + i % 32) * 512 + i / 32];
#pragma unroll 1
  for (unsigned i = thread; i < 4096; i += 64) {
    unsigned step = base + i % 32, state = i / 32;
    float decay = fminf(last - da[step], 0.0f);
    float weight = dt[step] * __builtin_amdgcn_exp2f(decay * 0x1.715476p+0f);
    sb[i] = (_Float16)((float)b[step * 512 + state] * weight);
  }
}
extern "C" __global__
__launch_bounds__(64) void mamba_state_original(const _Float16 *x, const _Float16 *b, float *states,
                                                const float *dt, const float *da,
                                                const void *seq_idx) {
  __shared__ __align__(16) _Float16 sx[2][2048], sb[2][4096];
  unsigned thread = threadIdx.x, lane = thread & 31, wave = thread / 32;
  unsigned tile = blockIdx.z * 512 + blockIdx.y;
  unsigned head = tile & 7, batch = tile >> 6, chunk = (tile >> 3) & 7;
  x += batch * 1048576 + chunk * 131072 + head * 64;
  b += batch * 1048576 + chunk * 131072 + (head >> 1) * 128;
  states += batch * 524288 + chunk * 65536 + head * 8192;
  dt += batch * 16384 + chunk * 256 + head * 2048;
  da += batch * 16384 + chunk * 256 + head * 2048;
  float last = da[255];
  state_stage(x, b, dt, da, last, 0, thread, &sx[0][0], &sb[0][0]);
  __syncthreads();
  mamba_float8 accumulator[2][8] = {};
#pragma unroll 1
  for (unsigned base = 0; base < 256; base += 32) {
    unsigned slot = (base / 32) & 1;
    if (base + 32 < 256)
      state_stage(x, b, dt, da, last, base + 32, thread, &sx[slot ^ 1][0], &sb[slot ^ 1][0]);
#pragma unroll
    for (unsigned row_tile = 0; row_tile < 2; ++row_tile) {
      mamba_half16 a;
#pragma unroll
      for (unsigned element = 0; element < 16; ++element) {
        unsigned k = (element / 8) * 16 + (lane / 16) * 8 + element % 8;
        a[element] = sx[slot][(wave * 32 + row_tile * 16 + lane % 16) * 32 + k];
      }
#pragma unroll
      for (unsigned column_tile = 0; column_tile < 8; ++column_tile) {
        mamba_half16 bv;
#pragma unroll
        for (unsigned element = 0; element < 16; ++element) {
          unsigned k = (element / 8) * 16 + (lane / 16) * 8 + element % 8;
          bv[element] = sb[slot][(column_tile * 16 + lane % 16) * 32 + k];
        }
        accumulator[row_tile][column_tile] = __builtin_amdgcn_wmma_f32_16x16x32_f16(
            false, a, false, bv, 0, accumulator[row_tile][column_tile], false, false);
      }
    }
    __syncthreads();
  }
#pragma unroll
  for (unsigned row_tile = 0; row_tile < 2; ++row_tile)
#pragma unroll
    for (unsigned column_tile = 0; column_tile < 8; ++column_tile)
#pragma unroll
      for (unsigned element = 0; element < 8; ++element) {
        unsigned row = wave * 32 + row_tile * 16 + (lane / 16) * 8 + element;
        states[row * 128 + column_tile * 16 + lane % 16] =
            accumulator[row_tile][column_tile][element];
      }
}

template <bool State>
__device__ __forceinline__ void scan_stage(const float *cb, const _Float16 *x, const _Float16 *c,
                                           const float *prev, const float *dt, const float *da,
                                           unsigned row_base, unsigned base, unsigned thread,
                                           _Float16 *a, _Float16 *b) {
#pragma unroll 1
  for (unsigned i = thread; i < 1024; i += 64) {
    unsigned row = i / 32, k = base + i % 32;
    if constexpr (State)
      a[i] = c[row * 64 + k];
    else {
      float decay = fminf(da[row_base + row] - da[k], 0.0f);
      float factor = __builtin_amdgcn_exp2f(decay * 0x1.715476p+0f);
      float weighted = cb[row * 128 + k] * factor;
      a[i] = (_Float16)(weighted * dt[k]);
    }
  }
#pragma unroll 1
  for (unsigned i = thread; i < 4096; i += 64) {
    unsigned feature = i / 32, k = base + i % 32;
    if constexpr (State)
      b[i] = (_Float16)prev[feature * 32 + k];
    else
      b[i] = x[k * 1024 + feature];
  }
}

template <bool State, unsigned K>
__device__ __forceinline__ void scan_product(const float *cb, const _Float16 *x, const _Float16 *c,
                                             const float *prev, const float *dt, const float *da,
                                             unsigned row_base, unsigned thread, _Float16 *a,
                                             _Float16 *b, mamba_float8 (&accumulator)[8]) {
  unsigned lane = thread & 31, wave = thread / 32;
  scan_stage<State>(cb, x, c, prev, dt, da, row_base, 0, thread, a, b);
  __syncthreads();
#pragma unroll 1
  for (unsigned base = 0; base < K; base += 32) {
    unsigned slot = (base / 32) & 1;
    if (base + 32 < K)
      scan_stage<State>(cb, x, c, prev, dt, da, row_base, base + 32, thread, a + (slot ^ 1) * 1024,
                        b + (slot ^ 1) * 4096);
    mamba_half16 av;
#pragma unroll
    for (unsigned element = 0; element < 16; ++element) {
      unsigned k = (element / 8) * 16 + (lane / 16) * 8 + element % 8;
      av[element] = a[slot * 1024 + (wave * 16 + lane % 16) * 32 + k];
    }
#pragma unroll
    for (unsigned column_tile = 0; column_tile < 8; ++column_tile) {
      mamba_half16 bv;
#pragma unroll
      for (unsigned element = 0; element < 16; ++element) {
        unsigned k = (element / 8) * 16 + (lane / 16) * 8 + element % 8;
        bv[element] = b[slot * 4096 + (column_tile * 16 + lane % 16) * 32 + k];
      }
      accumulator[column_tile] = __builtin_amdgcn_wmma_f32_16x16x32_f16(
          false, av, false, bv, 0, accumulator[column_tile], false, false);
    }
    __syncthreads();
  }
}
extern "C" __global__ __launch_bounds__(64) void mamba_scan_original(
    const float *cb, const _Float16 *x, const void *z, _Float16 *out, _Float16 *out_x,
    const float *dt, const float *da, const void *seq_idx, const _Float16 *c, const float *prev,
    const void *d) {
  __shared__ __align__(16) _Float16 a[2][1024], b[2][4096];
  unsigned thread = threadIdx.x, lane = thread & 31, wave = thread / 32;
  unsigned batch = blockIdx.y & 3, chunk = blockIdx.y >> 2;
  unsigned head = blockIdx.z, group = head >> 2, row_base = blockIdx.x * 32;
  cb += batch * 524288 + chunk * 32768 + group * 16384 + row_base * 128;
  prev += batch * 524288 + chunk * 32768 + head * 4096;
  c += batch * 131072 + chunk * 8192 + group * 32 + row_base * 64;
  dt += batch * 16384 + chunk * 128 + head * 2048;
  da += batch * 16384 + chunk * 128 + head * 2048;
  x += batch * 2097152 + chunk * 131072 + head * 128;
  unsigned output_base = batch * 2097152 + chunk * 131072 + head * 128 + row_base * 1024;
  out += output_base;
  out_x += output_base;
  mamba_float8 state[8] = {};
  scan_product<true, 32>(cb, x, c, prev, dt, da, row_base, thread, &a[0][0], &b[0][0], state);
#pragma unroll
  for (unsigned tile = 0; tile < 8; ++tile)
#pragma unroll
    for (unsigned element = 0; element < 8; ++element) {
      unsigned row = wave * 16 + (lane / 16) * 8 + element;
      float factor = __builtin_amdgcn_exp2f(da[row_base + row] * 0x1.715476p+0f);
      state[tile][element] *= factor;
    }
  mamba_float8 scan[8] = {};
  scan_product<false, 128>(cb, x, c, prev, dt, da, row_base, thread, &a[0][0], &b[0][0], scan);
#pragma unroll
  for (unsigned tile = 0; tile < 8; ++tile)
#pragma unroll
    for (unsigned element = 0; element < 8; ++element) {
      unsigned row = wave * 16 + (lane / 16) * 8 + element, feature = tile * 16 + lane % 16;
      out[row * 1024 + feature] = (_Float16)(state[tile][element] + scan[tile][element]);
      out_x[row * 1024 + feature] = (_Float16)0;
    }
}

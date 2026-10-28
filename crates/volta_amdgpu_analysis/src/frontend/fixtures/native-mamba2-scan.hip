// Reconstructed from the actual Mamba2ChunkScanForward PTX and its launch harness.
// Full32x128 output, stateK32 + scanK128; original X/out pitch1024 and C pitch64.
// F32 previous states and weighted CB are rounded to F16 BEFORE matrix consumption.
// Native wave64/two-wave LDS publication replaces the source's tensor-memory/proxy
// mechanism. The missing PTX ProxyAsync fence is a separate source-specific residual.
#include <hip/hip_runtime.h>
typedef _Float16 scan_half4 __attribute__((ext_vector_type(4)));
typedef _Float16 scan_half16 __attribute__((ext_vector_type(16)));
typedef float scan_float4 __attribute__((ext_vector_type(4)));

template <bool State>
__device__ __forceinline__ void scan_prefetch(
    const float *cb, const _Float16 *x, const _Float16 *c,
    const float *prev, const float *dt, const float *da,
    unsigned row_base, unsigned base, unsigned t,
    scan_half4 &a, scan_half16 &b) {
#pragma unroll
  for (unsigned j = 0; j < 4; ++j) {
    unsigned linear = t + j * 128;
    unsigned row = linear / 16, k = base + linear % 16;
    if constexpr (State) {
      a[j] = c[row * 64 + k];
    } else {
      float decay = fminf(da[row_base + row] - da[k], 0.0f);
      float factor = __builtin_amdgcn_exp2f(decay * 0x1.715476p+0f);
      float weighted = cb[row * 128 + k] * factor;
      weighted = weighted * dt[k];
      a[j] = (_Float16)weighted;
    }
  }
#pragma unroll
  for (unsigned j = 0; j < 16; ++j) {
    unsigned linear = t + j * 128;
    unsigned feature = linear / 16, k = base + linear % 16;
    if constexpr (State)
      b[j] = (_Float16)prev[feature * 32 + k];
    else
      b[j] = x[k * 1024 + feature];
  }
}
__device__ __forceinline__ void scan_publish(_Float16 *a, _Float16 *b,
                                            unsigned t, scan_half4 pa,
                                            scan_half16 pb) {
#pragma unroll
  for (unsigned j = 0; j < 4; ++j) a[t + j * 128] = pa[j];
#pragma unroll
  for (unsigned j = 0; j < 16; ++j) b[t + j * 128] = pb[j];
}

template <bool State, unsigned K>
__device__ __forceinline__ void scan_product(
    const float *cb, const _Float16 *x, const _Float16 *c,
    const float *prev, const float *dt, const float *da,
    unsigned row_base, unsigned t, _Float16 *a, _Float16 *b,
    scan_float4 (&acc)[8]) {
  unsigned lane = t & 63, wave = t / 64;
  scan_half4 first_a;
  scan_half16 first_b;
  scan_prefetch<State>(cb, x, c, prev, dt, da, row_base, 0, t, first_a, first_b);
  scan_publish(a, b, t, first_a, first_b);
  __syncthreads(); // Cross-wave publication; the native safety mutant removes this barrier.
#pragma unroll 1
  for (unsigned base = 0; base < K; base += 16) {
    unsigned slot = (base / 16) & 1;
    scan_half4 next_a;
    scan_half16 next_b;
    if (base + 16 < K)
      scan_prefetch<State>(cb, x, c, prev, dt, da, row_base, base + 16, t, next_a, next_b);
    scan_half4 av = *reinterpret_cast<const scan_half4 *>(
        &a[slot * 512 + (wave * 16 + (lane & 15)) * 16 + (lane / 16) * 4]);
#pragma unroll
    for (unsigned tile = 0; tile < 8; ++tile) {
      scan_half4 bv = *reinterpret_cast<const scan_half4 *>(
          &b[slot * 2048 + (tile * 16 + (lane & 15)) * 16 + (lane / 16) * 4]);
      acc[tile] = __builtin_amdgcn_mfma_f32_16x16x16f16(av, bv, acc[tile], 0, 0, 0);
    }
    if (base + 16 < K)
      scan_publish(a + (slot ^ 1) * 512, b + (slot ^ 1) * 2048, t, next_a, next_b);
    __syncthreads();
  }
}

extern "C" __global__ __launch_bounds__(128)
void mamba2_chunk_scan_full(const float *cb, const _Float16 *x,
    const _Float16 *c, const float *prev, const float *dt, const float *da,
    _Float16 *out, _Float16 *out_x) {
  __shared__ __align__(16) _Float16 a[2][512], b[2][2048];
  unsigned t = threadIdx.x, lane = t & 63, wave = t / 64;
  unsigned batch = blockIdx.y & 3, chunk = blockIdx.y >> 2;
  unsigned head = blockIdx.z, group = head >> 2, row_base = blockIdx.x * 32;
  cb += batch * 524288 + chunk * 32768 + group * 16384 + row_base * 128;
  prev += batch * 524288 + chunk * 32768 + head * 4096;
  c += batch * 131072 + chunk * 8192 + group * 32 + row_base * 64;
  dt += batch * 16384 + chunk * 128 + head * 2048;
  da += batch * 16384 + chunk * 128 + head * 2048;
  x += batch * 2097152 + chunk * 131072 + head * 128;
  unsigned output_base = batch * 2097152 + chunk * 131072 + head * 128 + row_base * 1024;
  out += output_base; out_x += output_base;
  scan_float4 state[8] = {};
  scan_product<true, 32>(cb, x, c, prev, dt, da, row_base, t, &a[0][0], &b[0][0], state);
#pragma unroll
  for (unsigned tile = 0; tile < 8; ++tile) {
#pragma unroll
    for (unsigned component = 0; component < 4; ++component) {
      unsigned row = wave * 16 + (lane / 16) * 4 + component;
      float factor = __builtin_amdgcn_exp2f(da[row_base + row] * 0x1.715476p+0f);
      state[tile][component] *= factor;
    }
  }
  scan_float4 scan[8] = {};
  scan_product<false, 128>(cb, x, c, prev, dt, da, row_base, t, &a[0][0], &b[0][0], scan);
#pragma unroll
  for (unsigned tile = 0; tile < 8; ++tile) {
#pragma unroll
    for (unsigned component = 0; component < 4; ++component) {
      unsigned row = wave * 16 + (lane / 16) * 4 + component;
      unsigned feature = tile * 16 + (lane & 15);
      out[row * 1024 + feature] = (_Float16)(state[tile][component] + scan[tile][component]);
      out_x[row * 1024 + feature] = (_Float16)0;
    }
  }
}

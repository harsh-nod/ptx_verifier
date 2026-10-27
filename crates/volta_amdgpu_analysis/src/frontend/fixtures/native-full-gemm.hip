// Original row-major workload shapes: M=N=K=4096, CTA tile 256x256.
// Native launch: grid 16x16, block 1024 (16 wave64s rather than 8 NVIDIA warps).
// Every CTA produces 65,536 F16 outputs at their original 4096-element row pitch.
// The larger workgroup assigns 64 FP32 accumulators/lane without private spills.
// Both dtype paths retain two LDS buffers totaling 64 KiB and 128/64 K iterations.
#include <hip/hip_runtime.h>
typedef _Float16 half8v __attribute__((ext_vector_type(8)));
typedef unsigned char uchar16v __attribute__((ext_vector_type(16)));
typedef int int4v __attribute__((ext_vector_type(4)));
typedef int int8v __attribute__((ext_vector_type(8)));
typedef float float4v __attribute__((ext_vector_type(4)));
typedef float float16v __attribute__((ext_vector_type(16)));

__device__ __forceinline__ float full_gemm_silu(float value) {
  float e = __builtin_amdgcn_exp2f((-value) * 0x1.715476p+0f);
  return value * __builtin_amdgcn_rcpf(1.0f + e);
}

template<bool Fused>
__device__ __forceinline__ void full_f16(const _Float16 *a, const _Float16 *b,
                                        const _Float16 *add, _Float16 *out) {
  __shared__ __align__(16) _Float16 sa[2][8192], sb[2][8192];
  unsigned t = threadIdx.x, lane = t & 63, wave = t >> 6;
  unsigned row_base = blockIdx.x * 256, col_base = blockIdx.y * 256;
  unsigned ar = t / 4, ak = (t & 3) * 8;
  unsigned bk = t / 32, bc = (t & 31) * 8;
  half8v av0 = *reinterpret_cast<const half8v *>(a + (row_base + ar) * 4096 + ak);
  half8v bv0 = *reinterpret_cast<const half8v *>(b + bk * 4096 + col_base + bc);
  *reinterpret_cast<half8v *>(&sa[0][t * 8]) = av0;
#pragma unroll
  for (unsigned j = 0; j < 8; ++j)
    sb[0][(bc + j) * 32 + bk] = bv0[j];
  __syncthreads();
  float4v acc[16] = {};
#pragma unroll 1
  for (unsigned kbase = 0; kbase < 4096; kbase += 32) {
    unsigned slot = (kbase / 32) & 1;
    half8v next_a, next_b;
    if (kbase + 32 < 4096) {
      next_a = *reinterpret_cast<const half8v *>(a + (row_base + ar) * 4096 + kbase + 32 + ak);
      next_b = *reinterpret_cast<const half8v *>(b + (kbase + 32 + bk) * 4096 + col_base + bc);
    }
    unsigned input_k = (lane >> 4) * 8;
    half8v av = *reinterpret_cast<const half8v *>(&sa[slot][(wave * 16 + (lane & 15)) * 32 + input_k]);
#pragma unroll
    for (unsigned column = 0; column < 16; ++column) {
      half8v bv = *reinterpret_cast<const half8v *>(&sb[slot][(column * 16 + (lane & 15)) * 32 + input_k]);
      acc[column] = __builtin_amdgcn_mfma_f32_16x16x32_f16(av, bv, acc[column], 0, 0, 0);
    }
    if (kbase + 32 < 4096) {
      unsigned next_slot = slot ^ 1;
      *reinterpret_cast<half8v *>(&sa[next_slot][t * 8]) = next_a;
#pragma unroll
      for (unsigned j = 0; j < 8; ++j)
        sb[next_slot][(bc + j) * 32 + bk] = next_b[j];
    }
    // Releases next-buffer stores and keeps old-buffer reads ahead of its reuse.
    __syncthreads();
  }
#pragma unroll
  for (unsigned column = 0; column < 16; ++column) {
#pragma unroll
    for (unsigned j = 0; j < 4; ++j) {
      unsigned row = row_base + wave * 16 + (lane >> 4) * 4 + j;
      unsigned col = col_base + column * 16 + (lane & 15);
      float value = acc[column][j];
      if (Fused) value = full_gemm_silu(value + (float)add[row * 4096 + col]);
      out[row * 4096 + col] = (_Float16)value;
    }
  }
}

template<bool Fused>
__device__ __forceinline__ void full_f8(const unsigned char *a, const unsigned char *b,
                                       const unsigned char *add, _Float16 *out) {
  __shared__ __align__(16) unsigned char sa[2][16384], sb[2][16384];
  unsigned t = threadIdx.x, lane = t & 63, wave = t >> 6;
  unsigned row_base = blockIdx.x * 256, col_base = blockIdx.y * 256;
  unsigned wave_row = wave >> 1, wave_col = (wave & 1) * 128;
  unsigned ar = t / 4, ak = (t & 3) * 16;
  unsigned bk = t / 16, bc = (t & 15) * 16;
  int4v av0 = *reinterpret_cast<const int4v *>(a + (row_base + ar) * 4096 + ak);
  int4v bv0 = *reinterpret_cast<const int4v *>(b + bk * 4096 + col_base + bc);
  *reinterpret_cast<int4v *>(&sa[0][t * 16]) = av0;
  auto bytes0 = __builtin_bit_cast(uchar16v, bv0);
#pragma unroll
  for (unsigned j = 0; j < 16; ++j)
    sb[0][(bc + j) * 64 + bk] = bytes0[j];
  __syncthreads();
  float16v acc[4] = {};
#pragma unroll 1
  for (unsigned kbase = 0; kbase < 4096; kbase += 64) {
    unsigned slot = (kbase / 64) & 1;
    int4v next_a, next_b;
    if (kbase + 64 < 4096) {
      next_a = *reinterpret_cast<const int4v *>(a + (row_base + ar) * 4096 + kbase + 64 + ak);
      next_b = *reinterpret_cast<const int4v *>(b + (kbase + 64 + bk) * 4096 + col_base + bc);
    }
    // CDNA4 section 7.1.5 interleaves 16 K values between the two lane groups.
    unsigned input_k = (lane >> 5) * 16;
    unsigned a_index = (wave_row * 32 + (lane & 31)) * 64 + input_k;
    int4v al = *reinterpret_cast<const int4v *>(&sa[slot][a_index]);
    int4v ah = *reinterpret_cast<const int4v *>(&sa[slot][a_index + 32]);
    int8v av;
#pragma unroll
    for (unsigned j = 0; j < 4; ++j) { av[j] = al[j]; av[j + 4] = ah[j]; }
#pragma unroll
    for (unsigned column = 0; column < 4; ++column) {
      unsigned b_index = (wave_col + column * 32 + (lane & 31)) * 64 + input_k;
      int4v bl = *reinterpret_cast<const int4v *>(&sb[slot][b_index]);
      int4v bh = *reinterpret_cast<const int4v *>(&sb[slot][b_index + 32]);
      int8v bv;
#pragma unroll
      for (unsigned j = 0; j < 4; ++j) { bv[j] = bl[j]; bv[j + 4] = bh[j]; }
      // Format 0 is OCP E4M3; E8M0 byte 127 is the unit scale.
      acc[column] = __builtin_amdgcn_mfma_scale_f32_32x32x64_f8f6f4(
          av, bv, acc[column], 0, 0, 0, 127, 0, 127);
    }
    if (kbase + 64 < 4096) {
      unsigned next_slot = slot ^ 1;
      // Keep the packed prefetch live as four dwords until matrix consumption
      // finishes. This empty tied-register asm preserves every bit and prevents
      // LLVM from expanding all sixteen next-buffer bytes across the MFMAs.
      asm volatile("" : "+v"(next_b[0]), "+v"(next_b[1]),
                         "+v"(next_b[2]), "+v"(next_b[3]));
      *reinterpret_cast<int4v *>(&sa[next_slot][t * 16]) = next_a;
      auto next_bytes = __builtin_bit_cast(uchar16v, next_b);
#pragma unroll
      for (unsigned j = 0; j < 16; ++j)
        sb[next_slot][(bc + j) * 64 + bk] = next_bytes[j];
    }
    __syncthreads();
  }
#pragma unroll
  for (unsigned column = 0; column < 4; ++column) {
#pragma unroll
    for (unsigned j = 0; j < 16; ++j) {
      unsigned row = row_base + wave_row * 32 + (lane >> 5) * 4 + (j & 3) + (j / 4) * 8;
      unsigned col = col_base + wave_col + column * 32 + (lane & 31);
      float value = acc[column][j];
      if (Fused) {
        float decoded_add = __builtin_amdgcn_cvt_f32_fp8((unsigned)add[row * 4096 + col], 0);
        value = full_gemm_silu(value + decoded_add);
      }
      out[row * 4096 + col] = (_Float16)value;
    }
  }
}

extern "C" __global__ __launch_bounds__(1024)
void gemm_f16_full(const _Float16 *a, const _Float16 *b, _Float16 *out) {
  full_f16<false>(a, b, nullptr, out);
}
extern "C" __global__ __launch_bounds__(1024)
void gemm_add_silu_f16_full(const _Float16 *a, const _Float16 *b,
                            const _Float16 *add, _Float16 *out) {
  full_f16<true>(a, b, add, out);
}
extern "C" __global__ __launch_bounds__(1024)
void gemm_f8_full(const unsigned char *a, const unsigned char *b, _Float16 *out) {
  full_f8<false>(a, b, nullptr, out);
}
extern "C" __global__ __launch_bounds__(1024)
void gemm_add_silu_f8_full(const unsigned char *a, const unsigned char *b,
                           const unsigned char *add, _Float16 *out) {
  full_f8<true>(a, b, add, out);
}

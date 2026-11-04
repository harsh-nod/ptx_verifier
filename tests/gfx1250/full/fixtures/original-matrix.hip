// Original full K4096 matrix workloads, with gfx1250 wave32 WMMA mapping.
// External F16/OCP E4M3/packed-u32 storage and the 4096-column output pitch
// remain.
#include <hip/hip_runtime.h>

typedef _Float16 half16v __attribute__((ext_vector_type(16)));
typedef float float8v __attribute__((ext_vector_type(8)));

// The pinned gfx1250 LLVM hazard model requires four unrelated VALUs between
// this F16 WMMA and a VALU that reads its result or overwrites any fragment.
// Keep all fragments live through the explicit spacing; scalar instructions,
// waits and split barriers do not contribute to this VALU distance.
__device__ __forceinline__ void matrix_wmma_spacing(float8v &acc, half16v av,
                                                    half16v bv) {
  asm volatile("v_nop\n\tv_nop\n\tv_nop\n\tv_nop"
               : "+v"(acc)
               : "v"(av), "v"(bv)
               : "memory");
}

template <class T> __device__ __forceinline__ _Float16 matrix_half(T value) {
  return value;
}
template <>
__device__ __forceinline__ _Float16 matrix_half(unsigned char value) {
  return (_Float16)__builtin_amdgcn_cvt_f32_fp8((unsigned)value, 0);
}
__device__ __forceinline__ float matrix_silu(float value) {
  return value * __builtin_amdgcn_rcpf(
                     1.0f + __builtin_amdgcn_exp2f(-value * 0x1.715476p+0f));
}

template <class T, bool Fused>
__device__ __forceinline__ void matrix_gemm(const T *a, const T *b,
                                            const T *add, _Float16 *out) {
  __shared__ __align__(16) _Float16 as[2][256 * 32], bs[2][256 * 32];
  unsigned t = threadIdx.x, lane = t & 31, wave = t >> 5;
  unsigned row_base = blockIdx.x * 256, col_base = blockIdx.y * 256;
  unsigned wave_row = wave >> 1, wave_col = (wave & 1) * 128;
  for (unsigned pass = 0; pass < 2; ++pass) {
    float8v acc[4] = {};
    for (unsigned j = t; j < 256 * 32; j += 1024) {
      as[0][j] = matrix_half(a[(row_base + j / 32) * 4096 + j % 32]);
      bs[0][j] = matrix_half(b[(j % 32) * 4096 + col_base + j / 32]);
    }
    __syncthreads();
#pragma unroll 1
    for (unsigned kbase = 0; kbase < 4096; kbase += 32) {
      unsigned slot = (kbase / 32) & 1;
      half16v av;
#pragma unroll
      for (unsigned j = 0; j < 16; ++j) {
        unsigned k = (j / 8) * 16 + (lane / 16) * 8 + j % 8;
        av[j] = as[slot][(wave_row * 16 + lane % 16) * 32 + k];
      }
#pragma unroll
      for (unsigned column = 0; column < 4; ++column) {
        half16v bv;
#pragma unroll
        for (unsigned j = 0; j < 16; ++j) {
          unsigned k = (j / 8) * 16 + (lane / 16) * 8 + j % 8;
          bv[j] = bs[slot]
                    [(wave_col + pass * 64 + column * 16 + lane % 16) * 32 + k];
        }
        acc[column] = __builtin_amdgcn_wmma_f32_16x16x32_f16(
            false, av, false, bv, 0, acc[column], false, false);
        matrix_wmma_spacing(acc[column], av, bv);
      }
      if (kbase + 32 < 4096) {
        for (unsigned j = t; j < 256 * 32; j += 1024) {
          as[slot ^ 1][j] =
              matrix_half(a[(row_base + j / 32) * 4096 + kbase + 32 + j % 32]);
          bs[slot ^ 1][j] =
              matrix_half(b[(kbase + 32 + j % 32) * 4096 + col_base + j / 32]);
        }
      }
      __syncthreads();
    }
#pragma unroll
    for (unsigned column = 0; column < 4; ++column) {
#pragma unroll
      for (unsigned j = 0; j < 8; ++j) {
        unsigned row = row_base + wave_row * 16 + (lane / 16) * 8 + j;
        unsigned col =
            col_base + wave_col + pass * 64 + column * 16 + lane % 16;
        float value = acc[column][j];
        if (Fused)
          value =
              matrix_silu(value + (float)matrix_half(add[row * 4096 + col]));
        out[row * 4096 + col] = (_Float16)value;
      }
    }
  }
}

template <unsigned Rows, unsigned Columns>
__device__ __forceinline__ void
matrix_bitdelta(const _Float16 *a, const unsigned *packed, _Float16 *out) {
  __shared__ __align__(16) _Float16 as[2][Rows * 32], bs[2][Columns * 32];
  constexpr unsigned WaveColumns = Columns == 128 ? 2 : 1;
  constexpr unsigned Passes = Columns == 256 ? 2 : 1;
  constexpr unsigned Accumulators = Columns / WaveColumns / Passes / 16;
  unsigned t = threadIdx.x, lane = t & 31, wave = t >> 5;
  unsigned pid = blockIdx.x;
  unsigned row_base, col_base, batch;
  if (Rows == 64) {
    row_base = ((pid >> 8) * 8 + (pid & 7)) * 64;
    col_base = ((pid >> 3) & 31) * 128;
    batch = 0;
  } else {
    row_base = ((pid >> 7) * 8 + (pid & 7)) * 128;
    col_base = ((pid & 127) >> 3) * 256;
    batch = blockIdx.y;
  }
  a += (unsigned long)batch * 4096 * 4096;
  packed += (unsigned long)batch * 128 * 4096;
  out += (unsigned long)batch * 4096 * 4096;
  unsigned wave_row = wave / WaveColumns;
  unsigned wave_col = (wave % WaveColumns) * (Columns / WaveColumns);
  for (unsigned pass = 0; pass < Passes; ++pass) {
    float8v acc[Accumulators] = {};
    for (unsigned j = t; j < Rows * 32; j += 256)
      as[0][j] = a[(row_base + j / 32) * 4096 + j % 32];
    if (t < Columns) {
      unsigned word = packed[col_base + t];
#pragma unroll
      for (unsigned k = 0; k < 32; ++k)
        bs[0][t * 32 + k] = ((word >> k) & 1) ? (_Float16)1 : (_Float16)-1;
    }
    __syncthreads();
#pragma unroll 1
    for (unsigned kbase = 0; kbase < 4096; kbase += 32) {
      unsigned slot = (kbase / 32) & 1;
      half16v av;
#pragma unroll
      for (unsigned j = 0; j < 16; ++j) {
        unsigned k = (j / 8) * 16 + (lane / 16) * 8 + j % 8;
        av[j] = as[slot][(wave_row * 16 + lane % 16) * 32 + k];
      }
#pragma unroll
      for (unsigned column = 0; column < Accumulators; ++column) {
        half16v bv;
#pragma unroll
        for (unsigned j = 0; j < 16; ++j) {
          unsigned k = (j / 8) * 16 + (lane / 16) * 8 + j % 8;
          bv[j] = bs[slot][(wave_col + pass * (Columns / Passes) + column * 16 +
                            lane % 16) *
                               32 +
                           k];
        }
        acc[column] = __builtin_amdgcn_wmma_f32_16x16x32_f16(
            false, av, false, bv, 0, acc[column], false, false);
        matrix_wmma_spacing(acc[column], av, bv);
      }
      if (kbase + 32 < 4096) {
        for (unsigned j = t; j < Rows * 32; j += 256)
          as[slot ^ 1][j] = a[(row_base + j / 32) * 4096 + kbase + 32 + j % 32];
        if (t < Columns) {
          unsigned word = packed[((kbase + 32) / 32) * 4096 + col_base + t];
#pragma unroll
          for (unsigned k = 0; k < 32; ++k)
            bs[slot ^ 1][t * 32 + k] =
                ((word >> k) & 1) ? (_Float16)1 : (_Float16)-1;
        }
      }
      __syncthreads();
    }
#pragma unroll
    for (unsigned column = 0; column < Accumulators; ++column) {
#pragma unroll
      for (unsigned j = 0; j < 8; ++j) {
        unsigned row = row_base + wave_row * 16 + (lane / 16) * 8 + j;
        unsigned col = col_base + wave_col + pass * (Columns / Passes) +
                       column * 16 + lane % 16;
        out[row * 4096 + col] = (_Float16)acc[column][j];
      }
    }
  }
}

extern "C" __global__
__launch_bounds__(1024) void gemm_f16_full(const _Float16 *a, const _Float16 *b,
                                           _Float16 *out) {
  matrix_gemm<_Float16, false>(a, b, nullptr, out);
}
extern "C" __global__ __launch_bounds__(1024) void gemm_f8_full(
    const unsigned char *a, const unsigned char *b, _Float16 *out) {
  matrix_gemm<unsigned char, false>(a, b, nullptr, out);
}
extern "C" __global__ __launch_bounds__(1024) void gemm_add_silu_f16_full(
    const _Float16 *a, const _Float16 *b, const _Float16 *add, _Float16 *out) {
  matrix_gemm<_Float16, true>(a, b, add, out);
}
extern "C" __global__ __launch_bounds__(1024) void gemm_add_silu_f8_full(
    const unsigned char *a, const unsigned char *b, const unsigned char *add,
    _Float16 *out) {
  matrix_gemm<unsigned char, true>(a, b, add, out);
}
extern "C" __global__ __launch_bounds__(256) void bitdelta_full(
    const _Float16 *a, const unsigned *packed, _Float16 *out) {
  matrix_bitdelta<64, 128>(a, packed, out);
}
extern "C" __global__ __launch_bounds__(256) void bitdelta_batched_full(
    const _Float16 *a, const unsigned *packed, _Float16 *out) {
  matrix_bitdelta<128, 256>(a, packed, out);
}

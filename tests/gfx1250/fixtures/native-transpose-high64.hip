// Portable counterparts to packed16 8x8 transpose and exact wide product/carry.
#include <hip/hip_runtime.h>
#include <stdint.h>
extern "C" __global__ __launch_bounds__(32)
void transpose_8x8_b16(const unsigned short *x, unsigned short *out) {
  __shared__ unsigned short tile[64];
  unsigned t = threadIdx.x;
  tile[2 * t] = x[2 * t];
  tile[2 * t + 1] = x[2 * t + 1];
  __syncthreads();
  unsigned j = 2 * t;
  out[j] = tile[(j % 8) * 8 + j / 8];
  ++j;
  out[j] = tile[(j % 8) * 8 + j / 8];
}
extern "C" __global__ __launch_bounds__(1)
void high64_mul_mad(uint64_t a, uint64_t b, uint64_t c, uint64_t *out) {
  unsigned __int128 product = static_cast<unsigned __int128>(a) * b;
  out[0] = uint64_t(product >> 64);
  out[1] = uint64_t(product);
  product += c;
  out[2] = uint64_t(product >> 64);
  out[3] = uint64_t(product);
}
extern "C" __global__ __launch_bounds__(1)
void high64_signed_mul_mad(int64_t a, int64_t b, int64_t c, uint64_t *out) {
  __int128 product = static_cast<__int128>(a) * b;
  out[0] = uint64_t(product >> 64);
  out[1] = uint64_t(product);
  product += c;
  out[2] = uint64_t(product >> 64);
  out[3] = uint64_t(product);
}

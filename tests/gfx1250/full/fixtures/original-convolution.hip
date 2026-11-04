// Original Convolution2DKernel selected-CTA computations, native gfx1250 wave32.
// F16:128 spatial x128 channels; OCP E4M3:64 spatial x128 channels.
// NCHW1x64x56x56, OIHW128x64x3x3, valid54x54, K576, F16 output.
// Preserve block128. Two N64 passes partition the complete output tile; every
// output still accumulates all576 terms. Two LDS slots stage K32 input tiles.
#include <hip/hip_runtime.h>
typedef _Float16 half16v __attribute__((ext_vector_type(16)));
typedef float float8v __attribute__((ext_vector_type(8)));

template <bool FP8>
__device__ __forceinline__ _Float16 external_half(const void *data, unsigned index) {
  if constexpr (FP8)
    return (_Float16)__builtin_amdgcn_cvt_f32_fp8(
        unsigned(static_cast<const unsigned char *>(data)[index]), 0);
  else
    return static_cast<const _Float16 *>(data)[index];
}

template <bool FP8, unsigned Spatial>
__device__ __forceinline__ void publish_convolution_tile(
    const void *x, const void *weight, _Float16 *a, _Float16 *b,
    unsigned t, unsigned tile, unsigned column_pass) {
  for (unsigned linear=t; linear<Spatial*32; linear+=128) {
    unsigned spatial=blockIdx.x*Spatial+linear/32;
    unsigned k=tile*32+linear%32;
    unsigned image=spatial/2916, position=spatial%2916;
    unsigned channel=k/9, filter=k%9;
    unsigned row=position/54+filter/3, col=position%54+filter%3;
    a[linear]=external_half<FP8>(x,(image*64+channel)*3136+row*56+col);
  }
  for (unsigned linear=t; linear<64*32; linear+=128) {
    unsigned channel=blockIdx.y*128+column_pass*64+linear/32;
    b[linear]=external_half<FP8>(weight,channel*576+tile*32+linear%32);
  }
}

template <bool FP8, unsigned Spatial>
__device__ __forceinline__ void convolution(
    const void *x, const void *weight, _Float16 *out,
    _Float16 *shared_a, _Float16 *shared_b) {
  constexpr unsigned RowTiles=Spatial/(4*16);
  unsigned t=threadIdx.x, lane=t&31, wave=t/32;
#pragma unroll 1
  for (unsigned column_pass=0; column_pass<2; ++column_pass) {
    float8v accumulator[RowTiles][4]={};
    publish_convolution_tile<FP8,Spatial>(x,weight,shared_a,shared_b,t,0,column_pass);
    __syncthreads();
#pragma unroll 1
    for (unsigned tile=0; tile<18; ++tile) {
      unsigned slot=tile&1;
      if (tile+1<18)
        publish_convolution_tile<FP8,Spatial>(
            x,weight,shared_a+(slot^1)*Spatial*32,
            shared_b+(slot^1)*64*32,t,tile+1,column_pass);
#pragma unroll
      for (unsigned row_tile=0; row_tile<RowTiles; ++row_tile) {
        half16v a;
#pragma unroll
        for (unsigned element=0; element<16; ++element) {
          unsigned k=(element/8)*16+(lane/16)*8+element%8;
          a[element]=shared_a[slot*Spatial*32+
              (wave*RowTiles*16+row_tile*16+lane%16)*32+k];
        }
#pragma unroll
        for (unsigned col_tile=0; col_tile<4; ++col_tile) {
          half16v b;
#pragma unroll
          for (unsigned element=0; element<16; ++element) {
            unsigned k=(element/8)*16+(lane/16)*8+element%8;
            b[element]=shared_b[slot*64*32+(col_tile*16+lane%16)*32+k];
          }
          accumulator[row_tile][col_tile]=__builtin_amdgcn_wmma_f32_16x16x32_f16(
              false,a,false,b,0,accumulator[row_tile][col_tile],false,false);
        }
      }
      __syncthreads();
    }
#pragma unroll
    for (unsigned row_tile=0; row_tile<RowTiles; ++row_tile)
#pragma unroll
      for (unsigned col_tile=0; col_tile<4; ++col_tile)
#pragma unroll
        for (unsigned element=0; element<8; ++element) {
          unsigned spatial=blockIdx.x*Spatial+wave*RowTiles*16+
              row_tile*16+(lane/16)*8+element;
          unsigned channel=blockIdx.y*128+column_pass*64+col_tile*16+lane%16;
          out[((spatial/2916)*128+channel)*2916+spatial%2916]=
              (_Float16)accumulator[row_tile][col_tile][element];
        }
    // The next column pass reuses both LDS slots after all reads complete.
    __syncthreads();
  }
}
extern "C" __global__ __launch_bounds__(128)
void convolution_f16_original(const void *x, const void *weight, _Float16 *out) {
  __shared__ _Float16 a[2*128*32], b[2*64*32];
  convolution<false,128>(x,weight,out,a,b);
}
extern "C" __global__ __launch_bounds__(128)
void convolution_f8_original(const void *x, const void *weight, _Float16 *out) {
  __shared__ _Float16 a[2*64*32], b[2*64*32];
  convolution<true,64>(x,weight,out,a,b);
}

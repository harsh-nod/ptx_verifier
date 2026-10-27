#include <hip/hip_runtime.h>
extern "C" __global__ void exchange(const float *x, float *out) { __shared__ float tile[128]; unsigned i = threadIdx.x; tile[i] = x[i]; __syncthreads(); out[i] = tile[i ^ 64]; }
extern "C" __global__ void reduce(const float *x, float *out) { unsigned i = threadIdx.x; float a = x[i]; for (int d=32; d; d>>=1) a += __shfl_down(a,d); if ((i&63) == 0) out[i/64]=a; }
extern "C" __global__ void relu(const float *x, float *out) { unsigned i = threadIdx.x; float a=x[i]; out[i] = fmaxf(a,0.0f); }

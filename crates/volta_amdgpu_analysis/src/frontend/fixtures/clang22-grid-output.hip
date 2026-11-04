// Launch block4x3x2, grid2x3x4. One workitem per workgroup writes9fields;
// each workgroup owns a separate row, permitting a full-grid physical check.
#include <hip/hip_runtime.h>
extern "C" __global__ void grid_output(unsigned *out) {
  if(threadIdx.x==0&&threadIdx.y==0&&threadIdx.z==0) {
    unsigned group=blockIdx.x+gridDim.x*(blockIdx.y+gridDim.y*blockIdx.z);
    out+=group*9;
    out[0]=gridDim.x; out[1]=gridDim.y; out[2]=gridDim.z;
    out[3]=blockIdx.x; out[4]=blockIdx.y; out[5]=blockIdx.z;
    out[6]=blockDim.x; out[7]=blockDim.y; out[8]=blockDim.z;
  }
}

#include <hip/hip_runtime.h>

// Launch block=(4,3,2). Each workitem writes one unique element and coordinate.
// Workgroup coordinates participate in the value so selected groups are visible.
extern "C" __global__ void ids_3d(float *out) {
  unsigned x = threadIdx.x, y = threadIdx.y, z = threadIdx.z;
  unsigned index = x + blockDim.x * (y + blockDim.y * z);
  unsigned coordinate = x + 10 * y + 100 * z +
                        1000 * blockIdx.x + 10000 * blockIdx.y +
                        100000 * blockIdx.z;
  out[index] = (float)coordinate;
}

// Native counterparts of the upstream CLI index-set soundness controls.
// Exactly one active work-item matches the original PTX launch.
#include <hip/hip_runtime.h>

extern "C" __global__ __attribute__((amdgpu_flat_work_group_size(1, 1)))
void output_complete(unsigned *out) {
  out[0] = 0;
  out[1] = 0;
}

extern "C" __global__ __attribute__((amdgpu_flat_work_group_size(1, 1)))
void output_partial(unsigned *out) {
  out[0] = 0;
}

extern "C" __global__ __attribute__((amdgpu_flat_work_group_size(1, 1)))
void output_shifted(unsigned *out) {
  out[0] = 0;
  out[2] = 0;
}

// Real-model boundary controls. Invalid/racy programs are tested on CPU only.
#include <hip/hip_runtime.h>
__device__ __forceinline__ unsigned integer_value(unsigned value) {
  asm volatile("v_add_nc_u32 %0, 0, %0" : "+v"(value));
  return value;
}
__device__ __forceinline__ void branch_on_float(float value) {
  asm volatile("v_cmp_lt_f32_e32 vcc_lo, 0, %0\n\t"
               "s_cbranch_vccnz .Lmodel_branch_%=\n\t"
               "s_nop 0\n\t"
               ".Lmodel_branch_%=:"
               :
               : "v"(value)
               : "vcc");
}
extern "C" __global__ void model_nan_bits(float *out) {
  float value;
  asm volatile("v_mov_b32 %0, 0x7fc00000" : "=v"(value));
  out[0] = value + value;
}
extern "C" __global__ void model_zero_over_zero(float *out) {
  float zero;
  asm volatile("v_mov_b32 %0, 0" : "=v"(zero));
  out[0] = zero * __builtin_amdgcn_rcpf(zero);
}
extern "C" __global__ void model_branch(const float *x, float *out) {
  float value = x[0];
  branch_on_float(value);
  out[0] = value;
}
extern "C" __global__ void model_branch_parameter(float *out, float value) {
  branch_on_float(value);
  asm volatile("v_add_f32 %0, 0, %0" : "+v"(value));
  out[0] = value;
}
extern "C" __global__ void model_divide_two(const unsigned *x, unsigned *out) {
  out[0] = integer_value(x[0] / 2u);
}
extern "C" __global__ void model_divide_then_double(const unsigned *x, unsigned *out) {
  out[0] = integer_value((x[0] / 2u) * 2u);
}
extern "C" __global__ void model_divide_concrete(unsigned *out) {
  unsigned value;
  asm volatile("v_mov_b32 %0, 7" : "=v"(value));
  out[0] = integer_value(value / 2u);
}

extern "C" __global__ void model_truncated_store(const unsigned *x, unsigned char *out) {
  out[0] = static_cast<unsigned char>(x[0]);
}
extern "C" __global__ void model_truncated_concrete(unsigned char *out, unsigned value) {
  out[0] = static_cast<unsigned char>(integer_value(value));
}
extern "C" __global__ void model_predicate_side_effect(unsigned *out) {
  // The baseline reduces the same negative packed word in both lanes. Both
  // overwritten predicates are true; preserving the side effect means a race.
  const int common_negative = static_cast<int>(0xbc00bc00u);
  if (common_negative < 0 || threadIdx.x == 0)
    out[0] = integer_value(1);
}
extern "C" __global__ void model_predicate_single_writer(unsigned *out) {
  if (threadIdx.x == 0)
    out[0] = integer_value(1);
}

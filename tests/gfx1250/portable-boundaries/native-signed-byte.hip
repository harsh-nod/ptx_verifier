// Signed symbolic byte widening control; volatile forces the actual GLOBAL path.
#include <hip/hip_runtime.h>
extern "C" __global__ void model_signed_byte(const volatile signed char *x, unsigned *out) {
  out[0] = static_cast<unsigned>(static_cast<int>(x[0]));
}

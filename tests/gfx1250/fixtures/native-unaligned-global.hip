// HSA GLOBAL unaligned access: every four-byte transfer is inside16 bytes.
#include <hip/hip_runtime.h>
#include <stdint.h>

#define COPY(OFFSET) \
  extern "C" __global__ __launch_bounds__(1) \
  void global_unaligned_##OFFSET(const uint8_t *input, uint8_t *out) { \
    uint32_t word; \
    __builtin_memcpy(&word, input + OFFSET, sizeof(word)); \
    asm volatile("" : "+v"(word)); \
    __builtin_memcpy(out + OFFSET, &word, sizeof(word)); \
  }
COPY(1)
COPY(2)
COPY(3)
COPY(5)
COPY(7)

#include "kittens.cuh"
#include <cstddef>
using B = kittens::gl<kittens::bf16,1,1,16,16>;
using H = kittens::gl<kittens::half,1,1,16,16>;
static_assert(sizeof(B)==16 && alignof(B)==8 && offsetof(B,raw_ptr)==0);
static_assert(sizeof(H)==16 && alignof(H)==8 && offsetof(H,raw_ptr)==0);

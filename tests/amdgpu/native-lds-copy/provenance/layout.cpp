#include "kittens.cuh"
#include <cstddef>
using G = kittens::gl<float,1,1,1,64>;
static_assert(sizeof(G)==16 && alignof(G)==8 && offsetof(G,raw_ptr)==0);
static_assert(kittens::MAX_SHARED_MEMORY==160000 && kittens::WARP_THREADS==64);

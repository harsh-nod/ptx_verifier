// Verifier control using HipKittens' real global/register vector operations.
// This is a local primitive probe, not an upstream application kernel.
#include "kittens.cuh"

using GL = kittens::gl<float, -1, -1, -1, -1>;
using Vector = kittens::rv_fl<256, 64, kittens::rt_16x16_s, kittens::ortho_l>;

extern "C" __global__ __launch_bounds__(64)
void hk_vector_copy(const GL x, const GL out) {
    Vector vector;
    kittens::load(vector, x, {0, 0, 0, 0});
    asm volatile("s_waitcnt vmcnt(0)" ::: "memory");
    kittens::store(out, vector, {0, 0, 0, 0});
}

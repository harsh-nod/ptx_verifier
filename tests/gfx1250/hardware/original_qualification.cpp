#include "../../amdgpu/original-kernel-qualification/hardware.hpp"

int main(int argc, char **argv) {
  return original_qualification::execute(argc, argv, "gfx1250");
}

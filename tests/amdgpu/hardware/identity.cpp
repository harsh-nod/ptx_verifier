// Reuse the common HIP identity probe without numerical-reference helpers.
#define VOLTA_HARDWARE_IDENTITY_ONLY
#include "../../gfx1250/full/hardware/original_common.hpp"

int main() {
  try {
    std::puts(selected_device_identity_json().c_str());
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "device identity failed: %s\n", error.what());
    return 1;
  }
}

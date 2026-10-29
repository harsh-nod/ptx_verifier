// Only the four source-verified safe entries; no ambiguous or harmful controls.
#include "original_common.hpp"

int main(int argc, char **argv) {
  try {
    validate_reference_controls();
    if (argc == 2 && std::string(argv[1]) == "--cpu-only") return 0;
    require(argc == 3 && std::string(argv[2]) == "8", "requires exact module and eight repetitions");
    hipDeviceProp_t device{};
    hip_check(hipGetDeviceProperties(&device, 0), "get actual device");
    const std::string architecture = device.gcnArchName;
    require(architecture.substr(0, architecture.find(':')) == "gfx1250" && device.warpSize == 32,
            "requires actual gfx1250 wave32");
    hipModule_t module{};
    hip_check(hipModuleLoad(&module, argv[1]), "load exact count-update compiler module");
    const char *kernels[] = {"named_phase_count_update7", "named_zero_update_marker7",
                            "named_null_update_marker7", "named_max_signal_count7"};
    const unsigned blocks[] = {64, 1, 1, 1};
    std::vector<Row> rows;
    for (const char *kernel : kernels) rows.push_back(Row{kernel});
    for (unsigned repetition = 0; repetition < 8; ++repetition) {
      for (size_t index = 0; index < rows.size(); ++index) {
        const size_t count = index == 0 ? 2 : 1;
        // One extra NaN word must remain untouched beyond the exact ABI output.
        Buffer out(Type::Float, count + 1, true);
        std::vector<double> expected(count + 1, 7.);
        expected.back() = NAN;
        run(module, kernels[index], dim3(blocks[index]), {&out.pointer}, {&out},
            out, expected, rows[index], 0, 0);
      }
    }
    hip_check(hipModuleUnload(module), "unload exact count-update module");
    std::printf("{\"status\":\"pass\",\"architecture\":\"gfx1250\",\"wave_size\":32,"
                "\"reference_controls\":\"pass\",\"patterns\":8,\"cases\":[");
    for (size_t i = 0; i < rows.size(); ++i) {
      const auto &r = rows[i];
      std::printf("%s{\"kernel\":\"%s\",\"outputs\":%zu,\"launches\":%zu,"
                  "\"unchanged_input_bytes\":%zu,\"unchanged_guard_bytes\":%zu,"
                  "\"unchanged_gap_bytes\":%zu,\"max_absolute_error\":%.12g}",
                  i ? "," : "", r.kernel.c_str(), r.outputs, r.launches,
                  r.unchanged_input_bytes, r.unchanged_guard_bytes, r.unchanged_gap_bytes, r.maximum);
    }
    std::puts("]}");
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "signal-count hardware validation failed: %s\n", error.what());
    return 1;
  }
}

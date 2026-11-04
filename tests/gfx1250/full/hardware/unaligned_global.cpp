#include "original_common.hpp"

int main(int argc, char **argv) {
  try {
    validate_reference_controls();
    if (argc == 2 && std::string(argv[1]) == "--cpu-only") return 0;
    require(argc == 3 && std::string(argv[2]) == "8", "requires exact module and eight patterns");
    hipDeviceProp_t device{};
    hip_check(hipGetDeviceProperties(&device, 0), "get actual device");
    const std::string architecture = device.gcnArchName;
    require(architecture.substr(0, architecture.find(':')) == "gfx1250" && device.warpSize == 32,
            "requires actual gfx1250 wave32");
    hipModule_t module{};
    hip_check(hipModuleLoad(&module, argv[1]), "load exact compiler module");
    const unsigned offsets[] = {1, 2, 3, 5, 7};
    std::vector<Row> rows;
    for (unsigned offset : offsets) rows.push_back(Row{"global_unaligned_" + std::to_string(offset)});
    for (unsigned pattern = 0; pattern < 8; ++pattern) {
      for (size_t index = 0; index < rows.size(); ++index) {
        const unsigned offset = offsets[index];
        Buffer input(Type::I8, 16), out(Type::I8, 16, true);
        std::vector<double> expected(16, std::numeric_limits<double>::quiet_NaN());
        for (size_t i = 0; i < 16; ++i) input.set(i, int((i * 19 + pattern * 31) % 256) - 128);
        for (unsigned i = offset; i < offset + 4; ++i) {
          expected[i] = input.get(i);
          out.before[Buffer::guard + i] = input.before[Buffer::guard + i] ^ 0xff;
        }
        run(module, rows[index].kernel, dim3(1), {&input.pointer, &out.pointer},
            {&input, &out}, out, expected, rows[index], 0, 0);
      }
    }
    hip_check(hipModuleUnload(module), "unload exact module");
    std::printf("{\"status\":\"pass\",\"architecture\":\"gfx1250\",\"wave_size\":32,"
                "\"reference_controls\":\"pass\",\"patterns\":8,\"cases\":[");
    for (size_t i = 0; i < rows.size(); ++i) {
      const auto &r = rows[i];
      std::printf("%s{\"kernel\":\"%s\",\"outputs\":%zu,\"launches\":%zu,"
                  "\"unchanged_input_bytes\":%zu,\"unchanged_guard_bytes\":%zu,\"unchanged_gap_bytes\":%zu,"
                  "\"max_absolute_error\":%.12g}",
                  i ? "," : "", r.kernel.c_str(), r.outputs, r.launches,
                  r.unchanged_input_bytes, r.unchanged_guard_bytes, r.unchanged_gap_bytes, r.maximum);
    }
    std::puts("]}");
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "unaligned GLOBAL hardware validation failed: %s\n", error.what());
    return 1;
  }
}

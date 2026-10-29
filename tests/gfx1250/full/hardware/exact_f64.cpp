// Physical IEEE binary64 checks are separate from Volta's real-valued model.
#include "original_common.hpp"

static double coefficient(uint64_t bits) {
  double value;
  static_assert(sizeof(value) == sizeof(bits));
  std::memcpy(&value, &bits, sizeof(value));
  return value;
}

int main(int argc, char **argv) {
  try {
    validate_reference_controls();
    const double a = coefficient(UINT64_C(0x3fb999999999999a));
    const double b = coefficient(UINT64_C(0x3fc999999999999a));
    const double c = coefficient(UINT64_C(0x3fd3333333333333));
    volatile double product = a * b;
    volatile double sum_a = a;
    volatile double sum_b = b;
    const double expected[] = {std::fma(a, b, c), product + c, sum_a + sum_b,
                              coefficient(UINT64_C(0x3fd3333333333334))};
    const char *kernels[] = {"exact_f64_fma", "exact_f64_mul_add", "exact_f64_runtime_sum",
                             "exact_f64_prerounded_literal"};
    require(expected[2] == expected[3], "physical IEEE sum control");
    if (argc == 2 && std::string(argv[1]) == "--cpu-only") return 0;
    require(argc == 3 && std::string(argv[2]) == "1", "requires exact code object and one pattern");
    hipDeviceProp_t device{};
    hip_check(hipGetDeviceProperties(&device, 0), "get actual device");
    const std::string architecture = device.gcnArchName;
    require(architecture.substr(0, architecture.find(':')) == "gfx1250" && device.warpSize == 32,
            "requires actual gfx1250 wave32");
    hipModule_t module{};
    hip_check(hipModuleLoad(&module, argv[1]), "load exact compiler module");
    std::vector<Row> rows;
    for (unsigned i = 0; i < 4; ++i) {
      Buffer out(Type::U32, 2, true);
      uint32_t words[2];
      std::memcpy(words, &expected[i], sizeof(words));
      Row row{kernels[i]};
      // U32 supplies exact raw-word comparison of the entire eight-byte F64
      // result, with no numeric tolerance or F64-to-F32 narrowing.
      run(module, row.kernel, dim3(1), {&out.pointer}, {&out}, out,
          {double(words[0]), double(words[1])}, row, 0., 0.);
      row.original_outputs += 1;
      rows.push_back(row);
    }
    hip_check(hipModuleUnload(module), "unload exact module");
    std::printf("{\"status\":\"pass\",\"architecture\":\"gfx1250\",\"wave_size\":32,"
                "\"reference_controls\":\"pass\",\"patterns\":1,\"cases\":[");
    for (size_t i = 0; i < rows.size(); ++i) {
      const auto &r = rows[i];
      std::printf("%s{\"kernel\":\"%s\",\"outputs\":%zu,\"original_outputs\":%zu,\"launches\":%zu,"
                  "\"unchanged_input_bytes\":%zu,\"unchanged_guard_bytes\":%zu,\"max_absolute_error\":%.12g}",
                  i ? "," : "", r.kernel.c_str(), r.outputs, r.original_outputs, r.launches,
                  r.unchanged_input_bytes, r.unchanged_guard_bytes, r.maximum);
    }
    std::puts("]}");
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "exact F64 physical validation failed: %s\n", error.what());
    return 1;
  }
}

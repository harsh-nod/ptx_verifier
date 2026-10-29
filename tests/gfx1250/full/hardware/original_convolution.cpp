// Independent NCHW/OIHW convolution, all K576 terms and selected CTA outputs.
#include "original_common.hpp"

static void validate(hipModule_t module, bool fp8, unsigned patterns, std::vector<Row> &rows) {
  constexpr size_t channels = 64, height = 56, width_in = 56, outputs = 128, pitch = 54 * 54;
  const size_t spatial = fp8 ? 64 : 128;
  const Type type = fp8 ? Type::E4M3 : Type::Half;
  Row row{fp8 ? "convolution_f8_original" : "convolution_f16_original"};
  Buffer x(type, channels * height * width_in), weight(type, outputs * channels * 9);
  Buffer out(Type::Half, outputs * pitch, true);
  for (unsigned pattern = 0; pattern < patterns; ++pattern) {
    x.fill(pattern, 3); weight.fill(pattern + (pattern != 0), 7);
    std::vector<double> expected(outputs * pitch, NAN);
    for (size_t oc = 0; oc < outputs; ++oc) for (size_t s = 0; s < spatial; ++s) {
      double value = 0;
      const size_t y = s / 54, x_col = s % 54;
      for (size_t ic = 0; ic < channels; ++ic)
        for (size_t fy = 0; fy < 3; ++fy) for (size_t fx = 0; fx < 3; ++fx)
          value += x.get(ic * height * width_in + (y + fy) * width_in + x_col + fx) *
                   weight.get(oc * channels * 9 + ic * 9 + fy * 3 + fx);
      expected[oc * pitch + s] = double((_Float16)value);
    }
    run(module, row.kernel, dim3(128), {&x.pointer, &weight.pointer, &out.pointer},
        {&x, &weight, &out}, out, expected, row, 0, 0);
  }
  rows.push_back(row);
}

int main(int argc, char **argv) {
  try {
    validate_reference_controls();
    if (argc == 2 && std::string(argv[1]) == "--cpu-only") {
      std::puts("PASS convolution host reference and storage controls; GPU launches=0"); return 0;
    }
    require(argc == 3, "usage: original_convolution_driver convolution.hsaco patterns");
    size_t consumed = 0;
    const std::string text = argv[2];
    const auto patterns = std::stoul(text, &consumed);
    require(consumed == text.size() && patterns >= 2 && patterns <= 16, "patterns must be2..16");
    hipDeviceProp_t device{};
    hip_check(hipGetDeviceProperties(&device, 0), "device properties");
    const std::string architecture = device.gcnArchName;
    require(architecture.substr(0, architecture.find(':')) == "gfx1250" && device.warpSize == 32, "requires actual wave32 gfx1250");
    hipModule_t module{};
    hip_check(hipModuleLoad(&module, argv[1]), "load exact original convolution assembly");
    std::vector<Row> rows;
    validate(module, false, unsigned(patterns), rows);
    validate(module, true, unsigned(patterns), rows);
    hip_check(hipModuleUnload(module), "unload convolution");
    std::printf("{\"status\":\"pass\",\"architecture\":\"gfx1250\",\"wave_size\":32,\"reference_controls\":\"pass\",\"patterns\":%lu,\"cases\":[", patterns);
    for (size_t i = 0; i < rows.size(); ++i) {
      const Row &r = rows[i];
      std::printf("%s{\"kernel\":\"%s\",\"outputs\":%zu,\"launches\":%zu,\"unchanged_input_bytes\":%zu,\"unchanged_guard_bytes\":%zu,\"unchanged_gap_bytes\":%zu,\"max_absolute_error\":%.12g}", i ? "," : "", r.kernel.c_str(), r.outputs, r.launches, r.unchanged_input_bytes, r.unchanged_guard_bytes, r.unchanged_gap_bytes, r.maximum);
    }
    std::puts("]}");
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "original convolution validation failed: %s\n", error.what()); return 1;
  }
}

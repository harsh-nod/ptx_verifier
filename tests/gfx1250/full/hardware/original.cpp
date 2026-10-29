#include "original_common.hpp"

static std::vector<Row> validate(hipModule_t f16, hipModule_t f8, unsigned patterns) {
  std::vector<Row> rows;
  for (bool fp8 : {false, true}) {
    const Type input = fp8 ? Type::E4M3 : Type::Half;
    const hipModule_t module = fp8 ? f8 : f16;
    const std::string suffix = fp8 ? "_f8" : "_f16";
    for (const std::string operation : {"relu", "sigmoid", "silu", "swiglu", "rope", "rmsnorm", "softmax", "matvec", "reduction"}) {
      Row row{operation + suffix};
      for (unsigned pattern = 0; pattern < patterns; ++pattern) {
        if (operation == "relu" || operation == "sigmoid" || operation == "silu" || operation == "swiglu") {
          const size_t n = fp8 ? (operation == "relu" || operation == "swiglu" ? 2048 : 1024)
                              : operation == "silu" ? 512 : 1024;
          const unsigned block = fp8 ? operation == "silu" ? 256 : operation == "swiglu" ? 512 : 128
                                     : operation == "sigmoid" ? 256 : 128;
          Buffer x(input, n), value(input, n), out(Type::Half, n, true);
          x.fill(pattern, 3); value.fill(pattern, 7);
          std::vector<double> expected(n);
          for (size_t i = 0; i < n; ++i) {
            const double a = x.get(i);
            double reference = operation == "relu" ? std::max(a, 0.) : 1. / (1. + std::exp(-a));
            if (operation == "silu" || operation == "swiglu") reference *= a;
            if (operation == "swiglu") reference *= value.get(i);
            expected[i] = reference;
          }
          if (operation == "swiglu") run(module, row.kernel, dim3(block), {&x.pointer, &value.pointer, &out.pointer}, {&x, &value, &out}, out, expected, row);
          else run(module, row.kernel, dim3(block), {&x.pointer, &out.pointer}, {&x, &out}, out, expected, row);
        } else if (operation == "rope") {
          Buffer x(input, 128), cosine(input, 128), sine(input, 128), out(Type::Half, 128, true);
          x.fill(pattern, 3); cosine.fill(pattern + 1, 7); sine.fill(pattern + 2, 11);
          std::vector<double> expected(128);
          for (size_t i = 0; i < 128; ++i) {
            const double a = x.get(i), partner = (i < 64 ? -1. : 1.) * x.get(i ^ 64);
            if (fp8) {
              const _Float16 left = (_Float16)((_Float16)(a * .25) * (_Float16)cosine.get(i));
              const _Float16 right = (_Float16)((_Float16)(partner * .25) * (_Float16)sine.get(i));
              expected[i] = double((_Float16)((_Float16)(left + right) * (_Float16)4));
            } else expected[i] = a * cosine.get(i) + partner * sine.get(i);
          }
          run(module, row.kernel, dim3(128), {&x.pointer, &cosine.pointer, &sine.pointer, &out.pointer}, {&x, &cosine, &sine, &out}, out, expected, row, 0, 0);
        } else if (operation == "rmsnorm") {
          Buffer x(input, 4096), weight(input, 4096), out(Type::Half, 4096, true);
          x.fill(pattern, 3); weight.fill(pattern + 1, 7);
          double square_sum = 0;
          for (size_t i = 0; i < 4096; ++i) square_sum += x.get(i) * x.get(i);
          const double scale = 1. / std::sqrt(square_sum / 4096 + double(1.e-6f));
          std::vector<double> expected(4096);
          for (size_t i = 0; i < 4096; ++i) expected[i] = x.get(i) * weight.get(i) * scale;
          run(module, row.kernel, dim3(512), {&x.pointer, &weight.pointer, &out.pointer}, {&x, &weight, &out}, out, expected, row);
        } else if (operation == "softmax") {
          Buffer x(input, 4096), out(Type::Half, 4096, true);
          x.fill(pattern, 3);
          std::vector<double> expected(4096);
          for (size_t row_index = 0; row_index < 16; ++row_index) {
            double maximum = -INFINITY, total = 0;
            for (size_t col = 0; col < 256; ++col) maximum = std::max(maximum, x.get(row_index * 256 + col));
            for (size_t col = 0; col < 256; ++col) {
              const size_t i = row_index * 256 + col;
              expected[i] = std::exp(double((_Float16)(x.get(i) - maximum)));
              total += expected[i];
            }
            for (size_t col = 0; col < 256; ++col) expected[row_index * 256 + col] /= total;
          }
          unsigned in_stride = 256, out_stride = 256, n_rows = 16, n_cols = 256;
          run(module, row.kernel, fp8 ? dim3(32, 4) : dim3(128), {&out.pointer, &x.pointer, &in_stride, &out_stride, &n_rows, &n_cols}, {&x, &out}, out, expected, row, .000002, .002);
        } else if (operation == "matvec") {
          const size_t n = fp8 ? 64 : 32;
          Buffer a(input, n * 4096), x(input, 4096), out(Type::Half, n, true);
          a.fill(pattern, 3); x.fill(pattern + 1, 7);
          std::vector<double> expected(n, 0);
          for (size_t r = 0; r < n; ++r) for (size_t k = 0; k < 4096; ++k) expected[r] += a.get(r * 4096 + k) * x.get(k);
          if (pattern > 0)
            require(std::any_of(expected.begin() + 1, expected.end(), [&](double v) { return v != expected[0]; }), "matvec reference must distinguish output rows");
          run(module, row.kernel, dim3(128), {&a.pointer, &x.pointer, &out.pointer}, {&a, &x, &out}, out, expected, row);
        } else {
          const size_t n = fp8 ? 2048 : 256;
          Buffer x(input, n), out(Type::Float, 1, true);
          x.fill(pattern, 3); out.set(0, 1.25);
          double expected = out.get(0);
          for (size_t i = 0; i < n; ++i) expected += x.get(i);
          run(module, row.kernel, dim3(fp8 ? 256 : 128), {&x.pointer, &out.pointer}, {&x, &out}, out, {expected}, row, 0, 0);
        }
      }
      rows.push_back(row);
    }
  }
  return rows;
}

int main(int argc, char **argv) {
  try {
    validate_reference_controls();
    if (argc == 2 && std::string(argv[1]) == "--cpu-only") {
      std::puts("PASS independent OCP E4M3 and zero-activation reference controls; GPU launches=0");
      return 0;
    }
    require(argc == 4, "usage: original_driver f16.hsaco f8.hsaco patterns");
    const std::string pattern_text = argv[3];
    size_t consumed = 0;
    const unsigned long count = std::stoul(pattern_text, &consumed);
    require(consumed == pattern_text.size() && count >= 1 && count <= 64, "patterns must be 1..64");
    hipDeviceProp_t device{};
    hip_check(hipGetDeviceProperties(&device, 0), "device properties");
    const std::string architecture = device.gcnArchName;
    require(architecture.substr(0, architecture.find(':')) == "gfx1250" && device.warpSize == 32, "requires actual wave32 gfx1250");
    hipModule_t f16{}, f8{};
    hip_check(hipModuleLoad(&f16, argv[1]), "load exact FP16 assembly");
    hip_check(hipModuleLoad(&f8, argv[2]), "load exact FP8 assembly");
    const auto rows = validate(f16, f8, unsigned(count));
    hip_check(hipModuleUnload(f16), "unload FP16");
    hip_check(hipModuleUnload(f8), "unload FP8");
    std::printf("{\"status\":\"pass\",\"architecture\":\"gfx1250\",\"wave_size\":32,\"reference_controls\":\"pass\",\"patterns\":%lu,\"cases\":[", count);
    for (size_t i = 0; i < rows.size(); ++i) {
      const Row &r = rows[i];
      std::printf("%s{\"kernel\":\"%s\",\"outputs\":%zu,\"launches\":%zu,\"unchanged_input_bytes\":%zu,\"unchanged_guard_bytes\":%zu,\"max_absolute_error\":%.12g}", i ? "," : "", r.kernel.c_str(), r.outputs, r.launches, r.unchanged_input_bytes, r.unchanged_guard_bytes, r.maximum);
    }
    std::puts("]}");
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "original workload hardware validation failed: %s\n", error.what());
    return 1;
  }
}

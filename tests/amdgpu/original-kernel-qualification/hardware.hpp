// Exact-assembly numerical checks for the registered full computations.
#pragma once
#include "../../gfx1250/full/hardware/original_common.hpp"

namespace original_qualification {

static void cdna3(hipModule_t module, unsigned patterns, std::vector<Row> &rows) {
  for (const std::string operation : {"relu", "silu", "rope"}) {
    const size_t n = operation == "relu" ? 1024 : operation == "silu" ? 512 : 128;
    Row row{operation + "_f16"};
    for (unsigned pattern = 0; pattern < patterns; ++pattern) {
      Buffer x(Type::Half, n), out(Type::Half, n, true);
      x.fill(pattern, 3);
      if (pattern == 9) x.basis(n - 1);
      std::vector<double> expected(n);
      if (operation == "rope") {
        Buffer cosine(Type::Half, n), sine(Type::Half, n);
        cosine.fill(pattern + 1, 7);
        sine.fill(pattern + 2, 11);
        for (size_t i = 0; i < n; ++i)
          expected[i] = x.get(i) * cosine.get(i) +
                        (i < 64 ? -1. : 1.) * x.get(i ^ 64) * sine.get(i);
        run(module, row.kernel, dim3(128),
            {&x.pointer, &cosine.pointer, &sine.pointer, &out.pointer},
            {&x, &cosine, &sine, &out}, out, expected, row, 0, 0);
      } else {
        for (size_t i = 0; i < n; ++i) {
          const double value = x.get(i);
          expected[i] = operation == "relu" ? std::max(value, 0.)
                                              : value / (1. + std::exp(-value));
        }
        run(module, row.kernel, dim3(128), {&x.pointer, &out.pointer},
            {&x, &out}, out, expected, row);
      }
    }
    rows.push_back(row);
  }
}

static void small(Buffer &buffer, unsigned pattern, unsigned salt) {
  buffer.fill(pattern, salt);
  for (size_t i = 0; i < buffer.count; ++i) buffer.set(i, buffer.get(i) / 8.);
}

static void rdna_sinkhorn(hipModule_t module, unsigned patterns, std::vector<Row> &rows) {
  Row row{"sinkhorn_original"};
  Buffer x(Type::Half, 32 * 64), y(Type::Half, 1024 * 64);
  Buffer f(Type::Float, 32), g(Type::Float, 1024), lb(Type::Float, 1024);
  Buffer out(Type::Float, 32, true);
  // Real allocations need not equal the symbolic bases. Require their high
  // words to be nonzero before any launch.
  for (const Buffer *buffer : {&x, &y, &f, &g, &lb, &out})
    require(reinterpret_cast<uintptr_t>(buffer->pointer) > 0xffffffffULL,
            "Sinkhorn physical address must exercise a nonzero high word");
  void *unused = nullptr;
  for (unsigned pattern = 0; pattern < patterns; ++pattern) {
    small(x, pattern, 3);
    small(y, pattern, 7);
    small(f, pattern, 11);
    small(g, pattern, 13);
    small(lb, pattern, 17);
    if (pattern == 4) { x.basis(31 * 64 + 63); y.basis(1023 * 64 + 63); }
    else if (pattern == 5) { x.basis(0); y.basis(0); }
    std::vector<double> expected(32), score(1024);
    for (size_t r = 0; r < 32; ++r) {
      for (size_t key = 0; key < 1024; ++key) {
        double dot = 0;
        for (size_t d = 0; d < 64; ++d)
          dot += x.get(r * 64 + d) * y.get(key * 64 + d);
        score[key] = 2 * dot + g.get(key) + lb.get(key);
      }
      const double maximum = *std::max_element(score.begin(), score.end());
      double total = 0;
      for (double value : score) total += std::exp(value - maximum);
      expected[r] = .5 * (f.get(r) - maximum - std::log(total));
    }
    run(module, row.kernel, dim3(256),
        {&x.pointer, &y.pointer, &f.pointer, &g.pointer, &unused, &lb.pointer,
         &out.pointer, &unused, &unused, &unused, &unused},
        {&x, &y, &f, &g, &lb, &out}, out, expected, row, .00002, .000002);
  }
  rows.push_back(row);
}

inline int execute(int argc, char **argv, const std::string &target) {
  try {
    require(argc == 2, "usage: qualification_driver MODULE.hsaco");
    constexpr unsigned patterns = 10; // All dense/zero/tail-basis controls are mandatory.
    require(target == "gfx942" || target == "gfx1250", "unregistered target");
    hipDeviceProp_t device{};
    hip_check(hipGetDeviceProperties(&device, 0), "device properties");
    const std::string actual = device.gcnArchName;
    require(actual.substr(0, actual.find(':')) == target &&
                device.warpSize == (target == "gfx942" ? 64 : 32),
            "matching physical target/wave size required");
    validate_reference_controls();
    validate_basis_controls();
    hipModule_t module{};
    hip_check(hipModuleLoad(&module, argv[1]), "load exact assembly");
    std::vector<Row> rows;
    if (target == "gfx942") cdna3(module, unsigned(patterns), rows);
    else rdna_sinkhorn(module, unsigned(patterns), rows);
    hip_check(hipModuleUnload(module), "unload assembly");
    std::printf("{\"status\":\"pass\",\"architecture\":\"%s\",\"wave_size\":%d,\"patterns\":%u,\"device\":%s,\"cases\":[",
                target.c_str(), device.warpSize, patterns, selected_device_identity_json().c_str());
    for (size_t i = 0; i < rows.size(); ++i) {
      const Row &row = rows[i];
      std::printf("%s{\"kernel\":\"%s\",\"outputs\":%zu,\"launches\":%zu,\"unchanged_input_bytes\":%zu,\"unchanged_guard_bytes\":%zu,\"max_absolute_error\":%.12g}",
                  i ? "," : "", row.kernel.c_str(), row.outputs, row.launches,
                  row.unchanged_input_bytes, row.unchanged_guard_bytes, row.maximum);
    }
    std::puts("]}");
    size_t launches = 0, outputs = 0, inputs = 0, guards = 0;
    for (const Row &row : rows) {
      launches += row.launches;
      outputs += row.outputs;
      inputs += row.unchanged_input_bytes;
      guards += row.unchanged_guard_bytes;
    }
    std::printf("PASS: %zu launches, %zu complete original outputs, %zu input bytes, %zu guard bytes\n",
                launches, outputs, inputs, guards);
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "original workload qualification failed: %s\n", error.what());
    return 1;
  }
}

} // namespace original_qualification

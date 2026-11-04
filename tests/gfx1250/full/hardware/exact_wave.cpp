#include "original_common.hpp"

struct Case {
  const char *kernel;
  unsigned block;
  size_t inputs, capacity;
  bool original;
};
static const Case cases[] = {
    {"exact_wave_elect", 32, 0, 32, true},
    {"exact_wave_elect_skip", 32, 0, 32, true},
    {"exact_wave_exchange", 2, 2, 2, true},
    {"exact_wave_tail_sum", 32, 16, 1, true},
    {"exact_wave_tail_reference", 1, 16, 1, true},
    {"exact_wave_divergent_leaders", 32, 0, 2, false},
    {"exact_wave_memory_exchange", 64, 64, 64, false}};

static std::vector<double> reference(size_t which, const std::vector<double> &input) {
  std::vector<double> out(cases[which].capacity, 0.);
  if (which < 2) {
    out[which] = 1000. + which;
    if (which == 1) out[0] = std::numeric_limits<double>::quiet_NaN();
  } else if (which == 2) out = {input[1], input[0]};
  else if (which < 5) {
    for (double value : input) out[0] += value;
  } else if (which == 5) out = {1, 2};
  else for (size_t i = 0; i < out.size(); ++i) out[i] = input[i ^ 32];
  return out;
}

int main(int argc, char **argv) {
  try {
    validate_reference_controls();
    require(reference(2, {3, 7}) == std::vector<double>({7, 3}), "exchange reference");
    require(reference(3, {1, -2, 4})[0] == 3, "sum reference");
    require(std::isnan(reference(1, {})[0]), "exited lane must remain unwritten");
    if (argc == 2 && std::string(argv[1]) == "--cpu-only") return 0;
    require(argc == 3 && std::string(argv[2]) == "8", "requires exact module and eight patterns");
    hipDeviceProp_t device{};
    hip_check(hipGetDeviceProperties(&device, 0), "get actual device");
    const std::string architecture = device.gcnArchName;
    require(architecture.substr(0, architecture.find(':')) == "gfx1250" && device.warpSize == 32,
            "requires actual gfx1250 wave32");
    hipModule_t module{};
    hip_check(hipModuleLoad(&module, argv[1]), "load exact compiler module");
    std::vector<Row> rows;
    for (const auto &c : cases) rows.push_back(Row{c.kernel});
    for (unsigned pattern = 0; pattern < 8; ++pattern) {
      for (size_t which = 0; which < rows.size(); ++which) {
        const auto &c = cases[which];
        auto &row = rows[which];
        // A dummy allocation is omitted from launch and accounting when unused.
        Buffer input(Type::Float, c.inputs);
        std::vector<double> values;
        for (size_t i = 0; i < c.inputs; ++i) {
          const double value = pattern == 0 ? 0. : (int((i * 7 + pattern * 3) % 33) - 16) * .125;
          input.set(i, value);
          values.push_back(input.get(i));
        }
        Buffer out(Type::Float, c.capacity, true);
        const auto expected = reference(which, values);
        size_t written = 0;
        for (size_t i = 0; i < out.count; ++i) {
          if (std::isnan(expected[i])) continue;
          const float value = float(expected[i]);
          uint32_t poison;
          std::memcpy(&poison, &value, sizeof(poison));
          poison ^= UINT32_MAX;
          std::memcpy(out.before.data() + Buffer::guard + 4 * i, &poison, sizeof(poison));
          ++written;
        }
        if (c.inputs) run(module, c.kernel, dim3(c.block), {&input.pointer, &out.pointer},
                          {&input, &out}, out, expected, row, 0, 0);
        else run(module, c.kernel, dim3(c.block), {&out.pointer}, {&out}, out, expected, row, 0, 0);
        if (c.original) row.original_outputs += written;
      }
    }
    hip_check(hipModuleUnload(module), "unload exact module");
    std::printf("{\"status\":\"pass\",\"architecture\":\"gfx1250\",\"wave_size\":32,"
                "\"reference_controls\":\"pass\",\"patterns\":8,\"cases\":[");
    for (size_t i = 0; i < rows.size(); ++i) {
      const auto &r = rows[i];
      std::printf("%s{\"kernel\":\"%s\",\"outputs\":%zu,\"original_outputs\":%zu,\"launches\":%zu,"
                  "\"unchanged_input_bytes\":%zu,\"unchanged_guard_bytes\":%zu,\"unchanged_gap_bytes\":%zu,"
                  "\"max_absolute_error\":%.12g}",
                  i ? "," : "", r.kernel.c_str(), r.outputs, r.original_outputs, r.launches,
                  r.unchanged_input_bytes, r.unchanged_guard_bytes, r.unchanged_gap_bytes, r.maximum);
    }
    std::puts("]}");
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "exact wave hardware validation failed: %s\n", error.what());
    return 1;
  }
}

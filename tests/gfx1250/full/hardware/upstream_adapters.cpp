// Independent inverse-fragment BF16 oracle and exact integer division oracle.
#include "original_common.hpp"

static double bfloat(const Buffer &buffer, size_t index) {
  uint16_t encoded;
  std::memcpy(&encoded, buffer.before.data() + Buffer::guard + 2 * index, 2);
  uint32_t word = uint32_t(encoded) << 16;
  float decoded;
  std::memcpy(&decoded, &word, 4);
  return decoded;
}

static void set_bfloat(Buffer &buffer, size_t index, double value) {
  float narrowed = float(value);
  uint32_t word;
  std::memcpy(&word, &narrowed, 4);
  require((word & 65535) == 0, "probe input must be exactly representable as BF16");
  uint16_t encoded = uint16_t(word >> 16);
  std::memcpy(buffer.before.data() + Buffer::guard + 2 * index, &encoded, 2);
}

static uint32_t division(uint64_t a, uint64_t b) {
  const unsigned __int128 product = static_cast<unsigned __int128>(a) * b;
  return uint32_t(uint64_t(product >> 64) >> 1);
}

static std::pair<uint64_t, uint64_t> division_inputs(unsigned pattern) {
  static const uint64_t dividends[] = {10, 0, 1, 2, 3, 9, 11, UINT32_MAX, UINT64_C(0x100000000),
      UINT64_C(0x100000001), UINT64_C(0x7fffffffffffffff), UINT64_C(0x8000000000000000),
      UINT64_C(0x8000000000000001), UINT64_MAX - 2, UINT64_MAX - 1, UINT64_MAX, 17};
  return {dividends[pattern % 17], pattern < 17 ? UINT64_C(0xaaaaaaaaaaaaaaab) : UINT64_MAX};
}

static void prepare_division_output(Buffer &out, uint32_t expected) {
  // An all-ones allocation sentinel is a valid U32 result for some inputs.
  // Complementing this pattern's reference makes every missing write visible.
  out.set(0, expected ^ UINT32_MAX);
}

static void division_output_controls() {
  Buffer out(Type::U32, 1, true, true);
  for (unsigned pattern = 0; pattern < 34; ++pattern) {
    const auto [a, b] = division_inputs(pattern);
    const uint32_t expected = division(a, b);
    prepare_division_output(out, expected);
    require(out.get(0) != double(expected), "unwritten U32 output aliases its reference");
    out.after = out.before;
    Row row;
    bool rejected = false;
    try { compare("unwritten division output", out, {double(expected)}, row, 0, 0); }
    catch (const std::runtime_error &) { rejected = true; }
    require(rejected && row.outputs == 0, "division checker accepted an unwritten output");
    std::memcpy(out.after.data() + Buffer::guard, &expected, sizeof(expected));
    compare("written division output", out, {double(expected)}, row, 0, 0);
    require(row.outputs == 1, "division checker missed a written U32 output");
  }
}

static void controls() {
  validate_reference_controls();
  require(division(10, UINT64_C(0xaaaaaaaaaaaaaaab)) == 3, "original division golden");
  require(division(UINT64_MAX, UINT64_MAX) == UINT32_MAX, "high-product/truncation golden");
  division_output_controls();
}

static Row matrix(hipModule_t module, unsigned patterns) {
  Row row{"bf16_m16n8k16_fragment_adapter"};
  // Half supplies guarded two-byte backing only. Encode/decode BF16 explicitly;
  // never interpret these input words using Buffer's F16 numerical conversion.
  Buffer a(Type::Half, 256), b(Type::Half, 128);
  Buffer full(Type::Float, 256, true), projection(Type::Float, 4, true);
  for (unsigned pattern = 0; pattern < patterns; ++pattern) {
    for (unsigned lane = 0; lane < 32; ++lane) {
      for (unsigned component = 0; component < 8; ++component) {
        const unsigned r = lane / 4 + (component % 4) / 2 * 8;
        const unsigned k = lane % 4 * 2 + component / 4 * 8 + component % 2;
        double value = (int((r * 7 + k * 11 + pattern * 3) % 33) - 16) / 16.;
        if (!pattern) value = 0;
        if (pattern >= 2 && pattern < 18) value = k == pattern - 2 ? (r + 1) / 16. : 0.;
        set_bfloat(a, lane * 8 + component, value);
      }
      for (unsigned component = 0; component < 4; ++component) {
        const unsigned c = lane / 4;
        const unsigned k = lane % 4 * 2 + component / 2 * 8 + component % 2;
        double value = (int((k * 5 + c * 13 + pattern * 7) % 31) - 15) / 16.;
        if (!pattern) value = 0;
        if (pattern >= 18) value = k == pattern - 18 ? (c + 1) / 8. : 0.;
        set_bfloat(b, lane * 4 + component, value);
      }
    }
    // Reconstruct by the baseline lane/component ownership, independently of
    // the native source's row/k -> storage-index helpers.
    double left[16][16]{}, right[16][8]{};
    for (unsigned lane = 0; lane < 32; ++lane) {
      for (unsigned j = 0; j < 8; ++j)
        left[lane / 4 + (j % 4) / 2 * 8][lane % 4 * 2 + j / 4 * 8 + j % 2] = bfloat(a, lane * 8 + j);
      for (unsigned j = 0; j < 4; ++j)
        right[lane % 4 * 2 + j / 2 * 8 + j % 2][lane / 4] = bfloat(b, lane * 4 + j);
    }
    std::vector<double> expected(256, 0);
    for (unsigned r = 0; r < 16; ++r)
      for (unsigned c = 0; c < 8; ++c)
        for (unsigned k = 0; k < 16; ++k)
          expected[r * 16 + c] += left[r][k] * right[k][c];
    const std::vector<double> original{expected[0], expected[1], expected[128], expected[129]};
    launch(module, row.kernel, dim3(32), {&a.pointer, &b.pointer, &full.pointer, &projection.pointer},
           {&a, &b, &full, &projection}, row);
    compare(row.kernel + ".native_full", full, expected, row, 0., 0.);
    compare(row.kernel + ".original_four", projection, original, row, 0., 0.);
    row.original_outputs += 4;
  }
  return row;
}

static Row high64(hipModule_t module, unsigned patterns) {
  Row row{"high64_division_projection"};
  Buffer out(Type::U32, 1, true);
  for (unsigned pattern = 0; pattern < patterns; ++pattern) {
    auto [a, b] = division_inputs(pattern);
    const uint32_t expected = division(a, b);
    prepare_division_output(out, expected);
    run(module, row.kernel, dim3(1), {&a, &b, &out.pointer}, {&out},
        out, {double(expected)}, row, 0., 0.);
    row.original_outputs += 1;
  }
  return row;
}

int main(int argc, char **argv) {
  try {
    controls();
    if (argc == 2 && std::string(argv[1]) == "--cpu-only") return 0;
    require(argc == 3 && std::string(argv[2]) == "34", "requires code object and all34 patterns");
    hipDeviceProp_t device{};
    hip_check(hipGetDeviceProperties(&device, 0), "get actual device");
    const std::string architecture = device.gcnArchName;
    require(architecture.substr(0, architecture.find(':')) == "gfx1250" && device.warpSize == 32,
            "requires actual gfx1250 wave32");
    hipModule_t module{};
    hip_check(hipModuleLoad(&module, argv[1]), "load exact module");
    const std::vector<Row> rows{matrix(module, 34), high64(module, 34)};
    hip_check(hipModuleUnload(module), "unload module");
    std::printf("{\"status\":\"pass\",\"architecture\":\"gfx1250\",\"wave_size\":32,"
                "\"reference_controls\":\"pass\",\"patterns\":34,\"cases\":[");
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
    std::fprintf(stderr, "upstream adapter validation failed: %s\n", error.what());
    return 1;
  }
}

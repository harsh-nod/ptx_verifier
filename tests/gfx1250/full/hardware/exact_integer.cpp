// Physical fixed-width counterparts; references use unsigned host arithmetic.
#include "original_common.hpp"

static const uint32_t inputs[] = {
    0, 1, 2, 0x7fffffff, 0x80000000, 0xfffffffe, 0xffffffff, 0x12345678};

struct Case {
  const char *kernel;
  const char *kind;
  size_t capacity;
  std::vector<double> expected;
};

static std::vector<Case> cases(uint32_t value, uint8_t byte) {
  const double gap = std::numeric_limits<double>::quiet_NaN();
  return {
      {"exact_b16_shift_count_u32", "io", 3, {0, 0, 65535}},
      // Compare both words of each of the two original U64 outputs.
      {"exact_b64_shift_u32", "io", 4, {0, 768, 3, 0}},
      {"exact_bfe_clipping", "out", 4, {10, 4294967290., 4294967295., 0}},
      {"exact_bfi_clipping", "out", 4, {48, 5, 5, 7}},
      {"exact_declined_cancel_one_pass", "tile", 64, {}},
      {"exact_int_abs_signed_width", "io", 2, {5, 2147483648.}},
      {"exact_load_s8_sign_extends", "scratch-write", 2, {4294967295., gap}},
      {"exact_load_s8_direct_minus_one", "scratch-read", 2, {4294967295., gap}},
      {"exact_mov_minus_one", "out", 1, {4294967295.}},
      {"exact_not_zero", "out", 1, {4294967295.}},
      {"exact_mul_high_u32", "io", 1, {1}},
      {"exact_mul_wide_u16", "io", 2, {1, 3}},
      {"exact_ring_add_s32_neg1", "io", 1, {double(value - uint32_t(1))}},
      {"exact_ring_add_u32_neg1", "io", 1, {double(value - uint32_t(1))}},
      {"exact_ring_sub_s32_neg7", "io", 1, {double(value + uint32_t(7))}},
      {"exact_ring_sub_u32_neg7", "io", 1, {double(value + uint32_t(7))}},
      {"exact_ring_sub_u32_1", "io", 1, {double(value - uint32_t(1))}},
      {"exact_ring_mul_s32_neg3", "io", 1, {double(value * uint32_t(-3))}},
      {"exact_ring_mul_u32_neg3", "io", 1, {double(value * uint32_t(-3))}},
      {"exact_select_minus_one", "io", 1, {double(value == UINT32_MAX ? UINT32_MAX : 0)}},
      {"exact_select_complement", "io", 1, {double(value == UINT32_MAX ? UINT32_MAX : 0)}},
      {"exact_funnel_clamp_wrap", "io", 4, {286331153., 572662306., 143165576., 1145324612.}},
      {"exact_store_u8_truncates", "scratch-write", 2, {44, gap}},
      {"exact_unsigned_byte_identity", "scratch-read", 2, {double(byte), gap}},
      {"exact_vector_immediates", "float", 4, {}}};
}

static uint32_t poison_word(double expected, bool floating) {
  uint32_t bits;
  if (floating) {
    const float f = float(expected);
    std::memcpy(&bits, &f, sizeof(bits));
  } else {
    bits = uint32_t(expected);
  }
  return bits ^ UINT32_MAX;
}

int main(int argc, char **argv) {
  try {
    validate_reference_controls();
    require(uint32_t(0) - uint32_t(1) == UINT32_MAX, "wrapping subtract reference");
    require(uint32_t(0x80000000) * uint32_t(-3) == uint32_t(0x80000000),
            "signed-width bit pattern reference");
    require(poison_word(4294967295., false) != UINT32_MAX, "poison differs from expected");
    require(cases(0, 0).size() == 25, "all25 fixed-width cases required");
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
    for (unsigned pattern = 0; pattern < 8; ++pattern) {
      const auto list = cases(inputs[pattern], uint8_t(inputs[pattern]));
      if (rows.empty()) for (const auto &c : list) rows.push_back(Row{c.kernel});
      for (size_t index = 0; index < list.size(); ++index) {
        auto c = list[index];
        auto &row = rows[index];
        const std::string kind = c.kind;
        const bool floating = kind == "tile" || kind == "float";
        const bool scratch = kind.find("scratch-") == 0;
        Buffer input(scratch ? Type::I8 : floating ? Type::Float : Type::U32,
                     scratch ? 8 : c.capacity, kind == "scratch-write");
        for (size_t i = 0; i < input.count; ++i) {
          // Powers of two keep host/reference F32 arithmetic exact.
          const double value = floating ? (int(i % 17) - 8) * .125 + pattern * .25
                                       : scratch ? int(uint8_t(inputs[pattern] + uint32_t(i)))
                                                 : double(inputs[pattern]);
          input.set(i, scratch ? int8_t(uint8_t(value)) : value);
        }
        Buffer out(floating ? Type::Float : Type::U32, c.capacity, true);
        if (kind == "tile") {
          for (size_t i = 0; i < input.count; ++i) c.expected.push_back(input.get(i) * 2);
        } else if (kind == "float") {
          c.expected = {input.get(0), 0, input.get(1), 1};
        }
        require(c.expected.size() == out.count, "complete output reference");
        size_t written = 0;
        for (size_t i = 0; i < out.count; ++i) {
          if (std::isnan(c.expected[i])) continue;
          const auto poison = poison_word(c.expected[i], floating);
          std::memcpy(out.before.data() + Buffer::guard + i * 4, &poison, sizeof(poison));
          ++written;
        }
        if (kind == "out") {
          run(module, c.kernel, dim3(1), {&out.pointer}, {&out}, out, c.expected, row, 0, 0);
        } else {
          run(module, c.kernel, dim3(kind == "tile" ? 64 : 1),
              {&input.pointer, &out.pointer}, {&input, &out}, out, c.expected, row, 0, 0);
        }
        if (kind == "scratch-write") {
          const uint8_t expected = std::string(c.kernel) == "exact_store_u8_truncates" ? 44 : 255;
          require(input.after[Buffer::guard] == expected, "exact intended scratch-byte write");
          for (size_t i = 1; i < input.count; ++i)
            require(input.after[Buffer::guard+i] == input.before[Buffer::guard+i],
                    "scratch neighbour byte modified");
        }
        row.original_outputs += std::string(c.kernel) == "exact_b64_shift_u32" ? 2 : written;
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
    std::fprintf(stderr, "exact integer hardware validation failed: %s\n", error.what());
    return 1;
  }
}

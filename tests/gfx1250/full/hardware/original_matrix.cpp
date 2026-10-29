// Complete selected-CTA matrix outputs at original K4096 and physical pitches.
// CPU loops never use WMMA lane layouts or verifier expression helpers.
#include "original_common.hpp"

static uint32_t mix(uint32_t value) {
  value ^= value >> 16;
  value *= 0x7feb352dU;
  value ^= value >> 15;
  value *= 0x846ca68bU;
  return value ^ (value >> 16);
}
static int coordinate(unsigned row, unsigned col, unsigned pattern, uint32_t domain) {
  if (pattern == 0) return 0;
  const uint32_t key = domain ^ (row + 1) * 0x9e3779b9U ^ (col + 3) * 0x85ebca6bU ^
                       (row + 7) * (col + 11) ^ (pattern + 1) * 0xc2b2ae35U;
  return int(mix(key) % 15) - 7;
}
static void encode(Buffer &buffer, size_t index, int numerator) {
  if (buffer.type != Type::E4M3) { buffer.set(index, numerator / 16.); return; }
  static const std::vector<uint8_t> codes = [] {
    std::vector<uint8_t> result;
    for (int n = -7; n <= 7; ++n) {
      unsigned bits = 0;
      while (bits < 256 && decode_e4m3(uint8_t(bits)) != n / 16.) ++bits;
      require(bits < 256, "matrix input pattern is not exactly E4M3 encodable");
      result.push_back(uint8_t(bits));
    }
    return result;
  }();
  buffer.before[Buffer::guard + index] = codes.at(size_t(numerator + 7));
}

static void gemm(hipModule_t module, bool fp8, unsigned patterns, std::vector<Row> &rows) {
  constexpr size_t M = 256, N = 256, K = 4096, pitch = 4096;
  const std::string suffix = fp8 ? "f8_full" : "f16_full";
  Row plain{"gemm_" + suffix}, fused{"gemm_add_silu_" + suffix};
  const Type input = fp8 ? Type::E4M3 : Type::Half;
  Buffer a(input, M * K), b(input, K * pitch), add(input, M * pitch), out(Type::Half, M * pitch, true);
  std::vector<double> a_values(M * K), b_values(K * N), dots(M * N);
  for (unsigned pattern = 0; pattern < patterns; ++pattern) {
    for (size_t r = 0; r < M; ++r) for (size_t k = 0; k < K; ++k) {
      const size_t i = r * K + k;
      encode(a, i, coordinate(unsigned(r), unsigned(k), pattern, 0x41d2c3b4U));
      a_values[i] = a.get(i);
    }
    for (size_t k = 0; k < K; ++k) for (size_t col = 0; col < pitch; ++col) {
      const size_t i = k * pitch + col;
      encode(b, i, coordinate(unsigned(k), unsigned(col), pattern, 0xb8632791U));
      if (col < N) b_values[k * N + col] = b.get(i);
    }
    for (size_t r = 0; r < M; ++r) for (size_t col = 0; col < pitch; ++col)
      encode(add, r * pitch + col, coordinate(unsigned(r), unsigned(col), pattern, 0x93a71e05U));
    std::fill(dots.begin(), dots.end(), 0.);
    // All K4096 products are dyadic; even their worst-case numerator sum is
    // below2^18, so FP32 accumulation is exact for this input distribution.
    for (size_t r = 0; r < M; ++r) for (size_t k = 0; k < K; ++k) {
      const double left = a_values[r * K + k];
      for (size_t col = 0; col < N; ++col) dots[r * N + col] += left * b_values[k * N + col];
    }
    std::vector<double> expected(M * pitch, NAN), fused_expected(M * pitch, NAN);
    for (size_t r = 0; r < M; ++r) for (size_t col = 0; col < N; ++col) {
      const size_t physical = r * pitch + col;
      expected[physical] = double((_Float16)dots[r * N + col]);
      const double value = dots[r * N + col] + add.get(physical);
      fused_expected[physical] = double((_Float16)(value / (1. + std::exp(-value))));
    }
    run(module, plain.kernel, dim3(1024), {&a.pointer, &b.pointer, &out.pointer}, {&a, &b, &out}, out, expected, plain, 0, 0);
    run(module, fused.kernel, dim3(1024), {&a.pointer, &b.pointer, &add.pointer, &out.pointer}, {&a, &b, &add, &out}, out, fused_expected, fused, .000001, .002);
  }
  rows.push_back(plain); rows.push_back(fused);
}

static void bitdelta(hipModule_t module, bool batched, unsigned patterns, std::vector<Row> &rows) {
  constexpr size_t K = 4096, pitch = 4096;
  const size_t M = batched ? 128 : 64, N = batched ? 256 : 128;
  Row row{batched ? "bitdelta_batched_full" : "bitdelta_full"};
  Buffer a(Type::Half, M * K), packed(Type::U32, 128 * pitch), out(Type::Half, M * pitch, true);
  std::vector<double> a_values(M * K);
  std::vector<uint32_t> words(128 * N);
  for (unsigned pattern = 0; pattern < patterns; ++pattern) {
    for (size_t r = 0; r < M; ++r) for (size_t k = 0; k < K; ++k) {
      const size_t i = r * K + k;
      a.set(i, coordinate(unsigned(r), unsigned(k), pattern, 0x57d108afU) / 16.);
      a_values[i] = a.get(i);
    }
    for (size_t group = 0; group < 128; ++group) for (size_t col = 0; col < pitch; ++col) {
      const uint32_t word = pattern == 0 || pattern == 2 ? 0 : pattern == 1 ? UINT32_MAX
          : mix(uint32_t(group + 1) * 0x9e3779b9U ^ uint32_t(col + 3) * 0x85ebca6bU ^ pattern * 0xc2b2ae35U);
      packed.set(group * pitch + col, word);
      if (col < N) words[group * N + col] = word;
    }
    std::vector<double> expected(M * pitch, NAN);
    for (size_t r = 0; r < M; ++r) for (size_t col = 0; col < N; ++col) expected[r * pitch + col] = 0;
    for (size_t r = 0; r < M; ++r) for (size_t k = 0; k < K; ++k) {
      const double left = a_values[r * K + k];
      for (size_t col = 0; col < N; ++col)
        expected[r * pitch + col] += left * ((words[(k / 32) * N + col] >> (k % 32)) & 1 ? 1. : -1.);
    }
    for (size_t r = 0; r < M; ++r) for (size_t col = 0; col < N; ++col)
      expected[r * pitch + col] = double((_Float16)expected[r * pitch + col]);
    run(module, row.kernel, dim3(256), {&a.pointer, &packed.pointer, &out.pointer}, {&a, &packed, &out}, out, expected, row, 0, 0);
  }
  rows.push_back(row);
}

int main(int argc, char **argv) {
  try {
    validate_reference_controls();
    if (argc == 2 && std::string(argv[1]) == "--cpu-only") {
      std::puts("PASS matrix host reference and storage controls; GPU launches=0"); return 0;
    }
    require(argc == 3, "usage: original_matrix_driver matrix.hsaco patterns");
    size_t consumed = 0;
    const std::string text = argv[2];
    const auto patterns = std::stoul(text, &consumed);
    require(consumed == text.size() && patterns >= 4 && patterns <= 16, "matrix patterns must be4..16");
    hipDeviceProp_t device{};
    hip_check(hipGetDeviceProperties(&device, 0), "device properties");
    const std::string architecture = device.gcnArchName;
    require(architecture.substr(0, architecture.find(':')) == "gfx1250" && device.warpSize == 32, "requires actual wave32 gfx1250");
    hipModule_t module{};
    hip_check(hipModuleLoad(&module, argv[1]), "load exact original matrix assembly");
    std::vector<Row> rows;
    gemm(module, false, unsigned(patterns), rows);
    gemm(module, true, unsigned(patterns), rows);
    bitdelta(module, false, unsigned(patterns), rows);
    bitdelta(module, true, unsigned(patterns), rows);
    hip_check(hipModuleUnload(module), "unload matrix module");
    std::printf("{\"status\":\"pass\",\"architecture\":\"gfx1250\",\"wave_size\":32,\"reference_controls\":\"pass\",\"patterns\":%lu,\"cases\":[", patterns);
    for (size_t i = 0; i < rows.size(); ++i) {
      const Row &r = rows[i];
      std::printf("%s{\"kernel\":\"%s\",\"outputs\":%zu,\"launches\":%zu,\"unchanged_input_bytes\":%zu,\"unchanged_guard_bytes\":%zu,\"unchanged_gap_bytes\":%zu,\"max_absolute_error\":%.12g}", i ? "," : "", r.kernel.c_str(), r.outputs, r.launches, r.unchanged_input_bytes, r.unchanged_guard_bytes, r.unchanged_gap_bytes, r.maximum);
    }
    std::puts("]}");
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "original matrix validation failed: %s\n", error.what()); return 1;
  }
}

// Host-only validation of the exact 20 portable-matrix assembly code objects.
// Build each unmodified .s using llvm-mc -triple=amdgcn-amd-amdhsa -mcpu=gfx950
// -filetype=obj, then ld.lld -shared object.o -o NAME.hsaco. No GPU C++ kernels.
// Build this host with clang++ -std=c++17 -D__HIP_PLATFORM_AMD__
// -I/opt/rocm/include THIS.cpp -L/opt/rocm/lib -Wl,-rpath,/opt/rocm/lib
// -lamdhip64 -o runner; invoke runner DIRECTORY_CONTAINING_HSACO_FILES.
// References use ordinary logical coordinates and dense row-major products;
// they do not call the verifier, its matrix mapper, or any symbolic oracle.
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

static constexpr size_t guard = 256;
static constexpr uint8_t sentinel = 0xa5;

static void check(hipError_t error, const char *operation) {
  if (error != hipSuccess) {
    std::fprintf(stderr, "%s: %s\n", operation, hipGetErrorString(error));
    std::exit(1);
  }
}

struct Buffer {
  std::vector<uint8_t> host;
  uint8_t *device{};
  explicit Buffer(size_t bytes) : host(bytes, sentinel) {
    check(hipMalloc(reinterpret_cast<void **>(&device), bytes), "allocate");
  }
  Buffer(const Buffer &) = delete;
  Buffer &operator=(const Buffer &) = delete;
  ~Buffer() { (void)hipFree(device); }
  void upload() {
    check(hipMemcpy(device, host.data(), host.size(), hipMemcpyHostToDevice), "upload");
  }
  void download() {
    check(hipMemcpy(host.data(), device, host.size(), hipMemcpyDeviceToHost), "download");
  }
};

enum class Ref {
  Transpose, FourTiles, LaneWords, Weighted, Ones, IdentityC,
  Numeric136, Raw17, Zero, Mixed408, Mixed476, Pair, PairRelu,
  Bytes4, Bytes02, Byte0
};
struct Case {
  const char *name;
  Ref reference;
  unsigned block, input_width, input_len, output_width, output_len;
  bool fragment = false;
};
// Launch and storage sizes are the public assembly ABI, also recorded in
// portable-matrix/cases.json. Every case in that manifest is listed here.
static const Case cases[] = {
  {"ldmatrix_transpose_8x8", Ref::Transpose, 32, 2, 64, 2, 64},
  {"ldmatrix_four_fragment_pairs", Ref::FourTiles, 32, 2, 256, 2, 256},
  {"stmatrix_lane_word_placement", Ref::LaneWords, 32, 2, 256, 4, 33},
  {"wmma_fragment_contiguous", Ref::Weighted, 64, 2, 256, 4, 256, true},
  {"wmma_fragment_stride48", Ref::Weighted, 64, 2, 256, 4, 256, true},
  {"wmma_fragment_stride64", Ref::Weighted, 64, 2, 256, 4, 256, true},
  {"wmma_store_tile_ones", Ref::Ones, 64, 2, 256, 4, 256},
  {"mma_raw_accumulator_identity", Ref::IdentityC, 64, 2, 256, 4, 128},
  {"mma_immediate_accumulator_identity", Ref::IdentityC, 64, 2, 256, 4, 128},
  {"tcgen_numeric136", Ref::Numeric136, 512, 2, 256, 4, 1024},
  {"tcgen_raw_operands_accumulator17", Ref::Raw17, 512, 2, 256, 4, 1024},
  {"tcgen_no_swizzle_128x8", Ref::Zero, 512, 2, 256, 4, 1024},
  {"tcgen_mixed_fp8_numeric408", Ref::Mixed408, 512, 2, 256, 4, 1024},
  {"tcgen_mixed_fp8_wrong_b_format", Ref::Mixed476, 512, 2, 256, 4, 1024},
  {"e4m3_concrete_pair", Ref::Pair, 1, 1, 1, 4, 2},
  {"e4m3_concrete_pair_relu", Ref::PairRelu, 1, 1, 1, 4, 2},
  {"e4m3_vector_bytes", Ref::Bytes4, 1, 1, 8, 4, 4},
  {"e4m3_selected_low_halves", Ref::Bytes02, 1, 1, 4, 4, 2},
  {"e4m3_zero_extended_byte", Ref::Byte0, 1, 1, 1, 4, 1},
  {"tcgen_shape128x256_lds_bounds", Ref::Zero, 1024, 2, 256, 4, 32768},
};

template<class T> static T read(const std::vector<uint8_t> &bytes, size_t offset) {
  T value;
  std::memcpy(&value, bytes.data() + offset, sizeof(value));
  return value;
}
template<class T> static void write(std::vector<uint8_t> &bytes, size_t offset, T value) {
  std::memcpy(bytes.data() + offset, &value, sizeof(value));
}

// IEEE-style OCP E4M3: exponent bias 7, gradual underflow, finite exponent 15
// except fraction 7. E5M2 uses bias 15 and reserves exponent 31 for Inf/NaN.
static double fp8(uint8_t bits, bool e5m2) {
  const unsigned fraction_bits = e5m2 ? 2 : 3;
  const unsigned fraction_mask = (1u << fraction_bits) - 1;
  const unsigned exponent = (bits & 0x7f) >> fraction_bits;
  const unsigned fraction = bits & fraction_mask;
  if ((e5m2 && exponent == 31) || (!e5m2 && exponent == 15 && fraction == 7)) {
    std::fprintf(stderr, "nonfinite FP8 reference input\n");
    std::exit(1);
  }
  const int bias = e5m2 ? 15 : 7;
  double value = exponent == 0
      ? std::ldexp(static_cast<double>(fraction), 1 - bias - int(fraction_bits))
      : std::ldexp(1.0 + double(fraction) / (1u << fraction_bits), int(exponent) - bias);
  return bits & 0x80 ? -value : value;
}
static uint8_t encode_fp8(double value) {
  for (unsigned bits = 0; bits < 256; ++bits) {
    if ((bits & 0x7f) == 0x7f) continue;
    if (fp8(static_cast<uint8_t>(bits), false) == value) return static_cast<uint8_t>(bits);
  }
  std::fprintf(stderr, "unrepresentable finite input %.17g\n", value);
  std::exit(1);
}

static std::vector<double> initialize_input(const Case &test, unsigned pattern, Buffer &input) {
  std::vector<double> logical(test.input_len);
  for (unsigned i = 0; i < test.input_len; ++i) {
    const unsigned row = i / 16, column = i % 16;
    // Three distinct coordinate-dependent bounded dyadics, exactly represented
    // by F16 and E4M3 and exactly accumulated by these small F32 dot products.
    const int code = pattern == 0 ? int((7 * row + 3 * column + 1) % 17) - 8
                   : pattern == 1 ? int((5 * row + 11 * column + 4) % 29) - 14
                                  : int((13 * row + 7 * column + 9) % 31) - 15;
    const double value = code * 0.25;
    if (test.input_width == 2) {
      const _Float16 encoded = static_cast<_Float16>(value);
      write(input.host, guard + 2 * i, encoded);
      logical[i] = static_cast<double>(encoded);
    } else {
      const uint8_t encoded = encode_fp8(value);
      input.host[guard + i] = encoded;
      logical[i] = fp8(encoded, false);
    }
  }
  return logical;
}

static std::vector<double> reference(const Case &test, const std::vector<double> &x) {
  std::vector<double> expected(test.output_len, 0);
  switch (test.reference) {
  case Ref::Transpose:
    for (unsigned row = 0; row < 8; ++row)
      for (unsigned col = 0; col < 8; ++col) expected[row * 8 + col] = x[col * 8 + row];
    break;
  case Ref::FourTiles:
    for (unsigned row = 0; row < 8; ++row)
      for (unsigned col_pair = 0; col_pair < 4; ++col_pair)
        for (unsigned tile = 0; tile < 4; ++tile)
          for (unsigned part = 0; part < 2; ++part)
            expected[(row * 4 + col_pair) * 8 + tile * 2 + part] =
                x[tile * 64 + row * 8 + col_pair * 2 + part];
    break;
  case Ref::LaneWords:
    expected[0] = 1005;
    for (unsigned i = 1; i < expected.size(); ++i) expected[i] = 999 + i;
    break;
  case Ref::Weighted:
    for (unsigned row = 0; row < 16; ++row)
      for (unsigned col = 0; col < 16; ++col)
        for (unsigned k = 0; k < 16; ++k) expected[row * 16 + col] += x[row * 16 + k] * (k + 1);
    break;
  case Ref::Ones: std::fill(expected.begin(), expected.end(), 1.0); break;
  case Ref::IdentityC:
    for (unsigned i = 0; i < expected.size(); ++i) expected[i] = i % 4 == 0 ? 1.0 : 0.0;
    break;
  case Ref::Numeric136:
  case Ref::Raw17:
  case Ref::Mixed408:
  case Ref::Mixed476: {
    const bool mixed = test.reference == Ref::Mixed408 || test.reference == Ref::Mixed476;
    const unsigned depth = mixed ? 32 : 16;
    const bool raw = test.reference == Ref::Raw17;
    // Original logical shapes M128,N8,K16/32, with internal native padding
    // excluded from the mathematical product. No MFMA lane coordinates here.
    for (unsigned row = 0; row < 128; ++row)
      for (unsigned col = 0; col < 8; ++col) {
        double sum = raw ? 1.0 : 0.0;
        for (unsigned k = 0; k < depth; ++k) {
          const double a = row == 0 ? (raw ? 1.0 : double(k % 16 + 1)) : 0.0;
          double b = col == 0 ? 1.0 : 0.0;
          if (mixed && col == 0) {
            const uint8_t stored_b = k < 16 ? 0x3c : 0x40; // E5M2 1/2.
            b = fp8(stored_b, test.reference == Ref::Mixed408);
          }
          sum += a * b;
        }
        expected[row * 8 + col] = sum;
      }
    break;
  }
  case Ref::Zero: break;
  case Ref::Pair: expected = {1.0, -1.0}; break;
  case Ref::PairRelu: expected = {1.0, 0.0}; break;
  case Ref::Bytes4:
  case Ref::Byte0:
    for (unsigned i = 0; i < expected.size(); ++i) expected[i] = x[i];
    break;
  case Ref::Bytes02:
    for (unsigned i = 0; i < expected.size(); ++i) expected[i] = x[2 * i];
    break;
  }
  return expected;
}

static void equal(const Case &test, unsigned pattern, const char *array,
                  size_t index, double expected, double actual) {
  if (!std::isfinite(actual) || actual != expected) {
    std::fprintf(stderr, "%s pattern=%u %s[%zu] expected=%.17g actual=%.17g atol=0 rtol=0\n",
                 test.name, pattern, array, index, expected, actual);
    std::exit(1);
  }
}

int main(int argc, char **argv) {
  if (argc != 2) {
    std::fprintf(stderr, "usage: %s DIRECTORY_CONTAINING_EXACT_HSACO_FILES\n", argv[0]);
    return 2;
  }
  hipDeviceProp_t device{};
  check(hipGetDeviceProperties(&device, 0), "device properties");
  const std::string architecture(device.gcnArchName);
  if (architecture.substr(0, architecture.find(':')) != "gfx950") {
    std::fprintf(stderr, "requires gfx950\n");
    return 2;
  }
  size_t total_outputs = 0, total_guard_bytes = 0, total_input_bytes = 0;
  for (const Case &test : cases) {
    const std::string path = std::string(argv[1]) + "/" + test.name + ".hsaco";
    hipModule_t module{};
    check(hipModuleLoad(&module, path.c_str()), "load exact assembly code object");
    hipFunction_t function{};
    check(hipModuleGetFunction(&function, module, "k"), "entry k");
    const size_t output_bytes = size_t(test.output_width) * test.output_len;
    const size_t payload_bytes = test.fragment ? std::max(output_bytes, size_t(0x400 + 512)) : output_bytes;
    Buffer input(2 * guard + size_t(test.input_width) * test.input_len);
    Buffer output(2 * guard + payload_bytes);
    size_t checked_outputs = 0, checked_guards = 0;
    for (unsigned pattern = 0; pattern < 3; ++pattern) {
      const std::vector<double> x = initialize_input(test, pattern, input);
      const std::vector<uint8_t> input_before = input.host;
      std::fill(output.host.begin(), output.host.end(), sentinel);
      input.upload(); output.upload();
      uint8_t *input_payload = input.device + guard;
      uint8_t *output_payload = output.device + guard;
      void *arguments[] = {&input_payload, &output_payload};
      check(hipModuleLaunchKernel(function, 1, 1, 1, test.block, 1, 1, 0,
                                  nullptr, arguments, nullptr), "launch exact assembly");
      check(hipDeviceSynchronize(), "synchronize");
      input.download(); output.download();
      if (input.host != input_before) {
        std::fprintf(stderr, "%s pattern=%u modified input or its guards\n", test.name, pattern);
        return 1;
      }
      total_input_bytes += input.host.size();
      const std::vector<double> expected = reference(test, x);
      for (size_t i = 0; i < expected.size(); ++i) {
        const size_t offset = guard + test.output_width * i;
        const double observed = test.output_width == 2
            ? static_cast<double>(read<_Float16>(output.host, offset))
            : test.reference == Ref::LaneWords
                ? static_cast<double>(read<uint32_t>(output.host, offset))
                : static_cast<double>(read<float>(output.host, offset));
        equal(test, pattern, "out", i, expected[i], observed);
        ++checked_outputs;
      }
      if (test.fragment) {
        // Four consecutive half elements per DS-read fragment: logical row
        // lane%16, K-group lane/16. Verify the exported gather at ABI +0x400.
        for (unsigned group = 0; group < 4; ++group)
          for (unsigned row = 0; row < 16; ++row)
            for (unsigned component = 0; component < 4; ++component) {
              const unsigned item = (group * 16 + row) * 4 + component;
              const unsigned k = group * 4 + component;
              equal(test, pattern, "fragment", item, x[row * 16 + k],
                    static_cast<double>(read<_Float16>(output.host, guard + 0x400 + 2 * item)));
              ++checked_outputs;
            }
      }
      for (size_t i = 0; i < output.host.size(); ++i) {
        const bool main_output = i >= guard && i < guard + output_bytes;
        const bool fragment_output = test.fragment && i >= guard + 0x400 && i < guard + 0x600;
        if (main_output || fragment_output) continue;
        if (output.host[i] != sentinel) {
          std::fprintf(stderr, "%s pattern=%u modified output gap/guard byte=%zu\n", test.name, pattern, i);
          return 1;
        }
        ++checked_guards;
      }
    }
    check(hipModuleUnload(module), "unload");
    total_outputs += checked_outputs;
    total_guard_bytes += checked_guards;
    std::printf("PASS %s patterns=3 output_checks=%zu guard_byte_checks=%zu atol=0 rtol=0\n",
                test.name, checked_outputs, checked_guards);
  }
  std::printf("PASS exact-native portable-matrix cases=%zu launches=%zu output_checks=%zu "
              "guard_byte_checks=%zu unchanged_input_byte_checks=%zu arch=%s\n",
              sizeof(cases) / sizeof(cases[0]), 3 * sizeof(cases) / sizeof(cases[0]),
              total_outputs, total_guard_bytes, total_input_bytes, device.gcnArchName);
}

// Run code objects assembled from the checked-in native-full-gemm.s and
// native-full-convolution.s. This file contains no GPU kernel implementation.
//
// Pinned assembly/link commands (do not recompile the HIP fixture sources):
//   llvm-mc --triple=amdgcn-amd-amdhsa --mcpu=gfx950 -filetype=obj INPUT.s -o
//   INPUT.o ld.lld -shared INPUT.o -o INPUT.hsaco hipcc -O2 -std=c++17
//   native_full_workloads.cpp -o native-full-workloads
//   ./native-full-workloads native-full-gemm.hsaco
//   native-full-convolution.hsaco
// Record source/assembly/object/code-object/driver hashes and tool versions
// with the output to identify the artifacts used by a numerical check.

#include <hip/hip_runtime.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

static void check(hipError_t error, const char *operation) {
  if (error != hipSuccess)
    throw std::runtime_error(std::string(operation) + ": " +
                             hipGetErrorString(error));
}

template <class T> struct Buffer {
  std::vector<T> host;
  T *device{};
  explicit Buffer(size_t count) : host(count) {
    check(hipMalloc(&device, count * sizeof(T)), "allocate");
  }
  Buffer(const Buffer &) = delete;
  Buffer &operator=(const Buffer &) = delete;
  ~Buffer() {
    if (device)
      (void)hipFree(device);
  }
  void upload() {
    check(hipMemcpy(device, host.data(), host.size() * sizeof(T),
                    hipMemcpyHostToDevice),
          "upload");
  }
  void download() {
    check(hipMemcpy(host.data(), device, host.size() * sizeof(T),
                    hipMemcpyDeviceToHost),
          "download");
  }
};

struct Module {
  hipModule_t handle{};
  explicit Module(const char *path) {
    check(hipModuleLoad(&handle, path), "load exact assembly code object");
  }
  Module(const Module &) = delete;
  ~Module() {
    if (handle)
      (void)hipModuleUnload(handle);
  }
  hipFunction_t function(const char *name) const {
    hipFunction_t result{};
    check(hipModuleGetFunction(&result, handle, name), name);
    return result;
  }
};

static uint16_t half_bits(double value) {
  _Float16 half = (_Float16)value;
  uint16_t bits;
  std::memcpy(&bits, &half, sizeof(bits));
  return bits;
}
static double half_value(uint16_t bits) {
  _Float16 value;
  std::memcpy(&value, &bits, sizeof(value));
  return (double)value;
}

// Independent OCP E4M3 decoding; no device conversion intrinsic or MFMA layout
// helper is used by the host reference. Exponent 15/mantissa 0..6 remain
// finite.
static float decode_e4m3(uint8_t bits) {
  unsigned exponent = (bits >> 3) & 15, fraction = bits & 7;
  if (exponent == 15 && fraction == 7)
    return std::numeric_limits<float>::quiet_NaN();
  float magnitude = exponent == 0
                        ? std::ldexp((float)fraction, -9)
                        : std::ldexp(1.0f + fraction / 8.0f, (int)exponent - 7);
  return (bits & 128) ? -magnitude : magnitude;
}
static const std::vector<uint8_t> &e4m3_pattern_codes() {
  static const std::vector<uint8_t> codes = [] {
    std::vector<uint8_t> result(15);
    for (int value = -7; value <= 7; ++value) {
      bool found = false;
      for (unsigned bits = 0; bits < 256; ++bits) {
        if (decode_e4m3((uint8_t)bits) == value / 16.0f) {
          result[value + 7] = (uint8_t)bits;
          found = true;
          break;
        }
      }
      if (!found)
        throw std::runtime_error("E4M3 pattern is not exactly encodable");
    }
    return result;
  }();
  return codes;
}

template <class T> struct Codec;
template <> struct Codec<_Float16> {
  static _Float16 encode(int numerator) {
    return (_Float16)(numerator / 16.0f);
  }
  static float decode(_Float16 value) { return (float)value; }
};
template <> struct Codec<uint8_t> {
  static uint8_t encode(int numerator) {
    return e4m3_pattern_codes()[numerator + 7];
  }
  static float decode(uint8_t value) { return decode_e4m3(value); }
};

static uint32_t mix(uint32_t value) {
  value ^= value >> 16;
  value *= 0x7feb352dU;
  value ^= value >> 15;
  value *= 0x846ca68bU;
  return value ^ (value >> 16);
}
// All coordinate bits, including high K bits, affect the asymmetric pattern.
// Values n/16, |n|<=7 are exact in both input formats. Even the largest
// possible K4096 dot has <2^18 numerator units of 1/256: its FP32 accumulation
// is exact.
static int pattern(unsigned a, unsigned b, unsigned seed, uint32_t domain) {
  uint32_t value = domain ^ (a + 1) * 0x9e3779b9U ^ (b + 3) * 0x85ebca6bU ^
                   (a + 7) * (b + 11) ^ (seed + 1) * 0xc2b2ae35U;
  return (int)(mix(value) % 15) - 7;
}

constexpr size_t Guard = 64;
constexpr uint16_t Sentinel =
    0x7e55; // A NaN payload, compared as raw bits in gaps.
struct Layout {
  size_t rows, pitch, columns;
};
struct Tolerance {
  double absolute, relative;
};
struct Report {
  size_t outputs{}, gaps{}, guards{};
  double max_absolute{}, max_relative{};
  unsigned max_half_ulp{};
};

static Report verify(const std::vector<uint16_t> &storage, Layout layout,
                     const std::vector<double> &expected, Tolerance tolerance,
                     const std::string &context) {
  if (storage.size() != 2 * Guard + layout.rows * layout.pitch ||
      expected.size() != layout.rows * layout.columns)
    throw std::runtime_error("invalid host validation dimensions");
  Report report;
  for (size_t physical = 0; physical < storage.size(); ++physical) {
    bool guard =
        physical < Guard || physical >= Guard + layout.rows * layout.pitch;
    size_t index = guard ? 0 : physical - Guard;
    size_t row = index / layout.pitch, column = index % layout.pitch;
    if (guard || column >= layout.columns) {
      if (storage[physical] != Sentinel)
        throw std::runtime_error(
            context + " changed " + (guard ? "guard" : "output gap") +
            " at allocation index " + std::to_string(physical));
      if (guard)
        ++report.guards;
      else
        ++report.gaps;
      continue;
    }
    double actual = half_value(storage[physical]);
    double reference = expected[row * layout.columns + column];
    double difference = std::abs(actual - reference);
    if (!std::isfinite(actual) || !std::isfinite(reference) ||
        difference >
            tolerance.absolute + tolerance.relative * std::abs(reference)) {
      char detail[256];
      std::snprintf(
          detail, sizeof(detail),
          " row=%zu col=%zu expected=%.12g actual=%.12g abs_error=%.12g", row,
          column, reference, actual, difference);
      throw std::runtime_error(context + detail);
    }
    ++report.outputs;
    report.max_absolute = std::max(report.max_absolute, difference);
    if (reference != 0.0)
      report.max_relative =
          std::max(report.max_relative, difference / std::abs(reference));
    auto rank = [](uint16_t bits) {
      return (bits & 0x8000) ? 32768 - int(bits & 0x7fff) : 32768 + int(bits);
    };
    report.max_half_ulp = std::max(
        report.max_half_ulp, (unsigned)std::abs(rank(storage[physical]) -
                                                rank(half_bits(reference))));
  }
  return report;
}

static void host_self_test() {
  if (decode_e4m3(0x38) != 1.0f || decode_e4m3(0xb8) != -1.0f ||
      decode_e4m3(0x7e) != 448.0f || decode_e4m3(1) != std::ldexp(1.0f, -9) ||
      !std::isnan(decode_e4m3(0x7f)) || !std::isnan(decode_e4m3(0xff)))
    throw std::runtime_error("independent OCP E4M3 decoder anchors failed");
  for (int n = -7; n <= 7; ++n)
    if (Codec<uint8_t>::decode(Codec<uint8_t>::encode(n)) != n / 16.0f)
      throw std::runtime_error("OCP E4M3 exact pattern roundtrip failed");
  Layout layout{2, 7, 3};
  std::vector<uint16_t> values(2 * Guard + 14, Sentinel);
  for (size_t row = 0; row < 2; ++row)
    for (size_t column = 0; column < 3; ++column)
      values[Guard + row * 7 + column] = 0;
  std::vector<double> expected(6, 0.0);
  Report good = verify(values, layout, expected, {0, 0}, "self-test");
  if (good.outputs != 6 || good.gaps != 8 || good.guards != 128)
    throw std::runtime_error("host checker missed part of its footprint");
  for (size_t corrupted : {size_t(0), Guard + 3, Guard, values.size() - 1}) {
    auto bad = values;
    bad[corrupted] = corrupted == Guard ? Sentinel : half_bits(1.0);
    bool rejected = false;
    try {
      (void)verify(bad, layout, expected, {0, 0}, "intentional corruption");
    } catch (const std::runtime_error &) {
      rejected = true;
    }
    if (!rejected)
      throw std::runtime_error(
          "host checker accepted intentional output/gap/guard corruption");
  }
  std::printf("PASS host checker detects missing output, gap overwrite, "
              "prefix/suffix overwrite; OCP E4M3 anchors\n");
}

static void launch_and_verify(hipFunction_t function, const char *name,
                              unsigned pattern_id, unsigned threads,
                              void **arguments, Buffer<uint16_t> &out,
                              Layout layout,
                              const std::vector<double> &reference,
                              Tolerance tolerance) {
  std::fill(out.host.begin(), out.host.end(), Sentinel);
  out.upload();
  check(hipModuleLaunchKernel(function, 1, 1, 1, threads, 1, 1, 0, nullptr,
                              arguments, nullptr),
        name);
  check(hipDeviceSynchronize(), "synchronize native full workload");
  out.download();
  Report result =
      verify(out.host, layout, reference, tolerance,
             std::string(name) + " pattern=" + std::to_string(pattern_id));
  std::printf("PASS %s pattern=%u outputs=%zu gaps=%zu guards=%zu atol=%.9g "
              "rtol=%.9g max_abs=%.12g max_rel=%.12g max_half_ulp=%u\n",
              name, pattern_id, result.outputs, result.gaps, result.guards,
              tolerance.absolute, tolerance.relative, result.max_absolute,
              result.max_relative, result.max_half_ulp);
  std::fflush(stdout);
}

template <class T>
static void gemm(const Module &module, const char *plain_name,
                 const char *fused_name, unsigned patterns) {
  constexpr size_t M = 256, N = 256, K = 4096, Pitch = 4096;
  Buffer<T> a(M * K), b(K * Pitch), add(M * Pitch);
  Buffer<uint16_t> out(2 * Guard + M * Pitch);
  std::vector<float> ar(a.host.size()), br(b.host.size()),
      add_real(add.host.size());
  hipFunction_t plain = module.function(plain_name),
                fused = module.function(fused_name);
  void *output_pointer = out.device + Guard;
  void *plain_arguments[] = {&a.device, &b.device, &output_pointer};
  void *fused_arguments[] = {&a.device, &b.device, &add.device,
                             &output_pointer};
  for (unsigned seed = 0; seed < patterns; ++seed) {
    for (size_t row = 0; row < M; ++row)
      for (size_t k = 0; k < K; ++k) {
        size_t index = row * K + k;
        a.host[index] = Codec<T>::encode(pattern(row, k, seed, 0x41d2c3b4U));
        ar[index] = Codec<T>::decode(a.host[index]);
      }
    for (size_t k = 0; k < K; ++k)
      for (size_t column = 0; column < Pitch; ++column) {
        size_t index = k * Pitch + column;
        b.host[index] = Codec<T>::encode(pattern(k, column, seed, 0xb8632791U));
        br[index] = Codec<T>::decode(b.host[index]);
      }
    for (size_t row = 0; row < M; ++row)
      for (size_t column = 0; column < Pitch; ++column) {
        size_t index = row * Pitch + column;
        add.host[index] =
            Codec<T>::encode(pattern(row, column, seed, 0x93a71e05U));
        add_real[index] = Codec<T>::decode(add.host[index]);
      }
    a.upload();
    b.upload();
    add.upload();
    std::vector<double> dot(M * N, 0.0), reference(M * N),
        fused_reference(M * N);
    auto start = std::chrono::steady_clock::now();
    // Independent ordinary row-major CPU GEMM: all 4096 terms, original B
    // pitch.
    for (size_t row = 0; row < M; ++row)
      for (size_t k = 0; k < K; ++k) {
        double left = ar[row * K + k];
        for (size_t column = 0; column < N; ++column)
          dot[row * N + column] += left * (double)br[k * Pitch + column];
      }
    for (size_t row = 0; row < M; ++row)
      for (size_t column = 0; column < N; ++column) {
        size_t index = row * N + column;
        reference[index] = half_value(half_bits(dot[index]));
        double value = dot[index] + add_real[row * Pitch + column];
        fused_reference[index] =
            half_value(half_bits(value / (1.0 + std::exp(-value))));
      }
    double seconds =
        std::chrono::duration<double>(std::chrono::steady_clock::now() - start)
            .count();
    std::printf("REFERENCE %s pattern=%u M=256 N=256 K=4096 A_pitch=4096 "
                "B_pitch=4096 output_pitch=4096 cpu_seconds=%.6f\n",
                plain_name, seed, seconds);
    launch_and_verify(plain, plain_name, seed, 1024, plain_arguments, out,
                      {M, Pitch, N}, reference, {0, 0});
    // Natural SiLU CPU formula; finite tolerance covers approximate device SFU
    // and reciprocal plus final F16 rounding. This is fixed before the run.
    launch_and_verify(fused, fused_name, seed, 1024, fused_arguments, out,
                      {M, Pitch, N}, fused_reference, {0.000001, 0.002});
  }
}

template <class T>
static void convolution(const Module &module, const char *name,
                        unsigned patterns) {
  constexpr size_t Cin = 64, H = 56, W = 56, Cout = 128, R = 3, S = 3;
  constexpr size_t OutputWidth = 54, Pitch = 54 * 54, Positions = 128;
  Buffer<T> image(Cin * H * W), weights(Cout * Cin * R * S);
  Buffer<uint16_t> out(2 * Guard + Cout * Pitch);
  std::vector<float> xr(image.host.size()), wr(weights.host.size());
  hipFunction_t function = module.function(name);
  void *output_pointer = out.device + Guard;
  void *arguments[] = {&image.device, &weights.device, &output_pointer};
  for (unsigned seed = 0; seed < patterns; ++seed) {
    for (size_t channel = 0; channel < Cin; ++channel)
      for (size_t y = 0; y < H; ++y)
        for (size_t x = 0; x < W; ++x) {
          size_t index = (channel * H + y) * W + x;
          image.host[index] =
              Codec<T>::encode(pattern(channel * H + y, x, seed, 0x13579bdfU));
          xr[index] = Codec<T>::decode(image.host[index]);
        }
    for (size_t output = 0; output < Cout; ++output)
      for (size_t input = 0; input < Cin; ++input)
        for (size_t y = 0; y < R; ++y)
          for (size_t x = 0; x < S; ++x) {
            size_t index = ((output * Cin + input) * R + y) * S + x;
            weights.host[index] = Codec<T>::encode(
                pattern(output * Cin + input, y * S + x, seed, 0x2468ace1U));
            wr[index] = Codec<T>::decode(weights.host[index]);
          }
    image.upload();
    weights.upload();
    std::vector<double> reference(Cout * Positions);
    // Independent NCHW/OIHW loops, without the native im2col/MFMA coordinate
    // map. The first 128 positions span output rows 54+54+20, not one long
    // input row.
    for (size_t output = 0; output < Cout; ++output)
      for (size_t pixel = 0; pixel < Positions; ++pixel) {
        size_t oy = pixel / OutputWidth, ox = pixel % OutputWidth;
        double sum = 0.0;
        for (size_t input = 0; input < Cin; ++input)
          for (size_t ry = 0; ry < R; ++ry)
            for (size_t rx = 0; rx < S; ++rx)
              sum += (double)xr[(input * H + oy + ry) * W + ox + rx] *
                     (double)wr[((output * Cin + input) * R + ry) * S + rx];
        reference[output * Positions + pixel] = half_value(half_bits(sum));
      }
    std::printf("REFERENCE %s pattern=%u NCHW=64x56x56 OIHW=128x64x3x3 K=576 "
                "output_tile=128x128 output_pitch=2916\n",
                name, seed);
    launch_and_verify(function, name, seed, 512, arguments, out,
                      {Cout, Pitch, Positions}, reference, {0, 0});
  }
}

int main(int argc, char **argv) {
  try {
    host_self_test();
    if (argc == 2 && std::string(argv[1]) == "--self-test")
      return 0;
    if (argc != 3 && argc != 4) {
      std::fprintf(stderr,
                   "usage: %s native-full-gemm.hsaco "
                   "native-full-convolution.hsaco [patterns>=3]\n",
                   argv[0]);
      return 2;
    }
    unsigned patterns = 3;
    if (argc == 4) {
      char *end{};
      unsigned long value = std::strtoul(argv[3], &end, 10);
      if (!end || *end || value < 3 || value > 17)
        throw std::runtime_error("patterns must be an integer in 3..17");
      patterns = (unsigned)value;
    }
    check(hipSetDevice(0), "select device0");
    hipDeviceProp_t device{};
    check(hipGetDeviceProperties(&device, 0), "device properties");
    if (std::string(device.gcnArchName).find("gfx950") != 0)
      throw std::runtime_error("hardware reference requires gfx950");
    int runtime{}, driver{};
    check(hipRuntimeGetVersion(&runtime), "HIP runtime version");
    check(hipDriverGetVersion(&driver), "HIP driver version");
    std::printf(
        "DEVICE name=%s arch=%s wave=%d max_threads=%d runtime=%d driver=%d\n",
        device.name, device.gcnArchName, device.warpSize,
        device.maxThreadsPerBlock, runtime, driver);
    std::printf("CODE_OBJECT gemm=%s convolution=%s selected_workgroup=0,0,0 "
                "patterns=%u\n",
                argv[1], argv[2], patterns);
    Module gemm_module(argv[1]), conv_module(argv[2]);
    gemm<_Float16>(gemm_module, "gemm_f16_full", "gemm_add_silu_f16_full",
                   patterns);
    gemm<uint8_t>(gemm_module, "gemm_f8_full", "gemm_add_silu_f8_full",
                  patterns);
    convolution<_Float16>(conv_module, "convolution_f16_full", patterns);
    convolution<uint8_t>(conv_module, "convolution_f8_full", patterns);
    std::printf("PASS all 6 full native workloads patterns=%u "
                "output_checks=%zu gap_checks=%zu guard_checks=%zu\n",
                patterns, (4 * size_t(65536) + 2 * size_t(16384)) * patterns,
                (4 * size_t(983040) + 2 * size_t(356864)) * patterns,
                6 * 2 * Guard * patterns);
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "FAIL %s\n", error.what());
    return 1;
  }
}

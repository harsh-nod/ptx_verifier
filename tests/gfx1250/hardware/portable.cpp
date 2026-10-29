// Host-only numerical oracle for the exact native-portable-workloads.s module.
// No device kernels are compiled into this executable. portable_run.py generates
// portable_manifest.hpp from the pinned manifest; it contains topology, not math.
#include <hip/hip_runtime.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <limits>
#include <map>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

struct ArraySpec {
  const char *name;
  uint64_t address;
  size_t count;
  const char *kind;
};
struct CaseSpec {
  const char *kernel;
  std::array<unsigned, 3> block, grid;
  std::vector<ArraySpec> arrays;
  std::vector<std::string> parameters;
  size_t outputs;
};
#include "portable_manifest.hpp"

using Inputs = std::map<std::string, std::vector<double>>;
using Outputs = std::map<std::string, std::vector<double>>;
constexpr size_t kGuardBytes = 4096;
constexpr uint32_t kGapSentinel = 0x7fc3c3c3; // NaN also exposes stray F32 reads.
enum class ByteKind : uint8_t { Gap, Input, Output, Guard };
constexpr uint32_t kUnwritten = 0x7fc5a5a5; // NaN: an unwritten zero cannot pass.

static void require(bool condition, const std::string &message) {
  if (!condition)
    throw std::runtime_error(message);
}
static void hip_check(hipError_t error, const char *operation) {
  if (error != hipSuccess)
    throw std::runtime_error(std::string(operation) + ": " + hipGetErrorString(error));
}
static std::string json_string(const std::string &value) {
  std::string result = "\"";
  for (unsigned char c : value) {
    if (c == '"' || c == '\\') {
      result += '\\';
      result += char(c);
    } else if (c >= 32 && c < 127)
      result += char(c);
    else {
      const char *hex = "0123456789abcdef";
      result += "\\u00";
      result += hex[c >> 4];
      result += hex[c & 15];
    }
  }
  return result + '"';
}
static uint32_t name_hash(const std::string &name) {
  uint32_t value = 2166136261u;
  for (unsigned char c : name)
    value = (value ^ c) * 16777619u;
  return value;
}

// Bounded coordinate patterns distinguish arrays, rows, columns and iterations.
// Values are rounded to the actual external F32 representation before reference
// evaluation. Integer IndexInput arrays retain exactly the manifest's i=i rule.
static float input_value(const std::string &name, size_t i, unsigned pattern) {
  uint32_t salt = name_hash(name) % 97;
  double value =
      (int((i * 13 + (i / 7) * 5 + salt * 3 + pattern * 11 + pattern * (i % 5)) % 33) - 16) / 16.0;
  if (pattern == 0)
    value = 0;
  if (pattern == 1)
    value = (i % 2 ? -1.0 : 1.0) * double(1 + (i % 7)) / 16.0;
  if (name == "dt")
    value = 0.125 + ((i * 3 + pattern) % 9) / 32.0;
  if (name == "da" || name == "log_lambda" || name == "g_hat" || name == "log_b")
    value *= 0.5;
  if (name == "weight")
    value = 0.5 + value * 0.5;
  if (name == "q_scale")
    value = 0.25 + (pattern % 5) / 16.0;
  if (name == "k_scale")
    value = 0.125 + ((i * 3 + pattern) % 7) / 32.0;
  if (name == "cosine")
    value = std::cos((i * 3 + pattern * 5 + 1) / 17.0);
  if (name == "sine")
    value = std::sin((i * 3 + pattern * 5 + 1) / 17.0);
  return static_cast<float>(value);
}

// These assertions exercise actual input generation before any device launch.
// In particular, multiplying a negative int by size_t would silently wrap: keep
// explicit signed-alternation controls as well as exhaustive finite/range checks.
static size_t input_pattern_self_test(unsigned patterns) {
  require(input_value("x", 1, 1) == -0.125f, "odd pattern coordinate lost its sign");
  require(input_value("gate", 3, 1) == -0.25f, "odd gate coordinate lost its sign");
  require(input_value("x", 0, 1) == 0.0625f, "even pattern coordinate changed");
  size_t checks = 0;
  for (const auto &test : kCases)
    for (const auto &array : test.arrays)
      if (std::string(array.kind) == "in")
        for (unsigned pattern = 0; pattern < patterns; ++pattern)
          for (size_t i = 0; i < array.count; ++i) {
            float value = input_value(array.name, i, pattern);
            require(std::isfinite(value) && std::abs(value) <= 1.0f,
                    "input pattern exceeded its finite [-1,1] envelope");
            ++checks;
          }
  return checks;
}

// Ordinary row-major CPU formulas, using double arithmetic on decoded inputs.
// These do not use executor expressions, ISA lane layouts, device intrinsics,
// approximate exp2/log2 conversion constants, or generated numerical code.
static Outputs reference(const std::string &kernel, const Inputs &input) {
  auto at = [&](const char *name, size_t index) { return input.at(name).at(index); };
  auto logistic = [](double x) { return 1.0 / (1.0 + std::exp(-x)); };
  Outputs result;
  if (kernel == "portable_relu" || kernel == "portable_sigmoid" || kernel == "portable_silu" ||
      kernel == "portable_swiglu") {
    auto &out = result["out"];
    out.resize(64);
    for (size_t i = 0; i < 64; ++i) {
      double x = at(kernel == "portable_swiglu" ? "gate" : "x", i);
      out[i] = kernel == "portable_relu" ? std::max(x, 0.0) : logistic(x);
      if (kernel == "portable_silu" || kernel == "portable_swiglu")
        out[i] *= x;
      if (kernel == "portable_swiglu")
        out[i] *= at("value", i);
    }
  } else if (kernel == "portable_rope") {
    auto &out = result["out"];
    out.resize(32);
    for (size_t component = 0; component < 16; ++component) {
      double x = at("x", component), y = at("x", component + 16);
      out[component] = x * at("cosine", component) - y * at("sine", component);
      out[component + 16] = y * at("cosine", component + 16) + x * at("sine", component + 16);
    }
  } else if (kernel == "portable_reduction" || kernel == "portable_softmax" ||
             kernel == "portable_rmsnorm") {
    auto &out = result["out"];
    out.resize(kernel == "portable_reduction" ? 2 : 64);
    for (size_t row = 0; row < 2; ++row) {
      double sum = 0, maximum = -std::numeric_limits<double>::infinity();
      for (size_t col = 0; col < 32; ++col) {
        double x = at("x", row * 32 + col);
        maximum = std::max(maximum, x);
        sum += kernel == "portable_rmsnorm" ? x * x : x;
      }
      if (kernel == "portable_reduction") {
        out[row] = sum;
        continue;
      }
      if (kernel == "portable_softmax") {
        sum = 0;
        for (size_t col = 0; col < 32; ++col)
          sum += std::exp(at("x", row * 32 + col) - maximum);
      }
      double denominator =
          kernel == "portable_rmsnorm" ? std::sqrt(sum / 32 + static_cast<double>(1.0e-6f)) : sum;
      for (size_t col = 0; col < 32; ++col) {
        size_t i = row * 32 + col;
        out[i] = kernel == "portable_rmsnorm" ? at("x", i) * at("weight", i) / denominator
                                              : std::exp(at("x", i) - maximum) / denominator;
      }
    }
  } else if (kernel == "portable_matvec" || kernel == "portable_gemm" ||
             kernel == "portable_gemm_add_silu") {
    const bool vector = kernel == "portable_matvec";
    size_t columns = vector ? 1 : 8, inner = vector ? 32 : 16;
    auto &out = result["out"];
    out.resize(4 * columns);
    for (size_t row = 0; row < 4; ++row)
      for (size_t col = 0; col < columns; ++col) {
        double value = 0;
        for (size_t k = 0; k < inner; ++k)
          value += at("a", row * inner + k) * (vector ? at("x", k) : at("b", k * columns + col));
        size_t index = row * columns + col;
        if (kernel == "portable_gemm_add_silu") {
          value += at("addend", index);
          value *= logistic(value);
        }
        out[index] = value;
      }
  } else if (kernel == "portable_bitdelta" || kernel == "portable_bitdelta_batched") {
    size_t batches = kernel == "portable_bitdelta" ? 1 : 2;
    for (size_t batch = 0; batch < batches; ++batch)
      for (size_t col = 0; col < 4; ++col) {
        std::string name = "out" + std::to_string(batch) + std::to_string(col);
        auto &out = result[name];
        out.resize(2);
        uint32_t word = static_cast<uint32_t>(at("packed", batch * 4 + col));
        for (size_t row = 0; row < 2; ++row) {
          double sum = 0;
          for (unsigned bit = 0; bit < 32; ++bit)
            sum += at("a", (batch * 2 + row) * 32 + bit) * ((word & (uint32_t(1) << bit)) ? 1 : -1);
          out[row] = sum;
        }
      }
  } else if (kernel == "portable_convolution") {
    auto &out = result["out"];
    out.resize(18);
    // NCHW input [1,2,5,5], OIHW weights [2,2,3,3], valid [1,2,3,3].
    for (size_t o = 0; o < 2; ++o)
      for (size_t h = 0; h < 3; ++h)
        for (size_t w = 0; w < 3; ++w) {
          double sum = 0;
          for (size_t c = 0; c < 2; ++c)
            for (size_t r = 0; r < 3; ++r)
              for (size_t s = 0; s < 3; ++s)
                sum += at("x", (c * 5 + h + r) * 5 + w + s) *
                       at("weight", ((o * 2 + c) * 3 + r) * 3 + s);
          out[(o * 3 + h) * 3 + w] = sum;
        }
  } else if (kernel == "portable_mamba_state") {
    auto &out = result["states"];
    out.resize(16);
    for (size_t row = 0; row < 4; ++row)
      for (size_t col = 0; col < 4; ++col)
        for (size_t t = 0; t < 8; ++t)
          out[row * 4 + col] += at("x", t * 4 + row) * at("b", t * 4 + col) * at("dt", t) *
                                std::exp(std::min(at("da", 7) - at("da", t), 0.0));
  } else if (kernel == "portable_mamba_scan") {
    auto &out = result["out"];
    out.resize(8);
    result["out_x"] = std::vector<double>(8, 0);
    for (size_t row = 0; row < 2; ++row)
      for (size_t col = 0; col < 4; ++col) {
        double previous = 0, scan = 0;
        for (size_t state = 0; state < 4; ++state)
          previous += at("c", row * 4 + state) * at("prev", col * 4 + state);
        for (size_t t = 0; t < 8; ++t)
          scan += at("cb", row * 8 + t) * std::exp(std::min(at("da", row) - at("da", t), 0.0)) *
                  at("dt", t) * at("x", t * 4 + col);
        out[row * 4 + col] = std::exp(at("da", row)) * previous + scan;
      }
  } else if (kernel == "portable_flash_attention" || kernel == "portable_forgetting_attention" ||
             kernel == "portable_sage_attention") {
    bool forgetting = kernel == "portable_forgetting_attention",
         sage = kernel == "portable_sage_attention";
    auto &out = result["out"];
    out.resize(8);
    if (!sage)
      result["lse"].resize(2);
    for (size_t row = 0; row < 2; ++row) {
      std::array<double, 8> scores{}, probabilities{};
      for (size_t key = 0; key < 8; ++key) {
        double dot = 0;
        for (size_t d = 0; d < 4; ++d)
          dot += at("q", row * 4 + d) * at("k", key * 4 + d);
        scores[key] = sage ? dot * at("q_scale", 0) * at("k_scale", key / 4)
                           : dot * 0.125 - (forgetting ? at("log_lambda", key) : 0.0);
      }
      double maximum = *std::max_element(scores.begin(), scores.end()), total = 0;
      for (size_t key = 0; key < 8; ++key) {
        probabilities[key] = std::exp(scores[key] - maximum);
        total += probabilities[key];
      }
      for (size_t col = 0; col < 4; ++col) {
        double weighted = 0;
        for (size_t key = 0; key < 8; ++key)
          weighted += probabilities[key] * at("v", key * 4 + col);
        out[row * 4 + col] = weighted / total;
      }
      if (!sage)
        result["lse"][row] = maximum + std::log(total) + (forgetting ? at("log_lambda", row) : 0.0);
    }
  } else if (kernel == "portable_sinkhorn") {
    auto &out = result["f_out"];
    out.resize(2);
    for (size_t row = 0; row < 2; ++row) {
      std::array<double, 8> scores{};
      for (size_t key = 0; key < 8; ++key) {
        double dot = 0;
        for (size_t d = 0; d < 4; ++d)
          dot += at("x", row * 4 + d) * at("y", key * 4 + d);
        scores[key] = 2 * dot + at("g_hat", key) + at("log_b", key);
      }
      double maximum = *std::max_element(scores.begin(), scores.end()), total = 0;
      for (double score : scores)
        total += std::exp(score - maximum);
      out[row] = 0.5 * (at("f_hat", row) - maximum - std::log(total));
    }
  } else
    throw std::runtime_error("no independent CPU reference for " + kernel);
  return result;
}

// Closed-form all-ones controls exercise every reference branch, independently
// of coordinate-pattern generation and any device execution.
static void reference_self_test() {
  size_t checks = 0;
  for (const CaseSpec &test : kCases) {
    Inputs inputs;
    for (const auto &a : test.arrays)
      if (std::string(a.kind) != "out") {
        auto &values = inputs[a.name];
        values.assign(a.count, 1);
        if (std::string(a.kind) == "index")
          for (size_t i = 0; i < a.count; ++i)
            values[i] = i;
      }
    Outputs actual = reference(test.kernel, inputs);
    std::string name = test.kernel;
    for (const auto &a : test.arrays)
      if (std::string(a.kind) == "out") {
        require(actual.at(a.name).size() == a.count, "self-test reference shape mismatch");
        for (size_t i = 0; i < a.count; ++i) {
          double expected = 0;
          if (name == "portable_relu")
            expected = 1;
          else if (name == "portable_sigmoid" || name == "portable_silu" ||
                   name == "portable_swiglu")
            expected = 1 / (1 + std::exp(-1.0));
          else if (name == "portable_rope")
            expected = i < 16 ? 0 : 2;
          else if (name == "portable_reduction" || name == "portable_matvec")
            expected = 32;
          else if (name == "portable_softmax")
            expected = 1.0 / 32;
          else if (name == "portable_rmsnorm")
            expected = 1 / std::sqrt(1 + double(1.0e-6f));
          else if (name == "portable_gemm")
            expected = 16;
          else if (name == "portable_gemm_add_silu")
            expected = 17 / (1 + std::exp(-17.0));
          else if (name == "portable_bitdelta" || name == "portable_bitdelta_batched") {
            unsigned word = unsigned(a.name[3] - '0') * 4 + unsigned(a.name[4] - '0');
            unsigned population = 0;
            for (unsigned bit = 0; bit < 32; ++bit)
              population += (word >> bit) & 1;
            expected = 2 * int(population) - 32;
          } else if (name == "portable_convolution")
            expected = 18;
          else if (name == "portable_mamba_state")
            expected = 8;
          else if (name == "portable_mamba_scan")
            expected = std::string(a.name) == "out_x" ? 0 : 4 * std::exp(1.0) + 8;
          else if (name == "portable_flash_attention" || name == "portable_forgetting_attention")
            expected = std::string(a.name) == "lse" ? 0.5 + std::log(8.0) : 1;
          else if (name == "portable_sage_attention")
            expected = 1;
          else if (name == "portable_sinkhorn")
            expected = 0.5 - 0.5 * (10 + std::log(8.0));
          else
            throw std::runtime_error("missing closed-form control");
          require(std::abs(actual.at(a.name)[i] - expected) < 1e-12,
                  "closed-form CPU oracle failed: " + name);
          ++checks;
        }
      }
  }
  require(checks == 590, "CPU oracle self-test did not cover all 590 values");
}

struct Totals {
  size_t outputs = 0, input_bytes = 0, gap_bytes = 0, guard_bytes = 0, launches = 0;
  double max_absolute_error = 0, max_relative_error = 0;
};
static std::pair<double, double> tolerance(const std::string &name) {
  // Dyadic input arithmetic is exact for these bounded linear workloads.
  if (name == "portable_relu" || name == "portable_reduction" || name == "portable_matvec" ||
      name == "portable_gemm" || name == "portable_bitdelta" ||
      name == "portable_bitdelta_batched" || name == "portable_convolution")
    return {0, 0};
  if (name == "portable_rope")
    return {2e-7, 2e-6};
  return {2e-6, 2e-5};
}
static void run_case(hipModule_t module, const CaseSpec &test, unsigned pattern, Totals &total) {
  uint64_t low = UINT64_MAX, high = 0;
  for (const auto &a : test.arrays) {
    low = std::min(low, a.address);
    high = std::max(high, a.address + a.count * 4);
  }
  require(high > low && high - low <= (1u << 20), "invalid guarded arena span");
  size_t size = size_t(high - low) + 2 * kGuardBytes;
  std::vector<uint8_t> before(size), after(size);
  std::vector<ByteKind> category(size, ByteKind::Gap);
  for (size_t offset = 0; offset < size; offset += 4)
    std::memcpy(before.data() + offset, &kGapSentinel, 4);
  std::fill(category.begin(), category.begin() + kGuardBytes, ByteKind::Guard);
  std::fill(category.end() - kGuardBytes, category.end(), ByteKind::Guard);
  Inputs inputs;
  Outputs expected;
  size_t declared_outputs = 0;
  for (const auto &a : test.arrays) {
    size_t offset = kGuardBytes + size_t(a.address - low);
    bool output = std::string(a.kind) == "out";
    for (size_t i = 0; i < a.count; ++i) {
      uint32_t bits = kUnwritten;
      if (!output) {
        if (std::string(a.kind) == "index") {
          bits = uint32_t(i);
          inputs[a.name].push_back(i);
        } else {
          float value = input_value(a.name, i, pattern);
          std::memcpy(&bits, &value, 4);
          inputs[a.name].push_back(value);
        }
      }
      std::memcpy(before.data() + offset + 4 * i, &bits, 4);
    }
    std::fill(category.begin() + offset, category.begin() + offset + a.count * 4,
              output ? ByteKind::Output : ByteKind::Input);
    if (output)
      declared_outputs += a.count;
  }
  require(declared_outputs == test.outputs, "manifest output count mismatch");
  expected = reference(test.kernel, inputs);
  size_t expected_count = 0;
  for (const auto &entry : expected)
    expected_count += entry.second.size();
  require(expected_count == declared_outputs, "CPU reference output selection mismatch");

  void *device = nullptr;
  hip_check(hipMalloc(&device, size), "allocate guarded arena");
  try {
    hip_check(hipMemcpy(device, before.data(), size, hipMemcpyHostToDevice), "upload arena");
    std::vector<void *> pointers, arguments;
    pointers.reserve(test.parameters.size());
    arguments.reserve(test.parameters.size());
    for (const auto &name : test.parameters) {
      auto found = std::find_if(test.arrays.begin(), test.arrays.end(),
                                [&](const ArraySpec &a) { return name == a.name; });
      require(found != test.arrays.end(), "unresolved pointer parameter");
      pointers.push_back(static_cast<uint8_t *>(device) + kGuardBytes +
                         size_t(found->address - low));
    }
    for (auto &pointer : pointers)
      arguments.push_back(&pointer);
    hipFunction_t function{};
    hip_check(hipModuleGetFunction(&function, module, test.kernel), "resolve exact native kernel");
    hip_check(hipModuleLaunchKernel(function, test.grid[0], test.grid[1], test.grid[2],
                                    test.block[0], test.block[1], test.block[2], 0, nullptr,
                                    arguments.data(), nullptr),
              "launch exact native kernel");
    hip_check(hipDeviceSynchronize(), "synchronize exact native kernel");
    hip_check(hipMemcpy(after.data(), device, size, hipMemcpyDeviceToHost),
              "download guarded arena");
  } catch (...) {
    (void)hipFree(device);
    throw;
  }
  hip_check(hipFree(device), "free guarded arena");

  for (size_t byte = 0; byte < size; ++byte)
    if (category[byte] != ByteKind::Output) {
      if (after[byte] != before[byte])
        throw std::runtime_error(std::string(test.kernel) + " pattern=" + std::to_string(pattern) +
                                 " changed non-output byte=" + std::to_string(byte) +
                                 " category=" + std::to_string(unsigned(category[byte])));
      if (category[byte] == ByteKind::Input)
        ++total.input_bytes;
      else if (category[byte] == ByteKind::Guard)
        ++total.guard_bytes;
      else
        ++total.gap_bytes;
    }
  auto [atol, rtol] = tolerance(test.kernel);
  for (const auto &a : test.arrays)
    if (std::string(a.kind) == "out") {
      const auto &values = expected.at(a.name);
      require(values.size() == a.count, "reference array length mismatch");
      size_t offset = kGuardBytes + size_t(a.address - low);
      for (size_t i = 0; i < a.count; ++i) {
        float observed;
        std::memcpy(&observed, after.data() + offset + 4 * i, 4);
        double value = values[i], error = std::abs(double(observed) - value);
        require(std::isfinite(value), "nonfinite CPU reference");
        if (!std::isfinite(observed) || error > atol + rtol * std::abs(value)) {
          std::cerr << std::setprecision(17) << test.kernel << " pattern=" << pattern << " "
                    << a.name << '[' << i << "] expected=" << value << " actual=" << observed
                    << " error=" << error << "\n";
          throw std::runtime_error("full-footprint numeric comparison failed");
        }
        ++total.outputs;
        total.max_absolute_error = std::max(total.max_absolute_error, error);
        if (value != 0)
          total.max_relative_error = std::max(total.max_relative_error, error / std::abs(value));
      }
    }
  ++total.launches;
}

int main(int argc, char **argv) {
  try {
    require(argc == 3, "usage: portable_driver exact.hsaco patterns");
    std::string count = argv[2];
    size_t consumed = 0;
    unsigned long parsed = std::stoul(count, &consumed);
    require(consumed == count.size() && parsed >= 1 && parsed <= 256, "patterns must be 1..256");
    unsigned patterns = unsigned(parsed);
    require(kCases.size() == 20, "all 20 portable cases are mandatory");
    reference_self_test();
    size_t pattern_checks = input_pattern_self_test(patterns);
    int devices = 0;
    hip_check(hipGetDeviceCount(&devices), "count visible devices");
    require(devices == 1, "select exactly one physical GPU with HIP_VISIBLE_DEVICES");
    hip_check(hipSetDevice(0), "select HIP-visible device zero");
    hipDeviceProp_t property{};
    hip_check(hipGetDeviceProperties(&property, 0), "device properties");
    std::string architecture = property.gcnArchName;
    require(architecture == "gfx1250" || architecture.rfind("gfx1250:", 0) == 0,
            "actual device is not gfx1250");
    require(property.warpSize == 32, "actual gfx1250 device must have wave size 32");
    int runtime = 0, driver = 0;
    hip_check(hipRuntimeGetVersion(&runtime), "HIP runtime version");
    hip_check(hipDriverGetVersion(&driver), "HIP driver version");
    char bus[32]{};
    hip_check(hipDeviceGetPCIBusId(bus, sizeof(bus), 0), "device PCI identity");
    hipModule_t module{};
    hip_check(hipModuleLoad(&module, argv[1]), "load exact unchanged assembly code object");
    std::ostringstream report;
    report << std::setprecision(17)
           << "{\"status\":\"pass\",\"device\":{\"name\":" << json_string(property.name)
           << ",\"architecture\":" << json_string(architecture)
           << ",\"pci_bus_id\":" << json_string(bus) << ",\"wave_size\":" << property.warpSize
           << ",\"compute_units\":" << property.multiProcessorCount
           << ",\"hip_runtime\":" << runtime << ",\"hip_driver\":" << driver
           << "},\"patterns\":" << patterns
           << ",\"reference_closed_form_checks\":590,\"input_pattern_checks\":" << pattern_checks
           << ",\"signed_alternation_checks\":3,\"cases\":[";
    Totals all;
    bool first = true;
    for (const auto &test : kCases) {
      Totals totals;
      for (unsigned pattern = 0; pattern < patterns; ++pattern)
        run_case(module, test, pattern, totals);
      require(totals.outputs == test.outputs * patterns && totals.launches == patterns,
              "incomplete case execution");
      if (!first)
        report << ',';
      first = false;
      auto [atol, rtol] = tolerance(test.kernel);
      report << "{\"kernel\":" << json_string(test.kernel) << ",\"launches\":" << totals.launches
             << ",\"outputs\":" << totals.outputs
             << ",\"unchanged_input_bytes\":" << totals.input_bytes
             << ",\"unchanged_gap_bytes\":" << totals.gap_bytes
             << ",\"unchanged_guard_bytes\":" << totals.guard_bytes << ",\"atol\":" << atol
             << ",\"rtol\":" << rtol << ",\"max_absolute_error\":" << totals.max_absolute_error
             << ",\"max_relative_error\":" << totals.max_relative_error << '}';
      all.outputs += totals.outputs;
      all.launches += totals.launches;
      all.input_bytes += totals.input_bytes;
      all.gap_bytes += totals.gap_bytes;
      all.guard_bytes += totals.guard_bytes;
    }
    hip_check(hipModuleUnload(module), "unload exact native module");
    require(all.outputs == size_t(590) * patterns && all.launches == size_t(20) * patterns,
            "incomplete mandatory corpus");
    report << "],\"totals\":{\"launches\":" << all.launches << ",\"outputs\":" << all.outputs
           << ",\"unchanged_input_bytes\":" << all.input_bytes
           << ",\"unchanged_gap_bytes\":" << all.gap_bytes
           << ",\"unchanged_guard_bytes\":" << all.guard_bytes << "}}\n";
    std::cout << report.str();
    return 0;
  } catch (const std::exception &error) {
    std::cerr << "portable hardware validation failed: " << error.what() << '\n';
    return 1;
  }
}

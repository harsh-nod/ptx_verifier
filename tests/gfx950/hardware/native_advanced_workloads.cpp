// Independent CPU references for exact checked-in gfx950 assembly. No GPU
// kernels are compiled from this driver. Assemble each native-*.s with
// llvm-mc --triple=amdgcn-amd-amdhsa --mcpu=gfx950 -filetype=obj, then link
// its object with ld.lld -shared. Build this driver with:
//   hipcc -O2 -std=c++17 -Wall -Wextra native_advanced_workloads.cpp -o
//   native-advanced
// Run: native-advanced MAMBA.hsaco FORGETTING.hsaco SINKHORN.hsaco SAGE.hsaco
// [patterns] Record fixture/source/object/driver hashes, tools, device and
// complete stdout. All checks select workgroup0; full original
// shapes/reductions are retained. Fixed tolerances below account for physical
// F16 probability/weight rounding and approximate transcendental operations,
// independently of symbolic proofs.

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <hip/hip_runtime.h>
#include <limits>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <vector>

static void check(hipError_t error, const char *operation) {
  if (error != hipSuccess)
    throw std::runtime_error(std::string(operation) + ": " +
                             hipGetErrorString(error));
}
template <class T> struct Buffer {
  std::vector<T> host;
  T *device{};
  explicit Buffer(size_t size) : host(size) {
    check(hipMalloc(&device, size * sizeof(T)), "allocate");
  }
  Buffer(const Buffer &) = delete;
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
    check(hipModuleLoad(&handle, path), "load exact code object");
  }
  ~Module() {
    if (handle)
      (void)hipModuleUnload(handle);
  }
  Module(const Module &) = delete;
  hipFunction_t function(const char *name) const {
    hipFunction_t value{};
    check(hipModuleGetFunction(&value, handle, name), name);
    return value;
  }
};
static void launch(hipFunction_t function, void **args) {
  check(hipModuleLaunchKernel(function, 1, 1, 1, 128, 1, 1, 0, nullptr, args,
                              nullptr),
        "launch workgroup0");
  check(hipDeviceSynchronize(), "synchronize");
}

static uint32_t mix(uint32_t x) {
  x ^= x >> 16;
  x *= 0x7feb352dU;
  x ^= x >> 15;
  x *= 0x846ca68bU;
  return x ^ (x >> 16);
}
static uint32_t coordinate(unsigned row, unsigned column, unsigned seed,
                           uint32_t domain) {
  return mix(domain ^ (row + 1) * 0x9e3779b9U ^ (column + 3) * 0x85ebca6bU ^
             (seed + 7) * 0xc2b2ae35U ^
             (row + 11) * (column + 17) * 0x27d4eb2dU);
}
static float small(unsigned row, unsigned column, unsigned seed,
                   uint32_t domain) {
  return (int(coordinate(row, column, seed, domain) % 15) - 7) / 32.0f;
}
static void fill_half(Buffer<_Float16> &buffer, unsigned pitch, unsigned seed,
                      uint32_t domain) {
  for (size_t i = 0; i < buffer.host.size(); ++i)
    buffer.host[i] =
        (_Float16)small(unsigned(i / pitch), unsigned(i % pitch), seed, domain);
  buffer.upload();
}

constexpr size_t Guard = 64;
template <class T>
using Bits =
    typename std::conditional<sizeof(T) == 2, uint16_t, uint32_t>::type;
template <class T> static Bits<T> raw(T value) {
  Bits<T> bits;
  std::memcpy(&bits, &value, sizeof(T));
  return bits;
}
template <class T> static T sentinel() {
  Bits<T> bits = sizeof(T) == 2 ? 0x7e55U : 0x7fc0a55aU;
  T value;
  std::memcpy(&value, &bits, sizeof(T));
  return value;
}
struct Result {
  size_t outputs{}, guards{};
  double maximum_absolute{}, maximum_relative{};
};
template <class T>
static Result verify_storage(const std::vector<T> &storage,
                             const std::vector<double> &expected, double atol,
                             double rtol, const std::string &label) {
  if (storage.size() != expected.size() + 2 * Guard)
    throw std::runtime_error("checker size mismatch");
  Result result;
  for (size_t i = 0; i < storage.size(); ++i) {
    if (i < Guard || i >= Guard + expected.size()) {
      if (raw(storage[i]) != raw(sentinel<T>()))
        throw std::runtime_error(
            label + " guard overwritten at backing index " + std::to_string(i));
      ++result.guards;
      continue;
    }
    const size_t index = i - Guard;
    const double actual = (double)storage[i], reference = expected[index];
    const double error = std::abs(actual - reference);
    if (!std::isfinite(reference) || !std::isfinite(actual) ||
        error > atol + rtol * std::abs(reference)) {
      char details[300];
      std::snprintf(details, sizeof(details),
                    " index=%zu expected=%.14g actual=%.14g error=%.14g "
                    "atol=%.8g rtol=%.8g",
                    index, reference, actual, error, atol, rtol);
      throw std::runtime_error(label + details);
    }
    result.maximum_absolute = std::max(result.maximum_absolute, error);
    result.maximum_relative = std::max(
        result.maximum_relative, error / std::max(std::abs(reference), 1e-30));
    ++result.outputs;
  }
  return result;
}
template <class T> struct Output {
  Buffer<T> storage;
  T *pointer;
  explicit Output(size_t count)
      : storage(count + 2 * Guard), pointer(storage.device + Guard) {}
  void reset() {
    std::fill(storage.host.begin(), storage.host.end(), sentinel<T>());
    storage.upload();
  }
  Result verify(const std::vector<double> &expected, double atol, double rtol,
                const char *name, unsigned seed) {
    storage.download();
    Result r = verify_storage(storage.host, expected, atol, rtol, name);
    std::printf("PASS %s pattern=%u outputs=%zu guards=%zu max_abs=%.12g "
                "max_rel=%.12g atol=%.8g rtol=%.8g\n",
                name, seed, r.outputs, r.guards, r.maximum_absolute,
                r.maximum_relative, atol, rtol);
    return r;
  }
};
static void add(Result &total, const Result &value) {
  total.outputs += value.outputs;
  total.guards += value.guards;
}

// Ordinary dense stable softmax over a complete key row. No online tile,
// lane mapping, MFMA output index or native LDS staging helper is reused.
static double softmax(const std::vector<double> &scores, bool base2,
                      std::vector<double> &probabilities) {
  double maximum = *std::max_element(scores.begin(), scores.end()), sum = 0;
  probabilities.resize(scores.size());
  for (size_t i = 0; i < scores.size(); ++i) {
    probabilities[i] =
        base2 ? std::exp2(scores[i] - maximum) : std::exp(scores[i] - maximum);
    sum += probabilities[i];
  }
  for (double &value : probabilities)
    value /= sum;
  return maximum + (base2 ? std::log2(sum) : std::log(sum));
}
static void self_test() {
  std::vector<double> p;
  double lse = softmax({0, 0, 0, 0}, false, p);
  if (std::abs(lse - std::log(4.0)) > 1e-14 ||
      p != std::vector<double>(4, 0.25))
    throw std::runtime_error("host softmax anchor failed");
  for (unsigned fault = 0; fault < 3; ++fault) {
    std::vector<float> storage(2 * Guard + 1, sentinel<float>());
    storage[Guard] = 1;
    if (fault == 0)
      storage[Guard] = sentinel<float>();
    if (fault == 1)
      storage[0] = 0;
    if (fault == 2)
      storage.back() = 0;
    bool rejected = false;
    try {
      (void)verify_storage(storage, {1}, 0, 0, "host negative control");
    } catch (const std::runtime_error &) {
      rejected = true;
    }
    if (!rejected)
      throw std::runtime_error("host checker missed corrupted storage");
  }
  std::printf("PASS host dense-softmax anchor and "
              "missing-output/prefix/suffix-guard negative controls\n");
}

static void mamba(const Module &module, unsigned patterns, Result &total) {
  constexpr unsigned Time = 256, Pitch = 512, Rows = 64, Columns = 128;
  Buffer<_Float16> x(Time * Pitch), b(Time * Pitch);
  Buffer<float> dt(Time), da(Time);
  Output<float> output(Rows * Columns);
  auto function = module.function("mamba2_chunk_state_full");
  for (unsigned seed = 0; seed < patterns; ++seed) {
    fill_half(x, Pitch, seed, 0x8d47U);
    fill_half(b, Pitch, seed, 0x9c73U);
    for (unsigned t = 0; t < Time; ++t) {
      dt.host[t] = (16 + coordinate(t, 0, seed, 0x3129U) % 17) / 64.0f;
      da.host[t] = (int(coordinate(t, 0, seed, 0x4319U) % 17) - 8) / 16.0f;
    }
    // Fix the final decay origin; both positive and negative branches occur.
    da.host.back() = 0;
    dt.upload();
    da.upload();
    output.reset();
    std::vector<_Float16> weighted(Time * Columns);
    for (unsigned t = 0; t < Time; ++t) {
      // The native contract rounds the weighted B operand to F16 before GEMM.
      // Natural exp is evaluated independently, without the device exp2 idiom.
      float weight =
          dt.host[t] *
          (float)std::exp(std::min(double(da.host.back()) - da.host[t], 0.0));
      for (unsigned column = 0; column < Columns; ++column)
        weighted[t * Columns + column] =
            (_Float16)((float)b.host[t * Pitch + column] * weight);
    }
    std::vector<double> reference(Rows * Columns, 0);
    for (unsigned row = 0; row < Rows; ++row)
      for (unsigned t = 0; t < Time; ++t)
        for (unsigned column = 0; column < Columns; ++column)
          reference[row * Columns + column] +=
              (double)x.host[t * Pitch + row] *
              (double)weighted[t * Columns + column];
    std::printf("REFERENCE mamba2_chunk_state_full pattern=%u state=64x128 "
                "T=256 input_pitch=512 natural_exp_then_F16_weight\n",
                seed);
    void *args[] = {&x.device, &b.device, &output.pointer, &dt.device,
                    &da.device};
    launch(function, args);
    // Fixed before hardware execution. F16 weighting can differ by one last
    // stored operand bit when approximate exp crosses a halfway boundary.
    add(total, output.verify(reference, 0.0002, 0.002,
                             "mamba2_chunk_state_full", seed));
  }
}

static void forgetting(const Module &module, unsigned patterns, Result &total) {
  constexpr unsigned Queries = 128, Keys = 1024, D = 64;
  Buffer<_Float16> q(Queries * D), k(Keys * D), v(Keys * D);
  Buffer<float> lambda(Keys);
  Output<_Float16> output(Queries * D);
  Output<float> lse(Queries);
  auto function = module.function("forgetting_attention_full");
  for (unsigned seed = 0; seed < patterns; ++seed) {
    fill_half(q, D, seed, 0x514dU);
    fill_half(k, D, seed, 0x27c9U);
    fill_half(v, D, seed, 0x8bd3U);
    for (unsigned key = 0; key < Keys; ++key)
      lambda.host[key] = small(key, 0, seed, 0x623bU);
    lambda.upload();
    output.reset();
    lse.reset();
    std::vector<double> reference(Queries * D, 0), reference_lse(Queries),
        scores(Keys), probabilities;
    for (unsigned row = 0; row < Queries; ++row) {
      for (unsigned key = 0; key < Keys; ++key) {
        double dot = 0;
        for (unsigned d = 0; d < D; ++d)
          dot += (double)q.host[row * D + d] * (double)k.host[key * D + d];
        scores[key] = dot / 8.0 - lambda.host[key];
      }
      reference_lse[row] =
          softmax(scores, false, probabilities) + lambda.host[row];
      for (unsigned d = 0; d < D; ++d)
        for (unsigned key = 0; key < Keys; ++key)
          reference[row * D + d] +=
              probabilities[key] * (double)v.host[key * D + d];
    }
    std::printf("REFERENCE forgetting_attention_full pattern=%u Q=128 T=1024 "
                "D=64 natural_softmax(QK/8-lambda_key),LSE_plus_lambda_query\n",
                seed);
    void *args[] = {&q.device,      &k.device,    &v.device,
                    &lambda.device, &lse.pointer, &output.pointer};
    launch(function, args);
    add(total, output.verify(reference, 0.00008, 0.002,
                             "forgetting_attention_full.Out", seed));
    add(total, lse.verify(reference_lse, 0.00002, 0,
                          "forgetting_attention_full.LSE", seed));
  }
}

static void sinkhorn(const Module &module, unsigned patterns, Result &total) {
  constexpr unsigned Rows = 32, Keys = 1024, D = 64;
  Buffer<_Float16> x(Rows * D), y(Keys * D);
  Buffer<float> f(Rows), g(Keys), log_b(Keys);
  Output<float> output(Rows);
  auto function = module.function("flash_sinkhorn_full");
  for (unsigned seed = 0; seed < patterns; ++seed) {
    fill_half(x, D, seed, 0x7fd1U);
    fill_half(y, D, seed, 0x03e5U);
    for (unsigned row = 0; row < Rows; ++row)
      f.host[row] = small(row, 0, seed, 0x0bacU);
    for (unsigned key = 0; key < Keys; ++key) {
      g.host[key] = small(key, 0, seed, 0x432dU);
      log_b.host[key] = small(key, 0, seed, 0x31e7U);
    }
    f.upload();
    g.upload();
    log_b.upload();
    output.reset();
    std::vector<double> reference(Rows), scores(Keys), probabilities;
    for (unsigned row = 0; row < Rows; ++row) {
      for (unsigned key = 0; key < Keys; ++key) {
        double dot = 0;
        for (unsigned d = 0; d < D; ++d)
          dot += (double)x.host[row * D + d] * (double)y.host[key * D + d];
        scores[key] = 2.0 * dot + g.host[key] + log_b.host[key];
      }
      reference[row] =
          0.5 * (f.host[row] - softmax(scores, false, probabilities));
    }
    std::printf("REFERENCE flash_sinkhorn_full pattern=%u rows=32 T=1024 D=64 "
                "f_update=0.5*(fhat-logsumexp(2XY+ghat+logb))\n",
                seed);
    float *null_pointer = nullptr;
    void *args[] = {&x.device,       &y.device,     &f.device,
                    &g.device,       &null_pointer, &log_b.device,
                    &output.pointer, &null_pointer};
    launch(function, args);
    add(total, output.verify(reference, 0.00002, 0.000002,
                             "flash_sinkhorn_full", seed));
  }
}

static void sage(const Module &module, unsigned patterns, Result &total) {
  constexpr unsigned Queries = 128, Keys = 128, D = 64;
  Buffer<int8_t> q(Queries * D), k(Keys * D);
  Buffer<_Float16> v(Keys * D);
  Buffer<float> qscale(1), kscale(2);
  Output<_Float16> output(Queries * D);
  auto function = module.function("sage_attention_full");
  for (unsigned seed = 0; seed < patterns; ++seed) {
    for (unsigned row = 0; row < Queries; ++row)
      for (unsigned d = 0; d < D; ++d)
        q.host[row * D + d] =
            int8_t(int(coordinate(row, d, seed, 0x341bU) & 255) - 128);
    for (unsigned key = 0; key < Keys; ++key)
      for (unsigned d = 0; d < D; ++d)
        k.host[key * D + d] =
            int8_t(int(coordinate(key, d, seed, 0x9d71U) & 255) - 128);
    if (*std::min_element(q.host.begin(), q.host.end()) != -128 ||
        *std::max_element(q.host.begin(), q.host.end()) != 127 ||
        *std::min_element(k.host.begin(), k.host.end()) != -128 ||
        *std::max_element(k.host.begin(), k.host.end()) != 127)
      throw std::runtime_error(
          "signed-I8 pattern does not span full numeric range");
    q.upload();
    k.upload();
    fill_half(v, D, seed, 0x62d5U);
    qscale.host[0] = 1.0f / float(128 + (seed % 2) * 128);
    kscale.host[0] = float(1 + (seed % 3)) / 512.0f;
    kscale.host[1] = float(5 + (seed % 3)) / 2048.0f;
    qscale.upload();
    kscale.upload();
    output.reset();
    std::vector<double> reference(Queries * D, 0), scores(Keys), probabilities;
    for (unsigned row = 0; row < Queries; ++row) {
      for (unsigned key = 0; key < Keys; ++key) {
        int32_t dot = 0;
        for (unsigned d = 0; d < D; ++d)
          dot += int32_t(q.host[row * D + d]) * int32_t(k.host[key * D + d]);
        scores[key] = double(dot) * qscale.host[0] * kscale.host[key / 64];
      }
      (void)softmax(scores, true, probabilities);
      for (unsigned d = 0; d < D; ++d)
        for (unsigned key = 0; key < Keys; ++key)
          reference[row * D + d] +=
              probabilities[key] * (double)v.host[key * D + d];
    }
    std::printf("REFERENCE sage_attention_full pattern=%u Q=128 T=128 D=64 "
                "signed_I8_range=-128..127 base2_softmax qscale=%.12g "
                "kscale0=%.12g kscale1=%.12g\n",
                seed, qscale.host[0], kscale.host[0], kscale.host[1]);
    void *args[] = {&q.device,      &k.device,      &v.device,
                    &qscale.device, &kscale.device, &output.pointer};
    launch(function, args);
    add(total,
        output.verify(reference, 0.00008, 0.002, "sage_attention_full", seed));
  }
}

int main(int argc, char **argv) {
  try {
    if (argc == 2 && std::string(argv[1]) == "--self-test") {
      self_test();
      return 0;
    }
    if (argc != 5 && argc != 6)
      throw std::runtime_error(
          "usage: native-advanced MAMBA.hsaco FORGETTING.hsaco SINKHORN.hsaco "
          "SAGE.hsaco [patterns>=3]");
    unsigned patterns = 3;
    if (argc == 6) {
      char *end{};
      long count = std::strtol(argv[5], &end, 10);
      if (!end || *end || count < 3 || count > 17)
        throw std::runtime_error("patterns must be an integer from3 to17");
      patterns = unsigned(count);
    }
    self_test();
    hipDeviceProp_t device{};
    check(hipGetDeviceProperties(&device, 0), "device properties");
    if (std::string(device.gcnArchName).find("gfx950") != 0 ||
        device.warpSize != 64)
      throw std::runtime_error("actual gfx950 wave64 hardware is required");
    int runtime{}, driver{};
    check(hipRuntimeGetVersion(&runtime), "runtime version");
    check(hipDriverGetVersion(&driver), "driver version");
    std::printf("DEVICE name=%s arch=%s wave=%d runtime=%d driver=%d "
                "selected_workgroup=0,0,0 patterns=%u\n",
                device.name, device.gcnArchName, device.warpSize, runtime,
                driver, patterns);
    std::printf("CODE_OBJECT mamba=%s forgetting=%s sinkhorn=%s sage=%s\n",
                argv[1], argv[2], argv[3], argv[4]);
    Module m(argv[1]), f(argv[2]), h(argv[3]), s(argv[4]);
    Result total;
    mamba(m, patterns, total);
    forgetting(f, patterns, total);
    sinkhorn(h, patterns, total);
    sage(s, patterns, total);
    std::printf("PASS all4 full advanced native workloads patterns=%u "
                "output_checks=%zu guard_checks=%zu\n",
                patterns, total.outputs, total.guards);
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "FAIL %s\n", error.what());
    return 1;
  }
}

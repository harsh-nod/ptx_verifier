// Host-only validation of exact, checked-in gfx1250 assembly code objects.
// No GPU C++ source is compiled by this driver. CPU references use logical
// matrices, with native fragment packing confined to the input/output ABI.
#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <hip/hip_runtime.h>
#include <iomanip>
#include <iostream>
#include <limits>
#include <sstream>
#include <stdexcept>
#include <string>
#include <thread>
#include <type_traits>
#include <utility>
#include <vector>

namespace {
struct Counts {
  uint64_t launches = 0, outputs = 0, output_guard_bytes = 0, unchanged_input_bytes = 0,
           host_argument_bytes = 0;
  double max_abs = 0, max_rel = 0;
} counts;
constexpr size_t GuardBytes = 256;
constexpr double LaunchTimeoutSeconds = 10;
void hip_check(hipError_t status, const char *operation) {
  if (status != hipSuccess)
    throw std::runtime_error(std::string(operation) + ": " + hipGetErrorString(status));
}
void cleanup_check(hipError_t status, const char *operation) noexcept {
  if (status != hipSuccess) {
    std::fprintf(stderr, "FATAL HIP cleanup error at %s: %s; no reset attempted\n", operation,
                 hipGetErrorString(status));
    std::fflush(nullptr);
    std::_Exit(2);
  }
}
std::string json_string(const std::string &value) {
  std::ostringstream result;
  result << '"';
  for (unsigned char ch : value) {
    if (ch == '"' || ch == '\\')
      result << '\\' << ch;
    else if (ch < 32)
      result << "\\u" << std::hex << std::setfill('0') << std::setw(4) << unsigned(ch) << std::dec;
    else
      result << ch;
  }
  result << '"';
  return result.str();
}
void launch(hipFunction_t f, dim3 grid, dim3 block, void **args) {
  hip_check(hipModuleLaunchKernel(f, grid.x, grid.y, grid.z, block.x, block.y, block.z, 0, nullptr,
                                  args, nullptr),
            "hipModuleLaunchKernel");
  auto deadline =
      std::chrono::steady_clock::now() + std::chrono::duration<double>(LaunchTimeoutSeconds);
  for (;;) {
    auto status = hipStreamQuery(nullptr);
    if (status == hipSuccess)
      break;
    if (status != hipErrorNotReady) {
      std::fprintf(stderr, "FATAL asynchronous HIP error: %s; no reset attempted\n",
                   hipGetErrorString(status));
      std::fflush(nullptr);
      std::_Exit(2);
    }
    if (std::chrono::steady_clock::now() > deadline) {
      std::fprintf(stderr, "FATAL positive-kernel timeout; no reset attempted\n");
      std::fflush(nullptr);
      std::_Exit(2);
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
  ++counts.launches;
}
struct Module {
  hipModule_t handle{};
  explicit Module(const std::string &file) {
    hip_check(hipModuleLoad(&handle, file.c_str()), "hipModuleLoad exact code object");
  }
  ~Module() {
    if (handle)
      cleanup_check(hipModuleUnload(handle), "hipModuleUnload");
  }
  Module(const Module &) = delete;
  Module &operator=(const Module &) = delete;
  hipFunction_t function(const char *name) {
    hipFunction_t f{};
    hip_check(hipModuleGetFunction(&f, handle, name), name);
    return f;
  }
};
void check_float(double actual, double expected, double atol, double rtol,
                 const std::string &context) {
  if (!std::isfinite(actual) || !std::isfinite(expected) ||
      std::abs(actual - expected) > atol + rtol * std::abs(expected)) {
    std::ostringstream message;
    message << std::setprecision(17) << context << ": expected=" << expected << " actual=" << actual
            << " atol=" << atol << " rtol=" << rtol;
    throw std::runtime_error(message.str());
  }
}
void check_canaries(const void *data, size_t bytes, size_t payload_bytes,
                    const std::string &context) {
  if (bytes != payload_bytes + 2 * GuardBytes)
    throw std::runtime_error("invalid guarded allocation size");
  const auto *raw = static_cast<const unsigned char *>(data);
  for (size_t i = 0; i < bytes; ++i)
    if ((i < GuardBytes || i >= GuardBytes + payload_bytes) && raw[i] != 0xa5)
      throw std::runtime_error(context + ": output canary overwritten");
}
void check_unchanged(const void *current, const void *before, size_t bytes,
                     const std::string &context) {
  if (std::memcmp(current, before, bytes))
    throw std::runtime_error(context + ": input or input canary modified");
}
template <class T> struct Buffer {
  static constexpr size_t G = GuardBytes / sizeof(T);
  std::vector<T> host;
  T *allocation{};
  T *device{};
  size_t length;
  explicit Buffer(size_t n) : host(n + 2 * G), length(n) {
    hip_check(hipMalloc(&allocation, host.size() * sizeof(T)), "hipMalloc guarded buffer");
    device = allocation + G;
    reset();
  }
  ~Buffer() {
    if (allocation)
      cleanup_check(hipFree(allocation), "hipFree");
  }
  Buffer(const Buffer &) = delete;
  Buffer &operator=(const Buffer &) = delete;
  T &at(size_t i) { return host.at(G + i); }
  const T &at(size_t i) const { return host.at(G + i); }
  void reset() { std::memset(host.data(), 0xa5, host.size() * sizeof(T)); }
  void upload() {
    hip_check(hipMemcpy(allocation, host.data(), host.size() * sizeof(T), hipMemcpyHostToDevice),
              "upload guarded buffer");
  }
  void download() {
    hip_check(hipMemcpy(host.data(), allocation, host.size() * sizeof(T), hipMemcpyDeviceToHost),
              "download guarded buffer");
  }
  void unchanged(const std::vector<T> &before, const std::string &context) {
    download();
    if (host.size() != before.size())
      throw std::runtime_error("snapshot length mismatch");
    check_unchanged(host.data(), before.data(), host.size() * sizeof(T), context);
    counts.unchanged_input_bytes += host.size() * sizeof(T);
  }
  template <class E> void prepare(const std::vector<E> &expected) {
    if (expected.size() != length)
      throw std::runtime_error("poison/reference length mismatch");
    reset();
    for (size_t i = 0; i < length; ++i) {
      if constexpr (std::is_floating_point_v<T>)
        at(i) = std::numeric_limits<T>::quiet_NaN();
      else
        at(i) = T(~T(expected[i]));
    }
    upload();
  }
  void guards(const std::string &context) {
    check_canaries(host.data(), host.size() * sizeof(T), length * sizeof(T), context);
    counts.output_guard_bytes += 2 * GuardBytes;
  }
  void floats(const std::vector<double> &expected, const std::string &context, double atol = 0,
              double rtol = 0) {
    if (expected.size() != length)
      throw std::runtime_error(context + ": reference length mismatch");
    download();
    guards(context);
    for (size_t i = 0; i < length; ++i) {
      double actual = double(at(i)), want = expected[i];
      double error = std::abs(actual - want);
      check_float(actual, want, atol, rtol, context + ": output " + std::to_string(i));
      counts.max_abs = std::max(counts.max_abs, error);
      if (want != 0)
        counts.max_rel = std::max(counts.max_rel, error / std::abs(want));
      ++counts.outputs;
    }
  }
  void exact(const std::vector<T> &expected, const std::string &context) {
    if (expected.size() != length)
      throw std::runtime_error(context + ": reference length mismatch");
    download();
    guards(context);
    for (size_t i = 0; i < length; ++i) {
      if (at(i) != expected[i])
        throw std::runtime_error(context + ": bit-exact output mismatch at " + std::to_string(i));
      ++counts.outputs;
    }
  }
};
float pattern(unsigned row, unsigned col, unsigned seed) {
  return float(int((row * 13 + col * 7 + seed * 11) % 31) - 15) * 0.125f;
}
uint32_t f32_bits(float value) {
  uint32_t bits;
  std::memcpy(&bits, &value, 4);
  return bits;
}
float bits_f32(uint32_t bits) {
  float value;
  std::memcpy(&value, &bits, 4);
  return value;
}
uint16_t half_bits(float x) { // Independent IEEE binary16 round-to-nearest-even.
  uint32_t b = f32_bits(x), sign = (b >> 16) & 0x8000, exponent = (b >> 23) & 255,
           frac = b & 0x7fffff;
  if (exponent == 255)
    return uint16_t(sign | 0x7c00 | (frac ? 0x200 : 0));
  int e = int(exponent) - 127 + 15;
  if (e >= 31)
    return uint16_t(sign | 0x7c00);
  uint32_t mantissa = frac | 0x800000;
  if (e <= 0) {
    if (e < -10)
      return uint16_t(sign);
    unsigned shift = unsigned(14 - e);
    uint32_t value = mantissa >> shift, rest = mantissa & ((1u << shift) - 1),
             half = 1u << (shift - 1);
    return uint16_t(sign + value + (rest > half || (rest == half && (value & 1))));
  }
  uint32_t value = frac >> 13, rest = frac & 8191;
  value += rest > 4096 || (rest == 4096 && (value & 1));
  return uint16_t(sign + (unsigned(e) << 10) + value);
}
double half_value(uint16_t bits) {
  unsigned sign = bits >> 15, e = (bits >> 10) & 31, m = bits & 1023;
  double value = e == 0    ? std::ldexp(double(m), -24)
                 : e == 31 ? (m ? std::numeric_limits<double>::quiet_NaN()
                                : std::numeric_limits<double>::infinity())
                           : std::ldexp(1 + double(m) / 1024, int(e) - 15);
  return sign ? -value : value;
}
uint16_t bf16_bits(float x) {
  uint32_t b = f32_bits(x);
  return uint16_t((b + 0x7fff + ((b >> 16) & 1)) >> 16);
}
double bf16_value(uint16_t bits) { return double(bits_f32(uint32_t(bits) << 16)); }

void copy_add(const std::string &dir) {
  Module m(dir + "/native-copy-add.hsaco");
  for (unsigned block : {1u, 31u, 32u, 33u, 63u, 64u, 65u, 96u, 128u, 256u})
    for (unsigned n : {1u, 31u, 32u, 33u, 63u, 64u, 65u, 129u, 257u})
      for (unsigned seed = 0; seed < 3; ++seed) {
        Buffer<float> x(n), y(n), out(n);
        for (unsigned i = 0; i < n; ++i) {
          x.at(i) = pattern(i, 0, seed);
          y.at(i) = pattern(i, 3, seed + 1);
        }
        auto xb = x.host, yb = y.host;
        x.upload();
        y.upload();
        for (bool add : {false, true}) {
          std::vector<double> expected(n);
          for (unsigned i = 0; i < n; ++i)
            expected[i] = add ? double(x.at(i)) + y.at(i) : x.at(i);
          out.prepare(expected);
          void *a[] = {&x.device, &out.device, &n};
          void *b[] = {&x.device, &y.device, &out.device, &n};
          launch(m.function(add ? "add" : "copy"), dim3((n + block - 1) / block), dim3(block),
                 add ? b : a);
          out.floats(expected, add ? "add" : "copy");
          x.unchanged(xb, "copy/add x");
          if (add)
            y.unchanged(yb, "add y");
        }
      }
}
void lds_ids(const std::string &dir) {
  Module m(dir + "/native-lds-ids.hsaco");
  for (unsigned seed = 0; seed < 17; ++seed) {
    Buffer<float> x(64), out(64), sum(2), ids(24);
    for (unsigned i = 0; i < 64; ++i)
      x.at(i) = pattern(i, 4, seed);
    auto xb = x.host;
    x.upload();
    std::vector<double> exchange(64), reduction(2), coordinates(24);
    for (unsigned i = 0; i < 64; ++i) {
      exchange[i] = x.at(i ^ 32);
      reduction[i / 32] += x.at(i);
    }
    for (unsigned z = 0; z < 2; ++z)
      for (unsigned y = 0; y < 3; ++y)
        for (unsigned xx = 0; xx < 4; ++xx)
          coordinates[xx + 4 * (y + 3 * z)] = xx + 10 * y + 100 * z;
    out.prepare(exchange);
    void *a[] = {&x.device, &out.device};
    launch(m.function("exchange"), dim3(1), dim3(64), a);
    out.floats(exchange, "cross-wave LDS exchange");
    x.unchanged(xb, "exchange input");
    sum.prepare(reduction);
    void *b[] = {&x.device, &sum.device};
    launch(m.function("reduce"), dim3(1), dim3(64), b);
    sum.floats(reduction, "wave32 reductions");
    x.unchanged(xb, "reduce input");
    ids.prepare(coordinates);
    void *c[] = {&ids.device};
    launch(m.function("ids_3d"), dim3(1), dim3(4, 3, 2), c);
    ids.floats(coordinates, "packed XYZ IDs");
  }
}
// CPU reference is a row-major dot product. Only packing/unpacking below follows
// the native fragment ABI; it does not execute an instruction-level oracle.
void wmma(const std::string &dir, const std::string &kind) {
  Module m(dir + "/native-wmma.hsaco");
  bool f32 = kind == "f32", bf = kind == "bf16";
  unsigned depth = f32 ? 4 : 32, items = depth / 2;
  for (unsigned seed = 0; seed < 17; ++seed) {
    std::vector<double> a(16 * depth), b(16 * depth), expected(256);
    for (unsigned row = 0; row < 16; ++row)
      for (unsigned k = 0; k < depth; ++k) {
        a[row * depth + k] = pattern(row, k, seed);
        b[row * depth + k] = pattern(k, row, seed + 7);
      }
    Buffer<float> out(256);
    auto expected_product = [&] {
      for (unsigned row = 0; row < 16; ++row)
        for (unsigned col = 0; col < 16; ++col) {
          double sum = 0;
          for (unsigned k = 0; k < depth; ++k)
            sum += a[row * depth + k] * b[col * depth + k];
          unsigned lane = (row / 8) * 16 + col, component = row % 8;
          expected[lane * 8 + component] = sum;
        }
    };
    if (f32) {
      Buffer<float> av(64), bv(64);
      for (unsigned row = 0; row < 16; ++row)
        for (unsigned k = 0; k < depth; ++k) {
          unsigned lane = row + (k / 2) * 16, v = k % 2;
          av.at(lane * items + v) = float(a[row * depth + k]);
          bv.at(lane * items + v) = float(b[row * depth + k]);
        }
      auto a_before = av.host, b_before = bv.host;
      av.upload();
      bv.upload();
      expected_product();
      out.prepare(expected);
      void *args[] = {&av.device, &bv.device, &out.device};
      launch(m.function("wmma_f32"), dim3(1), dim3(32), args);
      out.floats(expected, "wmma_f32 dense");
      av.unchanged(a_before, "wmma_f32 A");
      bv.unchanged(b_before, "wmma_f32 B");
    } else {
      Buffer<uint16_t> av(512), bv(512);
      for (unsigned row = 0; row < 16; ++row)
        for (unsigned k = 0; k < depth; ++k) {
          unsigned lane = row + ((k / 8) % 2) * 16, v = (k / 16) * 8 + k % 8;
          uint16_t a_bits = bf ? bf16_bits(float(a[row * depth + k]))
                               : half_bits(float(a[row * depth + k])),
                   b_bits = bf ? bf16_bits(float(b[row * depth + k]))
                               : half_bits(float(b[row * depth + k]));
          av.at(lane * items + v) = a_bits;
          bv.at(lane * items + v) = b_bits;
          a[row * depth + k] = bf ? bf16_value(a_bits) : half_value(a_bits);
          b[row * depth + k] = bf ? bf16_value(b_bits) : half_value(b_bits);
        }
      auto a_before = av.host, b_before = bv.host;
      av.upload();
      bv.upload();
      expected_product();
      out.prepare(expected);
      void *args[] = {&av.device, &bv.device, &out.device};
      launch(m.function(bf ? "wmma_bf16" : "wmma_f16"), dim3(1), dim3(32), args);
      out.floats(expected, "wmma_" + kind + " dense");
      av.unchanged(a_before, "WMMA16 A");
      bv.unchanged(b_before, "WMMA16 B");
    }
  }
}
void basis(const std::string &dir) {
  Module m(dir + "/native-wmma-basis.hsaco");
  Buffer<float> out(256);
  for (const auto &pair : std::vector<std::pair<std::string, unsigned>>{
           {"wmma_f32_basis", 4}, {"wmma_f16_basis", 32}, {"wmma_bf16_basis", 32}})
    for (unsigned side = 0; side < 2; ++side)
      for (unsigned selected = 0; selected < 16; ++selected)
        for (unsigned k = 0; k < pair.second; ++k) {
          std::vector<double> expected(256);
          for (unsigned row = 0; row < 16; ++row)
            for (unsigned col = 0; col < 16; ++col)
              expected[((row / 8) * 16 + col) * 8 + row % 8] =
                  double((side ? col : row) == selected);
          out.prepare(expected);
          void *args[] = {&out.device, &selected, &k, &side};
          launch(m.function(pair.first.c_str()), dim3(1), dim3(32), args);
          out.floats(expected, pair.first);
        }
}
void values(const std::string &dir) {
  Module m(dir + "/native-wmma-values.hsaco");
  Buffer<float> out(256);
  for (unsigned seed = 0; seed < 17; ++seed) {
    alignas(32) std::array<float, 2> a{}, b{};
    for (unsigned i = 0; i < 2; ++i) {
      a[i] = seed == 0 ? (i ? -1.0f : 0.5f) : pattern(i, 1, seed);
      b[i] = seed == 0 ? (i ? 4.0f : 2.0f) : pattern(i, 3, seed + 1);
    }
    auto a_before = a, b_before = b;
    double sum = 2 * (double(a[0]) * b[0] + double(a[1]) * b[1]);
    std::vector<double> expected(256, sum);
    out.prepare(expected);
    void *args[] = {a.data(), b.data(), &out.device};
    launch(m.function("wmma_f32_values"), dim3(1), dim3(32), args);
    out.floats(expected, "wmma_f32 raw byvalue");
    if (a != a_before || b != b_before)
      throw std::runtime_error("host F32 vector argument modified");
    counts.host_argument_bytes += sizeof(a) + sizeof(b);
    for (bool bf : {false, true}) {
      alignas(32) std::array<uint16_t, 16> av{}, bv{};
      double total = 0;
      for (unsigned i = 0; i < 16; ++i) {
        float va = seed == 0 ? 1.0f : pattern(i, 1, seed),
              vb = seed == 0 ? 2.0f : pattern(i, 3, seed + 1);
        av[i] = bf ? bf16_bits(va) : half_bits(va);
        bv[i] = bf ? bf16_bits(vb) : half_bits(vb);
        total += 2 * (bf ? bf16_value(av[i]) : half_value(av[i])) *
                 (bf ? bf16_value(bv[i]) : half_value(bv[i]));
      }
      auto a_before = av, b_before = bv;
      expected.assign(256, total);
      out.prepare(expected);
      void *p[] = {av.data(), bv.data(), &out.device};
      launch(m.function(bf ? "wmma_bf16_values" : "wmma_f16_values"), dim3(1), dim3(32), p);
      out.floats(expected, bf ? "BF16 raw byvalue" : "F16 raw byvalue");
      if (av != a_before || bv != b_before)
        throw std::runtime_error("host vector argument modified");
      counts.host_argument_bytes += sizeof(av) + sizeof(bv);
    }
  }
}
void gemm(const std::string &dir) {
  Module m(dir + "/native-gemm-pipeline.hsaco");
  for (unsigned seed = 0; seed < 17; ++seed) {
    Buffer<uint16_t> a(32 * 64), b(16 * 64);
    Buffer<float> out(512);
    for (unsigned row = 0; row < 32; ++row)
      for (unsigned k = 0; k < 64; ++k)
        a.at(row * 64 + k) = half_bits(pattern(row, k, seed));
    for (unsigned col = 0; col < 16; ++col)
      for (unsigned k = 0; k < 64; ++k)
        b.at(col * 64 + k) = half_bits(pattern(k, col, seed + 9));
    std::vector<double> expected(512);
    for (unsigned row = 0; row < 32; ++row)
      for (unsigned col = 0; col < 16; ++col)
        for (unsigned k = 0; k < 64; ++k)
          expected[row * 16 + col] +=
              half_value(a.at(row * 64 + k)) * half_value(b.at(col * 64 + k));
    auto a_before = a.host, b_before = b.host;
    a.upload();
    b.upload();
    out.prepare(expected);
    void *args[] = {&a.device, &b.device, &out.device};
    launch(m.function("gemm_pipeline_f16"), dim3(1), dim3(64), args);
    out.floats(expected, "two-wave two-stage K64 GEMM");
    a.unchanged(a_before, "pipeline A");
    b.unchanged(b_before, "pipeline B");
  }
}
void tensor(const std::string &dir) {
  Module m(dir + "/native-tensor-roundtrip.hsaco");
  for (unsigned seed = 0; seed < 17; ++seed) {
    Buffer<float> x(128), out(128);
    std::vector<double> expected(128);
    for (unsigned i = 0; i < 128; ++i) {
      x.at(i) = pattern(i, 4, seed);
      expected[i] = double(x.at(i)) + 1;
    }
    auto before = x.host;
    x.upload();
    out.prepare(expected);
    void *args[] = {&x.device, &out.device};
    launch(m.function("tensor_roundtrip"), dim3(1), dim3(64), args);
    out.floats(expected, "two-stage tensor load/store/reuse");
    x.unchanged(before, "tensor input");
  }
}
void attention(const std::string &dir) {
  Module m(dir + "/native-attention-small.hsaco");
  for (unsigned seed = 0; seed < 9; ++seed) {
    Buffer<float> q(512), k(1024), v(1024), out(512);
    for (unsigned r = 0; r < 16; ++r)
      for (unsigned d = 0; d < 32; ++d)
        q.at(r * 32 + d) = pattern(r, d, seed) * 0.25f;
    for (unsigned r = 0; r < 32; ++r)
      for (unsigned d = 0; d < 32; ++d) {
        k.at(r * 32 + d) = pattern(r, d, seed + 4) * 0.25f;
        v.at(r * 32 + d) = pattern(r, d, seed + 9);
      }
    std::vector<double> expected(512);
    for (unsigned row = 0; row < 16; ++row) {
      std::array<double, 32> p{};
      double denominator = 0;
      for (unsigned key = 0; key < 32; ++key) {
        double score = 0;
        for (unsigned d = 0; d < 32; ++d)
          score += double(q.at(row * 32 + d)) * k.at(key * 32 + d);
        p[key] = std::exp(score / 8);
        denominator += p[key];
      }
      for (unsigned d = 0; d < 32; ++d)
        for (unsigned key = 0; key < 32; ++key)
          expected[row * 32 + d] += p[key] / denominator * v.at(key * 32 + d);
    }
    auto qa = q.host, ka = k.host, va = v.host;
    q.upload();
    k.upload();
    v.upload();
    out.prepare(expected);
    void *args[] = {&q.device, &k.device, &v.device, &out.device};
    launch(m.function("attention_small"), dim3(1), dim3(32), args);
    out.floats(expected, "attention Q16 T32 D32", 1e-5, 1e-4);
    q.unchanged(qa, "attention Q");
    k.unchanged(ka, "attention K");
    v.unchanged(va, "attention V");
  }
}
void transpose(const std::string &dir) {
  Module m(dir + "/native-transpose-high64.hsaco");
  for (unsigned seed = 0; seed < 17; ++seed) {
    Buffer<uint16_t> x(64), out(64);
    for (unsigned i = 0; i < 64; ++i)
      x.at(i) = uint16_t(i * 7919 + seed * 1237);
    std::vector<uint16_t> expected(64);
    for (unsigned row = 0; row < 8; ++row)
      for (unsigned col = 0; col < 8; ++col)
        expected[row * 8 + col] = x.at(col * 8 + row);
    auto before = x.host;
    x.upload();
    out.prepare(expected);
    void *args[] = {&x.device, &out.device};
    launch(m.function("transpose_8x8_b16"), dim3(1), dim3(32), args);
    out.exact(expected, "all64 raw16 transpose elements");
    x.unchanged(before, "transpose input");
  }
}
// The host compiler's full 128-bit arithmetic is independent of the emitted
// GPU 32-bit carry/limb sequence. Signed addition sign-extends c.
void wide(const std::string &dir) {
  Module m(dir + "/native-transpose-high64.hsaco");
  const uint64_t words[] = {0,
                            1,
                            UINT64_C(0xffffffff),
                            UINT64_C(0x100000000),
                            UINT64_C(0x7fffffffffffffff),
                            UINT64_C(0x8000000000000000),
                            UINT64_MAX};
  Buffer<uint64_t> out(4);
  for (bool signed_math : {false, true})
    for (uint64_t a : words)
      for (uint64_t b : words)
        for (uint64_t c : words) {
          unsigned __int128 product, added;
          if (signed_math) {
            __int128 signed_a = static_cast<__int128>(static_cast<int64_t>(a)),
                     signed_b = static_cast<__int128>(static_cast<int64_t>(b));
            __int128 p = signed_a * signed_b;
            product = static_cast<unsigned __int128>(p);
            added =
                static_cast<unsigned __int128>(p + static_cast<__int128>(static_cast<int64_t>(c)));
          } else {
            product = static_cast<unsigned __int128>(a) * b;
            added = product + c;
          }
          std::vector<uint64_t> expected = {uint64_t(product >> 64), uint64_t(product),
                                            uint64_t(added >> 64), uint64_t(added)};
          out.prepare(expected);
          void *args[] = {&a, &b, &c, &out.device};
          launch(m.function(signed_math ? "high64_signed_mul_mad" : "high64_mul_mad"), dim3(1),
                 dim3(1), args);
          out.exact(expected, signed_math ? "signed128 product/mad" : "unsigned128 product/mad");
        }
}
void selftest() {
  unsigned negative_controls = 0;
  auto rejects = [&](auto operation) {
    try {
      operation();
    } catch (const std::runtime_error &) {
      ++negative_controls;
      return;
    }
    throw std::runtime_error("checker accepted deliberately invalid host data");
  };
  check_float(1, 1, 0, 0, "selftest exact");
  check_float(1.00001, 1, 0.0001, 0, "selftest tolerance");
  rejects([&] { check_float(2, 1, 0, 0, "wrong result"); });
  rejects([&] {
    check_float(std::numeric_limits<double>::quiet_NaN(), 0, 0, 0, "missing write poison");
  });
  rejects([&] { check_float(1.01, 1, 0.0001, 0, "beyond tolerance"); });
  std::vector<unsigned char> data(2 * GuardBytes + 16, 0xa5), before = data;
  check_canaries(data.data(), data.size(), 16, "selftest guards");
  data[0] = 0;
  rejects([&] { check_canaries(data.data(), data.size(), 16, "prefix corruption"); });
  data = before;
  data.back() = 0;
  rejects([&] { check_canaries(data.data(), data.size(), 16, "suffix corruption"); });
  data = before;
  check_unchanged(data.data(), before.data(), data.size(), "selftest unchanged");
  data[GuardBytes] = 0;
  rejects([&] {
    check_unchanged(data.data(), before.data(), data.size(), "input payload corruption");
  });
  data = before;
  data.back() = 0;
  rejects(
      [&] { check_unchanged(data.data(), before.data(), data.size(), "input guard corruption"); });
  if (half_bits(1.0f) != 0x3c00 || half_value(0xc000) != -2 ||
      half_bits(std::ldexp(1.0f, -24)) != 1 || half_value(1) != std::ldexp(1.0, -24) ||
      bf16_bits(1) != 0x3f80 || bf16_value(0x4000) != 2)
    throw std::runtime_error("host 16-bit conversion anchors failed");
  std::cout << "SELFTEST {\"status\":\"PASS\",\"negative_controls\":" << negative_controls
            << ",\"kernel_launches\":0}\n";
}
void identity() {
  hip_check(hipSetDevice(0), "hipSetDevice visible ordinal zero");
  hipDeviceProp_t p{};
  hip_check(hipGetDeviceProperties(&p, 0), "hipGetDeviceProperties");
  std::string arch = p.gcnArchName;
  if (arch.substr(0, arch.find(':')) != "gfx1250" || p.warpSize != 32)
    throw std::runtime_error("requires actual gfx1250 wave32 device");
  int runtime = 0, driver = 0;
  hip_check(hipRuntimeGetVersion(&runtime), "HIP runtime version");
  hip_check(hipDriverGetVersion(&driver), "HIP driver version");
  std::cout << "IDENTITY {\"name\":" << json_string(p.name)
            << ",\"target\":" << json_string(p.gcnArchName) << ",\"wave_size\":" << p.warpSize
            << ",\"compute_units\":" << p.multiProcessorCount
            << ",\"global_memory_bytes\":" << p.totalGlobalMem
            << ",\"shared_memory_per_block\":" << p.sharedMemPerBlock
            << ",\"pci_domain\":" << p.pciDomainID << ",\"pci_bus\":" << p.pciBusID
            << ",\"pci_device\":" << p.pciDeviceID << ",\"runtime_version\":" << runtime
            << ",\"driver_version\":" << driver << "}\n";
}
} // namespace
int main(int argc, char **argv) {
  try {
    if (argc != 3)
      throw std::runtime_error("usage: core CODE_OBJECT_DIRECTORY SUITE|identity");
    std::string suite = argv[2], dir = argv[1];
    if (suite == "selftest") {
      selftest();
      return 0;
    }
    identity();
    if (suite == "identity")
      return 0;
    if (suite == "copy")
      copy_add(dir);
    else if (suite == "lds")
      lds_ids(dir);
    else if (suite == "wmma_f32")
      wmma(dir, "f32");
    else if (suite == "wmma_f16")
      wmma(dir, "f16");
    else if (suite == "wmma_bf16")
      wmma(dir, "bf16");
    else if (suite == "basis")
      basis(dir);
    else if (suite == "values")
      values(dir);
    else if (suite == "gemm")
      gemm(dir);
    else if (suite == "tensor")
      tensor(dir);
    else if (suite == "attention")
      attention(dir);
    else if (suite == "transpose")
      transpose(dir);
    else if (suite == "wide")
      wide(dir);
    else
      throw std::runtime_error("unknown safe suite " + suite);
    std::cout << std::setprecision(17) << "RESULT {\"suite\":" << json_string(suite)
              << ",\"status\":\"PASS\",\"launches\":" << counts.launches
              << ",\"output_checks\":" << counts.outputs
              << ",\"output_guard_bytes\":" << counts.output_guard_bytes
              << ",\"unchanged_input_bytes_including_guards\":" << counts.unchanged_input_bytes
              << ",\"host_argument_bytes\":" << counts.host_argument_bytes
              << ",\"max_absolute_error\":" << counts.max_abs
              << ",\"max_relative_error\":" << counts.max_rel << "}\n";
    return 0;
  } catch (const std::exception &e) {
    std::cerr << "FAIL " << e.what() << '\n';
    return 1;
  }
}

#pragma once
// Independent numerical references for original-shape FP16/OCP-E4M3 workloads.
// Load the same assembled fixtures that the verifier consumes.
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

static void require(bool value, const std::string &message) {
  if (!value) throw std::runtime_error(message);
}
static void hip_check(hipError_t error, const char *operation) {
  require(error == hipSuccess, std::string(operation) + ": " + hipGetErrorString(error));
}

inline std::string quote_identity_text(const char *value) {
  std::string result = "\"";
  for (const unsigned char *p = reinterpret_cast<const unsigned char *>(value); *p; ++p) {
    if (*p == '"' || *p == '\\') {
      result += '\\';
      result += char(*p);
    } else if (*p < 0x20) {
      char escaped[7];
      std::snprintf(escaped, sizeof(escaped), "\\u%04x", unsigned(*p));
      result += escaped;
    } else {
      result += char(*p);
    }
  }
  return result + "\"";
}

inline std::string selected_device_identity_json() {
  int ordinal = -1, visible = 0, runtime = 0, driver = 0;
  hip_check(hipGetDevice(&ordinal), "get selected logical device");
  hip_check(hipGetDeviceCount(&visible), "get visible device count");
  hipDeviceProp_t properties{};
  hip_check(hipGetDeviceProperties(&properties, ordinal), "get selected device properties");
  hip_check(hipRuntimeGetVersion(&runtime), "get HIP runtime API version");
  hip_check(hipDriverGetVersion(&driver), "get HIP driver API version");
  char pci[64]{};
  hip_check(hipDeviceGetPCIBusId(pci, sizeof(pci), ordinal), "get selected device PCI address");
  hipDevice_t device{};
  hip_check(hipDeviceGet(&device, ordinal), "get selected device handle");
  hipUUID uuid{};
  const hipError_t uuid_error = hipDeviceGetUuid(&uuid, device);
  require(uuid_error == hipSuccess || uuid_error == hipErrorNotSupported,
          std::string("get selected device UUID: ") + hipGetErrorString(uuid_error));
  std::string uuid_hex;
  bool any_uuid_byte = false;
  if (uuid_error == hipSuccess) {
    for (const unsigned char byte : uuid.bytes) {
      char digits[3];
      std::snprintf(digits, sizeof(digits), "%02x", unsigned(byte));
      uuid_hex += digits;
      any_uuid_byte |= byte != 0;
    }
  }
  const char *uuid_status = uuid_error != hipSuccess ? "not_supported"
                            : any_uuid_byte          ? "available"
                                                     : "all_zero";
  return "{\"logical_ordinal\":" + std::to_string(ordinal) +
         ",\"visible_device_count\":" + std::to_string(visible) +
         ",\"name\":" + quote_identity_text(properties.name) +
         ",\"architecture\":" + quote_identity_text(properties.gcnArchName) +
         ",\"wave_size\":" + std::to_string(properties.warpSize) +
         ",\"pci_bus_id\":" + quote_identity_text(pci) +
         ",\"uuid_status\":" + quote_identity_text(uuid_status) +
         ",\"uuid_hex\":" + (any_uuid_byte ? quote_identity_text(uuid_hex.c_str()) : "null") +
         ",\"uuid_hip_error\":" + std::to_string(int(uuid_error)) +
         ",\"hip_runtime_version\":" + std::to_string(runtime) +
         ",\"hip_driver_version\":" + std::to_string(driver) + "}";
}

#ifndef VOLTA_HARDWARE_IDENTITY_ONLY

static void check_preserved(const std::vector<uint8_t> &before, const std::vector<uint8_t> &after,
                            bool output, size_t guard) {
  require(before.size() == after.size() && before.size() >= guard * 2, "invalid storage extent");
  for (size_t i = 0; i < before.size(); ++i) {
    const bool data = i >= guard && i < before.size() - guard;
    if (!output || !data) require(before[i] == after[i], "input or allocation guard modified");
  }
}

enum class Type { Half, Float, E4M3, I8, U32 };
static size_t width(Type type) {
  return type == Type::E4M3 || type == Type::I8 ? 1 : type == Type::Half ? 2 : 4;
}
static double decode_e4m3(uint8_t byte) {
  const unsigned exponent = (byte >> 3) & 15, fraction = byte & 7;
  const double value = exponent == 15 && fraction == 7
      ? NAN : exponent ? std::ldexp(1. + fraction / 8., int(exponent) - 7)
                      : std::ldexp(double(fraction), -9);
  return byte & 128 ? -value : value;
}

static void validate_reference_controls() {
  for (const auto &sample : std::vector<std::pair<uint8_t, double>>{
      {0x00, 0}, {0x01, 1. / 512}, {0x07, 7. / 512}, {0x08, 1. / 64},
      {0x30, .5}, {0x38, 1}, {0x40, 2}, {0x7e, 448}, {0x81, -1. / 512},
      {0xb8, -1}, {0xfe, -448}}) {
    require(decode_e4m3(sample.first) == sample.second, "OCP E4M3 decoder reference control failed");
  }
  require(std::signbit(decode_e4m3(0x80)), "OCP E4M3 negative zero lost");
  require(std::isnan(decode_e4m3(0x7f)) && std::isnan(decode_e4m3(0xff)), "OCP E4M3 NaN control failed");
  require(std::exp(0.) == 1. && 1. / (1. + std::exp(0.)) == .5, "zero activation reference failed");
  const std::vector<uint8_t> before(3, 0xa5);
  check_preserved(before, before, false, 1);
  for (size_t position : {size_t(0), size_t(1), size_t(2)}) {
    auto changed = before;
    changed[position] = 0;
    bool rejected = false;
    try { check_preserved(before, changed, position != 1, 1); }
    catch (const std::runtime_error &) { rejected = true; }
    require(rejected, "CPU storage checker missed input/prefix/suffix corruption");
  }
}

struct Buffer {
  static constexpr size_t guard = 4096;
  Type type;
  size_t count;
  bool output;
  std::vector<uint8_t> before, after;
  uint8_t *allocation{};
  void *pointer{};
  Buffer(Type t, size_t n, bool out = false)
      : type(t), count(n), output(out), before(guard * 2 + width(t) * n, 0xa5), after(before.size()) {
    hip_check(hipMalloc(&allocation, before.size()), "allocate guarded buffer");
    pointer = allocation + guard;
    if (out) std::fill(before.begin() + guard, before.end() - guard, 0xff);
  }
  Buffer(const Buffer &) = delete;
  Buffer &operator=(const Buffer &) = delete;
  ~Buffer() { if (allocation) (void)hipFree(allocation); }
  void set(size_t index, double value) {
    require(index < count, "reference input index out of bounds");
    uint8_t *p = before.data() + guard + index * width(type);
    if (type == Type::Half) { _Float16 v = (_Float16)value; std::memcpy(p, &v, 2); }
    else if (type == Type::Float) { float v = float(value); std::memcpy(p, &v, 4); }
    else if (type == Type::I8) { int8_t v = int8_t(value); std::memcpy(p, &v, 1); }
    else if (type == Type::U32) { uint32_t v = uint32_t(value); std::memcpy(p, &v, 4); }
    else throw std::runtime_error("E4M3 inputs require explicit encoded bytes");
  }
  double get(size_t index, bool observed = false) const {
    require(index < count, "reference output index out of bounds");
    const uint8_t *p = (observed ? after : before).data() + guard + index * width(type);
    if (type == Type::Half) { _Float16 v; std::memcpy(&v, p, 2); return double(v); }
    if (type == Type::Float) { float v; std::memcpy(&v, p, 4); return double(v); }
    if (type == Type::I8) { int8_t v; std::memcpy(&v, p, 1); return double(v); }
    if (type == Type::U32) { uint32_t v; std::memcpy(&v, p, 4); return double(v); }
    return decode_e4m3(*p);
  }
  void fill(unsigned pattern, unsigned salt) {
    static const uint8_t magnitudes[] = {0x00, 0x10, 0x20, 0x28, 0x30, 0x38, 0x3c, 0x40};
    for (size_t i = 0; i < count; ++i) {
      if (type == Type::E4M3) {
        const size_t coordinate = i * (2 * salt + 1) + (i / 7) * 5 +
                                  (i / 4096) * 3 + pattern * 7 + salt;
        uint8_t value = magnitudes[coordinate % 8];
        if ((i + i / 13 + i / 4096 + salt + pattern) & 1) value |= 128;
        before[guard + i] = pattern == 0 ? 0 : value;
      } else {
        // Convert the modular coordinate to signed BEFORE subtraction.
        const int coordinate = int((i * (2 * salt + 1) + pattern * 7 + salt) % 33) - 16;
        set(i, pattern == 0 ? 0 : coordinate * .125);
      }
    }
  }
  void upload() { hip_check(hipMemcpy(allocation, before.data(), before.size(), hipMemcpyHostToDevice), "upload"); }
  void download() { hip_check(hipMemcpy(after.data(), allocation, after.size(), hipMemcpyDeviceToHost), "download"); }
  size_t check_unchanged() const {
    check_preserved(before, after, output, guard);
    return output ? guard * 2 : before.size();
  }
};

struct Row {
  std::string kernel;
  size_t outputs{}, launches{}, unchanged_input_bytes{}, unchanged_guard_bytes{}, unchanged_gap_bytes{}, original_outputs{};
  double maximum{};
};
static void launch(hipModule_t module, const std::string &name, dim3 block,
                   std::vector<void *> args, const std::vector<Buffer *> &buffers, Row &row,
                   dim3 grid = dim3(1)) {
  for (Buffer *buffer : buffers) buffer->upload();
  hipFunction_t function{};
  hip_check(hipModuleGetFunction(&function, module, name.c_str()), "get kernel");
  hip_check(hipModuleLaunchKernel(function, grid.x, grid.y, grid.z, block.x, block.y, block.z,
                                 0, nullptr, args.data(), nullptr), "launch");
  hip_check(hipDeviceSynchronize(), "synchronize");
  for (Buffer *buffer : buffers) {
    buffer->download();
    buffer->check_unchanged();
    row.unchanged_guard_bytes += Buffer::guard * 2;
    if (!buffer->output) row.unchanged_input_bytes += buffer->count * width(buffer->type);
  }
  ++row.launches;
}

static void compare(const std::string &name, Buffer &out,
                    const std::vector<double> &expected, Row &row,
                    double atol = .00003, double rtol = .002) {
  require(expected.size() == out.count, name + ": incomplete CPU reference");
  for (size_t i = 0; i < out.count; ++i) {
    const double value = out.get(i, true), reference = expected[i];
    if (std::isnan(reference)) {
      const size_t start = Buffer::guard + i * width(out.type);
      for (size_t b = 0; b < width(out.type); ++b)
        require(out.before[start + b] == out.after[start + b], name + ": output padding modified");
      row.unchanged_gap_bytes += width(out.type);
      continue;
    }
    require(std::isfinite(value) && std::isfinite(reference), name + ": nonfinite output/reference");
    const double error = std::abs(value - reference);
    if (error > atol + rtol * std::abs(reference)) {
      char detail[256];
      std::snprintf(detail, sizeof(detail), ": index=%zu expected=%.12g observed=%.12g", i, reference, value);
      throw std::runtime_error(name + detail);
    }
    row.maximum = std::max(row.maximum, error);
    ++row.outputs;
  }
}

static void run(hipModule_t module, const std::string &name, dim3 block,
                std::vector<void *> args, const std::vector<Buffer *> &buffers,
                Buffer &out, const std::vector<double> &expected, Row &row,
                double atol = .00003, double rtol = .002) {
  launch(module, name, block, std::move(args), buffers, row);
  compare(name, out, expected, row, atol, rtol);
}

#endif // VOLTA_HARDWARE_IDENTITY_ONLY

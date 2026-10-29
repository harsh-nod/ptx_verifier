// Dense independent references for original attention, Sinkhorn and Mamba.
#include "original_common.hpp"

static void small(Buffer &buffer, unsigned pattern, unsigned salt) {
  buffer.fill(pattern, salt);
  for (size_t i = 0; i < buffer.count; ++i) buffer.set(i, buffer.get(i) / 8.);
}
static double softmax(const std::vector<double> &score, bool base2, std::vector<double> &p) {
  const double maximum = *std::max_element(score.begin(), score.end());
  double denominator = 0;
  p.resize(score.size());
  for (size_t i = 0; i < score.size(); ++i) {
    p[i] = base2 ? std::exp2(score[i] - maximum) : std::exp(score[i] - maximum);
    denominator += p[i];
  }
  for (double &value : p) value /= denominator;
  return maximum + (base2 ? std::log2(denominator) : std::log(denominator));
}
static uint32_t hash_coordinate(uint32_t value) {
  value ^= value >> 16; value *= 0x7feb352dU;
  value ^= value >> 15; value *= 0x846ca68bU;
  return value ^ (value >> 16);
}

static void attention(hipModule_t module, unsigned mode, unsigned patterns, std::vector<Row> &rows) {
  const size_t queries = mode == 0 ? 1024 : 128, keys = mode == 2 ? 128 : 1024;
  Row row{mode == 0 ? "flash_attention_original" : mode == 1 ? "forgetting_attention_original" : "sage_attention_original"};
  Buffer q(mode == 2 ? Type::I8 : Type::Half, queries * 64);
  Buffer k(mode == 2 ? Type::I8 : Type::Half, keys * 64), v(Type::Half, keys * 64);
  Buffer lambda(Type::Float, keys), qs(Type::Float, 1), ks(Type::Float, 2);
  Buffer out(Type::Half, queries * 64, true), lse(Type::Float, queries, true);
  void *unused = nullptr;
  for (unsigned pattern = 0; pattern < patterns; ++pattern) {
    if (mode == 2) {
      for (size_t i = 0; i < q.count; ++i) q.set(i, pattern == 0 ? 0 : int(hash_coordinate(uint32_t(i) ^ pattern * 0x3129U) & 255) - 128);
      for (size_t i = 0; i < k.count; ++i) k.set(i, pattern == 0 ? 0 : int(hash_coordinate(uint32_t(i) ^ pattern * 0x4319U) & 255) - 128);
      qs.set(0, 1. / double(128 + (pattern % 2) * 128));
      ks.set(0, double(1 + pattern % 3) / 512);
      ks.set(1, double(5 + pattern % 3) / 2048);
    } else { small(q, pattern, 3); small(k, pattern, 7); }
    small(v, pattern, 11); small(lambda, pattern, 13);
    if (pattern == 4) {
      // D63 basis vectors retain every query/key, including both Sage scale blocks.
      q.fill(0, 0); k.fill(0, 0); v.fill(0, 0);
      for (size_t r = 0; r < queries; ++r)
        q.set(r * 64 + 63, mode == 2 ? (r % 2 ? -128. : 127.) : (r % 7 + 1) / 16.);
      for (size_t key = 0; key < keys; ++key)
        k.set(key * 64 + 63, mode == 2 ? (key % 2 ? -128. : 127.) : (key % 5 + 1) / 16.);
      v.set(63 * 64, 1.);
      v.set(64 * 64 + 31, -.5);
      v.set((keys - 1) * 64 + 63, .25);
    } else if (pattern == 5) {
      // First feature/key, last original query and the additional Flash tail row.
      q.basis(127 * 64); k.basis(0); v.basis(63);
      if (queries > 128) q.set((queries - 1) * 64, -1.);
    }
    std::vector<double> expected(queries * 64, 0), expected_lse(queries), scores(keys), probabilities;
    for (size_t r = 0; r < queries; ++r) {
      for (size_t key = 0; key < keys; ++key) {
        double dot = 0;
        for (size_t d = 0; d < 64; ++d) dot += q.get(r * 64 + d) * k.get(key * 64 + d);
        scores[key] = mode == 2 ? dot * qs.get(0) * ks.get(key / 64)
                              : dot / 8. - (mode == 1 ? lambda.get(key) : 0.);
      }
      expected_lse[r] = softmax(scores, mode == 2, probabilities) + (mode == 1 ? lambda.get(r) : 0.);
      for (size_t key = 0; key < keys; ++key) for (size_t d = 0; d < 64; ++d)
        expected[r * 64 + d] += probabilities[key] * v.get(key * 64 + d);
    }
    if (mode == 0)
      launch(module, row.kernel, dim3(128), {&q.pointer, &k.pointer, &v.pointer, &unused, &out.pointer, &lse.pointer, &unused},
             {&q, &k, &v, &out, &lse}, row, dim3(16));
    else if (mode == 1)
      launch(module, row.kernel, dim3(256), {&q.pointer, &k.pointer, &v.pointer, &lambda.pointer, &lse.pointer, &out.pointer},
             {&q, &k, &v, &lambda, &lse, &out}, row);
    else
      launch(module, row.kernel, dim3(256), {&q.pointer, &k.pointer, &v.pointer, &qs.pointer, &ks.pointer, &out.pointer, &unused, &unused},
             {&q, &k, &v, &qs, &ks, &out}, row);
    compare(row.kernel + ".out", out, expected, row, .00008, .002);
    if (mode != 2) compare(row.kernel + ".lse", lse, expected_lse, row, .00002, 0);
    // Flash uses the real grid16 and checks every additional native row.
    // CTA0's original projection is all128 output rows plus128 LSE values.
    row.original_outputs += mode == 2 ? 8192 : 8320;
  }
  rows.push_back(row);
}

static void sinkhorn(hipModule_t module, unsigned patterns, std::vector<Row> &rows) {
  Row row{"sinkhorn_original"};
  Buffer x(Type::Half, 32 * 64), y(Type::Half, 1024 * 64);
  Buffer f(Type::Float, 32), g(Type::Float, 1024), lb(Type::Float, 1024), out(Type::Float, 32, true);
  void *unused = nullptr;
  for (unsigned pattern = 0; pattern < patterns; ++pattern) {
    small(x, pattern, 3); small(y, pattern, 7); small(f, pattern, 11);
    small(g, pattern, 13); small(lb, pattern, 17);
    if (pattern == 4) { x.basis(31 * 64 + 63); y.basis(1023 * 64 + 63); }
    else if (pattern == 5) { x.basis(0); y.basis(0); }
    std::vector<double> expected(32), score(1024), p;
    for (size_t r = 0; r < 32; ++r) {
      for (size_t key = 0; key < 1024; ++key) {
        double dot = 0;
        for (size_t d = 0; d < 64; ++d) dot += x.get(r * 64 + d) * y.get(key * 64 + d);
        score[key] = 2 * dot + g.get(key) + lb.get(key);
      }
      expected[r] = .5 * (f.get(r) - softmax(score, false, p));
    }
    run(module, row.kernel, dim3(256), {&x.pointer, &y.pointer, &f.pointer, &g.pointer, &unused, &lb.pointer, &out.pointer, &unused, &unused, &unused, &unused},
        {&x, &y, &f, &g, &lb, &out}, out, expected, row, .00002, .000002);
    row.original_outputs += 32;
  }
  rows.push_back(row);
}

static void state(hipModule_t module, unsigned patterns, std::vector<Row> &rows) {
  Row row{"mamba_state_original"};
  Buffer x(Type::Half, 256 * 512), b(Type::Half, 256 * 512), dt(Type::Float, 256), da(Type::Float, 256), out(Type::Float, 64 * 128, true);
  void *unused = nullptr;
  for (unsigned pattern = 0; pattern < patterns; ++pattern) {
    small(x, pattern, 3); small(b, pattern, 7); small(da, pattern, 11);
    if (pattern == 4) { x.basis(255 * 512 + 63); b.basis(255 * 512 + 127); }
    else if (pattern == 5) { x.basis(0); b.basis(0); }
    da.set(255, 0);
    for (size_t t = 0; t < 256; ++t) dt.set(t, (16 + (t * 7 + pattern) % 17) / 64.);
    std::vector<double> expected(64 * 128, 0);
    for (size_t t = 0; t < 256; ++t) {
      const float weight = float(dt.get(t)) * float(std::exp(std::min(da.get(255) - da.get(t), 0.)));
      for (size_t s = 0; s < 128; ++s) {
        const double weighted = double((_Float16)(float(b.get(t * 512 + s)) * weight));
        for (size_t f = 0; f < 64; ++f) expected[f * 128 + s] += x.get(t * 512 + f) * weighted;
      }
    }
    run(module, row.kernel, dim3(64), {&x.pointer, &b.pointer, &out.pointer, &dt.pointer, &da.pointer, &unused},
        {&x, &b, &out, &dt, &da}, out, expected, row, .0002, .002);
    row.original_outputs += 8192;
  }
  rows.push_back(row);
}

static void scan(hipModule_t module, unsigned patterns, std::vector<Row> &rows) {
  Row row{"mamba_scan_original"};
  Buffer cb(Type::Float, 32 * 128), x(Type::Half, 128 * 1024), dt(Type::Float, 128), da(Type::Float, 128);
  Buffer c(Type::Half, 32 * 64), prev(Type::Float, 128 * 32);
  Buffer out(Type::Half, 32 * 1024, true), out_x(Type::Half, 32 * 1024, true);
  void *unused = nullptr;
  for (unsigned pattern = 0; pattern < patterns; ++pattern) {
    small(cb, pattern == 1 ? 0 : pattern, 3); small(x, pattern, 7);
    small(c, pattern, 11); small(prev, pattern == 2 ? 0 : pattern, 13); small(da, pattern, 17);
    if (pattern == 4) {
      // Last current-chunk time/row/feature; no prior-state contribution.
      cb.basis(31 * 128 + 127); x.basis(127 * 1024 + 127);
      c.fill(0, 0); prev.fill(0, 0);
    } else if (pattern == 5) {
      // Distinct prior-state basis, including state31 and its F32-to-F16 cast.
      cb.fill(0, 0); x.fill(0, 0);
      c.basis(31 * 64 + 31); prev.basis(127 * 32 + 31);
    }
    for (size_t t = 0; t < 128; ++t) dt.set(t, (8 + (t * 7 + pattern) % 17) / 64.);
    std::vector<double> expected(32 * 1024, NAN), zeros(32 * 1024, NAN);
    for (size_t r = 0; r < 32; ++r) for (size_t f = 0; f < 128; ++f) {
      double previous = 0, value = 0;
      for (size_t s = 0; s < 32; ++s) previous += c.get(r * 64 + s) * double((_Float16)prev.get(f * 32 + s));
      previous *= float(std::exp(da.get(r)));
      for (size_t t = 0; t < 128; ++t) {
        const float decay = float(std::exp(std::min(da.get(r) - da.get(t), 0.)));
        const float weighted = float(cb.get(r * 128 + t)) * decay * float(dt.get(t));
        value += double((_Float16)weighted) * x.get(t * 1024 + f);
      }
      expected[r * 1024 + f] = double((_Float16)(previous + value));
      zeros[r * 1024 + f] = 0;
    }
    launch(module, row.kernel, dim3(64), {&cb.pointer, &x.pointer, &unused, &out.pointer, &out_x.pointer,
           &dt.pointer, &da.pointer, &unused, &c.pointer, &prev.pointer, &unused},
           {&cb, &x, &out, &out_x, &dt, &da, &c, &prev}, row);
    compare(row.kernel + ".out", out, expected, row, .00003, .002);
    compare(row.kernel + ".out_x", out_x, zeros, row, 0, 0);
    row.original_outputs += 8192;
  }
  rows.push_back(row);
}

int main(int argc, char **argv) {
  try {
    validate_reference_controls();
    validate_basis_controls();
    std::vector<double> p;
    require(softmax({0, 0, 0, 0}, false, p) == std::log(4.) && p == std::vector<double>(4, .25), "dense softmax control failed");
    if (argc == 2 && std::string(argv[1]) == "--cpu-only") {
      std::puts("PASS advanced host reference and storage and basis byte/guard controls; GPU launches=0"); return 0;
    }
    require(argc == 5, "usage: original_advanced_driver attention.hsaco sinkhorn.hsaco mamba.hsaco patterns");
    size_t consumed = 0;
    const std::string text = argv[4];
    const auto patterns = std::stoul(text, &consumed);
    require(consumed == text.size() && patterns >= 6 && patterns <= 16, "advanced patterns must be6..16, including current/prior bases4/5");
    hipDeviceProp_t device{};
    hip_check(hipGetDeviceProperties(&device, 0), "device properties");
    const std::string architecture = device.gcnArchName;
    require(architecture.substr(0, architecture.find(':')) == "gfx1250" && device.warpSize == 32, "requires actual wave32 gfx1250");
    hipModule_t a{}, s{}, m{};
    hip_check(hipModuleLoad(&a, argv[1]), "load exact attention");
    hip_check(hipModuleLoad(&s, argv[2]), "load exact Sinkhorn");
    hip_check(hipModuleLoad(&m, argv[3]), "load exact Mamba");
    std::vector<Row> rows;
    for (unsigned mode = 0; mode < 3; ++mode) attention(a, mode, unsigned(patterns), rows);
    sinkhorn(s, unsigned(patterns), rows); state(m, unsigned(patterns), rows); scan(m, unsigned(patterns), rows);
    hip_check(hipModuleUnload(a), "unload attention"); hip_check(hipModuleUnload(s), "unload Sinkhorn"); hip_check(hipModuleUnload(m), "unload Mamba");
    std::printf("{\"status\":\"pass\",\"architecture\":\"gfx1250\",\"wave_size\":32,\"reference_controls\":\"pass\",\"patterns\":%lu,\"flash_native_rows\":1024,\"flash_original_rows\":128,\"flash_grid\":[16,1,1],\"cases\":[", patterns);
    for (size_t i = 0; i < rows.size(); ++i) {
      const Row &r = rows[i];
      std::printf("%s{\"kernel\":\"%s\",\"outputs\":%zu,\"original_outputs\":%zu,\"launches\":%zu,\"unchanged_input_bytes\":%zu,\"unchanged_guard_bytes\":%zu,\"unchanged_gap_bytes\":%zu,\"max_absolute_error\":%.12g}", i ? "," : "", r.kernel.c_str(), r.outputs, r.original_outputs, r.launches, r.unchanged_input_bytes, r.unchanged_guard_bytes, r.unchanged_gap_bytes, r.maximum);
    }
    std::puts("]}");
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "original advanced validation failed: %s\n", error.what()); return 1;
  }
}

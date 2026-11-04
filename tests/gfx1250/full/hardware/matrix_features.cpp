// Independent dense/raw-word controls for the safe native matrix feature kernels.
// Assemble/link native-matrix-{layout,numeric,publication}.s unchanged, then build
// this host driver with clang++ -std=c++17 -O2 -D__HIP_PLATFORM_AMD__
// -I$ROCM/include -L$ROCM/lib -lamdhip64 -Wl,-rpath,$ROCM/lib. Select one physical
// GPU with HIP_VISIBLE_DEVICES, leaving ROCR_VISIBLE_DEVICES unset. The three
// arguments are the layout, numeric and publication code objects in that order.
// LLVM/HIP versions and artifact hashes belong in external run records.
#include "original_common.hpp"

static void compare_words(Buffer &actual, const Buffer &input, bool fragments, Row &row) {
  for (size_t index = 0; index < actual.count; ++index) {
    const size_t source = fragments
        ? ((index % 8) / 2) * 64 + (index / 8) * 2 + index % 2
        : index;
    require(std::memcmp(actual.after.data() + Buffer::guard + index * 2,
                        input.before.data() + Buffer::guard + source * 2, 2) == 0,
            "raw halfword placement mismatch");
    ++row.outputs;
  }
}

int main(int argc, char **argv) {
  try {
    require(argc == 4, "usage: matrix_features layout.hsaco numeric.hsaco publication.hsaco");
    for (const char *name : {"HSA_OVERRIDE_GFX_VERSION", "HSA_OVERRIDE_GFX_VERSION_0"})
      require(std::getenv(name) == nullptr, "architecture override is forbidden");
    hipDeviceProp_t properties{};
    hip_check(hipGetDeviceProperties(&properties, 0), "get selected device properties");
    require(std::string(properties.gcnArchName).substr(0, 7) == "gfx1250" &&
                properties.warpSize == 32, "a real gfx1250 wave32 device is required");
    hipModule_t layout{}, numeric{}, publication{};
    hip_check(hipModuleLoad(&layout, argv[1]), "load layout assembly");
    hip_check(hipModuleLoad(&numeric, argv[2]), "load numeric assembly");
    hip_check(hipModuleLoad(&publication, argv[3]), "load publication assembly");
    Row total;
    for (unsigned pattern = 0; pattern < 8; ++pattern) {
      Buffer input(Type::Half, 256), out(Type::Float, 256, true), fragment(Type::Half, 256, true);
      input.fill(pattern, 3);
      std::vector<double> product(256);
      for (unsigned row = 0; row < 16; ++row) {
        double sum = 0;
        for (unsigned k = 0; k < 16; ++k)
          sum += input.get(row * 16 + k) * (k + 1);
        for (unsigned column = 0; column < 16; ++column)
          product[row * 16 + column] = sum;
      }
      // The overlapping 16-byte-pitch CPU mutant is deliberately excluded.
      for (const char *kernel : {"matrix_stride32", "matrix_stride48", "matrix_stride64", "matrix_stride40"}) {
        launch(layout, kernel, dim3(32), {&input.pointer, &out.pointer, &fragment.pointer},
               {&input, &out, &fragment}, total);
        compare(kernel, out, product, total, 0, 0);
        compare_words(fragment, input, false, total);
      }
      launch(publication, "matrix_cross_wave_publication", dim3(64),
             {&input.pointer, &out.pointer}, {&input, &out}, total);
      compare("matrix_cross_wave_publication", out, product, total, 0, 0);

      for (const char *kernel : {"matrix_raw_accumulator", "matrix_immediate_accumulator"}) {
        Buffer projected(Type::Float, 128, true), native(Type::Float, 256, true);
        std::vector<double> values(256);
        for (unsigned i = 0; i < 256; ++i) values[i] = i % 4 == 0 ? 1 : 0;
        launch(layout, kernel, dim3(32), {&projected.pointer, &native.pointer},
               {&projected, &native}, total);
        compare(kernel, projected, std::vector<double>(values.begin(), values.begin() + 128), total, 0, 0);
        compare(kernel, native, values, total, 0, 0);
      }
      {
        Buffer raw(Type::Half, 256), copied(Type::Half, 256, true);
        for (unsigned i = 0; i < 256; ++i) {
          const uint16_t word = uint16_t(i * 17011 + pattern * 12347);
          std::memcpy(raw.before.data() + Buffer::guard + i * 2, &word, 2);
        }
        launch(layout, "matrix_four_fragment_pairs", dim3(32), {&raw.pointer, &copied.pointer},
               {&raw, &copied}, total);
        compare_words(copied, raw, true, total);
      }
      {
        Buffer words(Type::U32, 33, true);
        launch(layout, "matrix_lane_word_placement", dim3(32), {&words.pointer}, {&words}, total);
        std::vector<double> expected(33);
        expected[0] = 1005;
        for (unsigned i = 1; i < 33; ++i) expected[i] = 999 + i;
        compare("matrix_lane_word_placement", words, expected, total, 0, 0);
      }
      for (const auto &sample : std::vector<std::pair<const char *, unsigned>>{
          {"matrix_numeric136", 8}, {"matrix_raw17", 8}, {"matrix_zero_128x8", 8},
          {"matrix_zero_128x256", 256}, {"matrix_mixed408", 8}, {"matrix_wrong_b476", 8}}) {
        const std::string kernel = sample.first;
        const unsigned columns = sample.second, pitch = ((columns + 15) / 16) * 16;
        Buffer logical(Type::Float, 128 * columns, true), native(Type::Float, 128 * pitch, true);
        std::vector<double> original(128 * columns, kernel == "matrix_raw17" ? 1 : 0);
        std::vector<double> padded(128 * pitch);
        for (unsigned r = 0; r < 128; ++r)
          for (unsigned c = 0; c < columns; ++c) padded[r * pitch + c] = original[r * columns + c];
        const double first = kernel == "matrix_numeric136" ? 136 : kernel == "matrix_raw17" ? 17
                             : kernel == "matrix_mixed408" ? 408 : kernel == "matrix_wrong_b476" ? 476 : 0;
        original[0] = padded[0] = first;
        launch(numeric, kernel, dim3(256), {&logical.pointer, &native.pointer}, {&logical, &native}, total);
        compare(kernel, logical, original, total, 0, 0);
        compare(kernel, native, padded, total, 0, 0);
      }
    }
    hip_check(hipModuleUnload(layout), "unload layout");
    hip_check(hipModuleUnload(numeric), "unload numeric");
    hip_check(hipModuleUnload(publication), "unload publication");
    require(total.launches == 120 && total.outputs == 674056 &&
                total.unchanged_input_bytes == 24576 && total.unchanged_guard_bytes == 2162688,
            "incomplete matrix feature launch/output accounting");
    std::printf("PASS: %zu launches, %zu complete original/native outputs, %zu input bytes, %zu guard bytes\n",
                total.launches, total.outputs, total.unchanged_input_bytes, total.unchanged_guard_bytes);
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "FAIL: %s\n", error.what());
    return 1;
  }
}

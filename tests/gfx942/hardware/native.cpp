// Host-only reference driver for the exact compiler-emitted gfx942 .s files.
// llvm-mc gfx942 -> ld.lld -shared -> HIP module API; no GPU C++ kernels here.
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <string>
#include <vector>

static void check(hipError_t error, const char *operation) {
  if (error != hipSuccess)
    throw std::runtime_error(std::string(operation) + ": " + hipGetErrorString(error));
}
static constexpr unsigned Guard = 64;
static uint64_t launches = 0, output_checks = 0, guard_bytes = 0, input_bytes = 0;

template<class T> struct Buffer {
  std::vector<T> host;
  T *allocation{}, *device{};
  explicit Buffer(unsigned n) : host(n + 2 * Guard) {
    check(hipMalloc(&allocation, host.size() * sizeof(T)), "allocate guarded storage");
    device = allocation + Guard;
    reset();
  }
  ~Buffer() { if (allocation) (void)hipFree(allocation); }
  Buffer(const Buffer &) = delete;
  void reset() { std::memset(host.data(), 0xa5, host.size() * sizeof(T)); }
  T &at(unsigned i) { return host[Guard + i]; }
  unsigned size() const { return host.size() - 2 * Guard; }
  void upload() { check(hipMemcpy(allocation, host.data(), host.size()*sizeof(T), hipMemcpyHostToDevice), "upload"); }
  void download() { check(hipMemcpy(host.data(), allocation, host.size()*sizeof(T), hipMemcpyDeviceToHost), "download"); }
  void unchanged(const std::vector<T> &before) {
    download();
    if (std::memcmp(host.data(), before.data(), host.size()*sizeof(T)))
      throw std::runtime_error("input or input guards modified");
    input_bytes += host.size()*sizeof(T);
  }
  void verify(const std::vector<double> &expected, const std::string &context) {
    if (expected.size() != size()) throw std::runtime_error("reference length");
    download();
    auto raw = reinterpret_cast<const unsigned char *>(host.data());
    for (size_t i=0;i<host.size()*sizeof(T);++i) {
      if (i<Guard*sizeof(T) || i>=(Guard+size())*sizeof(T)) {
        if (raw[i] != 0xa5) throw std::runtime_error(context+": output guard overwrite");
        ++guard_bytes;
      }
    }
    for (unsigned i=0;i<size();++i) {
      double actual = (double)at(i);
      if (!std::isfinite(actual) || actual != expected[i])
        throw std::runtime_error(context+": output "+std::to_string(i)+" expected="+
                                 std::to_string(expected[i])+" got="+std::to_string(actual));
      ++output_checks;
    }
  }
};
struct Module {
  hipModule_t value{};
  explicit Module(const std::string &path) { check(hipModuleLoad(&value, path.c_str()), "load exact native code object"); }
  ~Module() { if(value) (void)hipModuleUnload(value); }
  hipFunction_t function(const char *name) {
    hipFunction_t f{}; check(hipModuleGetFunction(&f,value,name),name); return f;
  }
};
static void launch(hipFunction_t function, dim3 grid, dim3 block, void **args) {
  check(hipModuleLaunchKernel(function,grid.x,grid.y,grid.z,block.x,block.y,block.z,
                              0,nullptr,args,nullptr),"launch");
  check(hipDeviceSynchronize(),"synchronize"); ++launches;
}
static void checker_controls() {
  auto saved_outputs=output_checks,saved_guards=guard_bytes;
  Buffer<float> probe(2);
  probe.at(0)=1;probe.at(1)=2;probe.upload();probe.verify({1,2},"checker positive");
  for(unsigned corruption=0;corruption<4;++corruption) {
    probe.reset();probe.at(0)=1;probe.at(1)=2;
    if(corruption==0)probe.at(0)=3;
    if(corruption==1)std::memset(&probe.at(0),0xa5,sizeof(float));
    if(corruption==2)probe.host.front()=0;
    if(corruption==3)probe.host.back()=0;
    probe.upload();bool rejected=false;
    try{probe.verify({1,2},"intentional checker corruption");}
    catch(const std::runtime_error&){rejected=true;}
    if(!rejected)throw std::runtime_error("host checker accepted intentional corruption");
  }
  output_checks=saved_outputs;guard_bytes=saved_guards;
  std::puts("PASS checker rejects wrong output, missing output, prefix and suffix guard corruption");
}
static float pattern(unsigned row,unsigned col,unsigned seed) {
  return float(int((row*13+col*7+seed*11)%31)-15)*0.125f;
}

static void copy_add(const std::string &directory) {
  Module module(directory+"/native-copy-add.hsaco");
  for (unsigned block : {1u,63u,64u,65u,128u,256u})
    for (unsigned n : {1u,65u,257u})
      for (unsigned seed=0;seed<3;++seed) {
        Buffer<float> x(n),y(n),out(n);
        for(unsigned i=0;i<n;++i){x.at(i)=pattern(i,0,seed);y.at(i)=pattern(i,3,seed+1);}
        auto xb=x.host,yb=y.host; x.upload();y.upload();
        for (bool addition : {false,true}) {
          out.reset();out.upload();
          void *two[]={&x.device,&out.device,&n};
          void *three[]={&x.device,&y.device,&out.device,&n};
          launch(module.function(addition?"add":"copy"),dim3((n+block-1)/block),
                 dim3(block),addition?three:two);
          std::vector<double> expected(n);
          for(unsigned i=0;i<n;++i)expected[i]=addition?x.at(i)+y.at(i):x.at(i);
          out.verify(expected,addition?"add":"copy");x.unchanged(xb);y.unchanged(yb);
        }
      }
  std::puts("PASS copy/add blocks=1,63,64,65,128,256 lengths=1,65,257 patterns=3 full_grid=true exact=true");
}

static void lds_ids(const std::string &directory) {
  Module module(directory+"/native-lds-ids.hsaco");
  for(unsigned seed=0;seed<17;++seed) {
    Buffer<float>x(128),exchanged(128),reduced(2),ids(24);
    for(unsigned i=0;i<128;++i)x.at(i)=pattern(i,4,seed);
    auto before=x.host;x.upload();exchanged.upload();reduced.upload();ids.upload();
    void *exchange_args[]={&x.device,&exchanged.device};
    launch(module.function("exchange"),dim3(1),dim3(128),exchange_args);
    std::vector<double> expected(128);
    for(unsigned i=0;i<128;++i)expected[i]=x.at(i^64);
    exchanged.verify(expected,"cross-wave LDS exchange");x.unchanged(before);
    void *reduce_args[]={&x.device,&reduced.device};
    launch(module.function("reduce"),dim3(1),dim3(128),reduce_args);
    std::vector<double> sums(2,0);
    for(unsigned i=0;i<128;++i)sums[i/64]+=x.at(i);
    reduced.verify(sums,"two independent wave64 reductions");x.unchanged(before);
    void *id_args[]={&ids.device};
    launch(module.function("ids_3d"),dim3(1),dim3(4,3,2),id_args);
    std::vector<double> coordinates(24);
    for(unsigned z=0;z<2;++z)for(unsigned y=0;y<3;++y)for(unsigned x=0;x<4;++x)
      coordinates[x+4*(y+3*z)]=x+10*y+100*z;
    ids.verify(coordinates,"packed local XYZ IDs");
  }
  std::puts("PASS LDS exchange128, wave64 reduction2, IDs4x3x2 patterns=17 exact=true");
}

template<class T> static void mfma(Module &module,const char *name,unsigned depth) {
  const unsigned items=16*depth/64,count=16*depth;
  Buffer<T> a(count),b(count);Buffer<float> out(256);
  // Every A and B basis coordinate plus17 asymmetric dense patterns. The CPU
  // product uses ordinary logical row/column coordinates independently of MFMA.
  for(unsigned seed=0;seed<2*count+17;++seed) {
    std::vector<double> ar(count),br(count);
    for(unsigned row=0;row<16;++row)for(unsigned k=0;k<depth;++k)
      ar[row*depth+k]=seed<count?double(row*depth+k==seed):pattern(row,k,seed);
    for(unsigned k=0;k<depth;++k)for(unsigned col=0;col<16;++col)
      br[k*16+col]=seed>=count&&seed<2*count?double(k*16+col==seed-count):pattern(k,col,seed+3);
    for(unsigned row=0;row<16;++row)for(unsigned k=0;k<depth;++k) {
      unsigned lane=row+16*(k/items),component=k%items;
      a.at(lane*items+component)=T(ar[row*depth+k]);
      b.at(lane*items+component)=T(br[k*16+row]);
    }
    auto ab=a.host,bb=b.host;a.upload();b.upload();out.reset();out.upload();
    void *args[]={&a.device,&b.device,&out.device};
    launch(module.function(name),dim3(1),dim3(64),args);
    std::vector<double> expected(256);
    for(unsigned row=0;row<16;++row)for(unsigned col=0;col<16;++col) {
      double sum=0;for(unsigned k=0;k<depth;++k)sum+=ar[row*depth+k]*br[k*16+col];
      unsigned lane=16*(row/4)+col,component=row%4;
      expected[lane*4+component]=sum;
    }
    out.verify(expected,name);a.unchanged(ab);b.unchanged(bb);
  }
  std::printf("PASS %s M=N=16 K=%u A_basis=%u B_basis=%u dense=17 exact=true\n",name,depth,count,count);
}
static void pipeline(const std::string &directory) {
  Module module(directory+"/native-pipeline-f16.hsaco");
  for(unsigned seed=0;seed<17;++seed) {
    Buffer<_Float16>a(32*32),b(32*16),out(32*16);
    for(unsigned row=0;row<32;++row)for(unsigned k=0;k<32;++k)a.at(row*32+k)=(_Float16)pattern(row,k,seed);
    for(unsigned k=0;k<32;++k)for(unsigned col=0;col<16;++col)b.at(k*16+col)=(_Float16)pattern(k,col,seed+7);
    auto ab=a.host,bb=b.host;a.upload();b.upload();out.upload();
    void *args[]={&a.device,&b.device,&out.device};
    launch(module.function("pipelined_mfma_f16"),dim3(1),dim3(128),args);
    std::vector<double> expected(512);
    for(unsigned row=0;row<32;++row)for(unsigned col=0;col<16;++col) {
      double sum=0;for(unsigned k=0;k<32;++k)sum+=double(a.at(row*32+k))*double(b.at(k*16+col));
      expected[row*16+col]=double((_Float16)sum);
    }
    out.verify(expected,"two-wave F16 LDS/MFMA pipeline");a.unchanged(ab);b.unchanged(bb);
  }
  std::puts("PASS pipelined_mfma_f16 M32 N16 K32 block128 patterns=17 exact=true");
}
int main(int argc,char **argv) {try {
  if(argc!=2)throw std::runtime_error("usage: native DIRECTORY_WITH_EXACT_HSACO_FILES");
  hipDeviceProp_t device{};check(hipGetDeviceProperties(&device,0),"device properties");
  std::string target=device.gcnArchName;
  if(target.substr(0,target.find(':'))!="gfx942"||device.warpSize!=64)
    throw std::runtime_error("requires actual gfx942 wave64 device");
  int runtime{},driver{};check(hipRuntimeGetVersion(&runtime),"runtime version");check(hipDriverGetVersion(&driver),"driver version");
  std::printf("DEVICE name=%s arch=%s wave=%d runtime=%d driver=%d\n",device.name,device.gcnArchName,device.warpSize,runtime,driver);
  checker_controls();
  copy_add(argv[1]);lds_ids(argv[1]);
  {Module matrix(std::string(argv[1])+"/native-mfma.hsaco");mfma<float>(matrix,"mfma_f32",4);mfma<_Float16>(matrix,"mfma_f16",16);}
  pipeline(argv[1]);
  std::printf("SUMMARY PASS launches=%llu output_checks=%llu guard_bytes=%llu unchanged_input_bytes=%llu atol=0 rtol=0\n",
    (unsigned long long)launches,(unsigned long long)output_checks,(unsigned long long)guard_bytes,(unsigned long long)input_bytes);
  return 0;
}catch(const std::exception &error){std::fprintf(stderr,"FAIL %s\n",error.what());return 1;}}

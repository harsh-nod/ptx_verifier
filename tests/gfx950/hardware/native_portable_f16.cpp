// Numeric validation of the exact compiler-produced portable-f16.s code object.
// Reference loops describe computations independently of the symbolic executor.
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

static void check(hipError_t error, const char *operation) {
  if (error != hipSuccess) {
    std::fprintf(stderr, "%s: %s\n", operation, hipGetErrorString(error));
    std::exit(1);
  }
}
template <class T> struct Buffer {
  std::vector<T> host;
  T *device{};
  explicit Buffer(size_t count) : host(count) {
    check(hipMalloc(&device, count * sizeof(T)), "allocate");
    check(hipMemset(device, 0xff, count * sizeof(T)), "initialize storage sentinel");
  }
  void upload() { check(hipMemcpy(device, host.data(), host.size()*sizeof(T), hipMemcpyHostToDevice), "upload"); }
  void download() { check(hipMemcpy(host.data(), device, host.size()*sizeof(T), hipMemcpyDeviceToHost), "download"); }
  ~Buffer() { (void)hipFree(device); }
};
static void launch(hipModule_t module, const char *name, unsigned block, void **args) {
  hipFunction_t function{};
  check(hipModuleGetFunction(&function, module, name), name);
  check(hipModuleLaunchKernel(function, 1,1,1,block,1,1,0,nullptr,args,nullptr), "launch");
  check(hipDeviceSynchronize(), "synchronize");
}
template <class T> static void compare(const char *name, const std::vector<T> &actual,
                                     const std::vector<double> &expected,
                                     double atol, double rtol) {
  double max_error=0;
  for (size_t i=0;i<actual.size();++i) {
    double observed=static_cast<double>(actual[i]);
    double error=std::abs(observed-expected[i]);
    max_error=std::max(max_error,error);
    if (!std::isfinite(observed) || error>atol+rtol*std::abs(expected[i])) {
      std::fprintf(stderr,"%s i=%zu expected=%.12g actual=%.12g error=%.12g\n",name,i,expected[i],observed,error);
      std::exit(1);
    }
  }
  std::printf("PASS %s elements=%zu max_abs_error=%.9g atol=%.9g rtol=%.9g\n",name,actual.size(),max_error,atol,rtol);
}

int main(int argc,char **argv) {
  if (argc!=2) { std::fprintf(stderr,"usage: %s portable-f16.hsaco\n",argv[0]); return 2; }
  hipDeviceProp_t device{};
  check(hipGetDeviceProperties(&device,0),"device properties");
  if (std::string(device.gcnArchName).find("gfx950")!=0) return 2;
  hipModule_t module{};
  check(hipModuleLoad(&module,argv[1]),"load native corpus");
  for (std::string name : {"relu_f16","silu_f16","sigmoid_f16","swiglu_f16"}) {
    unsigned n=name=="silu_f16"?512:1024;
    unsigned block=name=="sigmoid_f16"?256:128;
    Buffer<_Float16> x(n),value(n),out(n);
    std::vector<double> expected(n);
    for (unsigned i=0;i<n;++i) {
      x.host[i]=(_Float16)((int(i%65)-32)*.125f);
      value.host[i]=(_Float16)((int(i%17)-8)*.125f);
      double a=(double)x.host[i],b=(double)value.host[i];
      expected[i]=name=="relu_f16"?std::max(a,0.):1./(1.+std::exp(-a));
      if (name=="silu_f16" || name=="swiglu_f16") expected[i]*=a;
      if (name=="swiglu_f16") expected[i]*=b;
    }
    x.upload();value.upload();
    void *two[]={&x.device,&out.device};
    void *three[]={&x.device,&value.device,&out.device};
    launch(module,name.c_str(),block,name=="swiglu_f16"?three:two);
    out.download();compare(name.c_str(),out.host,expected,0.00003,0.002);
  }
  {
    Buffer<_Float16> x(128),cosine(128),sine(128),out(128);
    std::vector<double> expected(128);
    for (unsigned i=0;i<128;++i) {
      x.host[i]=(_Float16)((int(i%37)-18)*.125f);
      cosine.host[i]=(_Float16).5f;sine.host[i]=(_Float16).25f;
    }
    for(unsigned i=0;i<128;++i) {
      unsigned partner=i<64?i+64:i-64;
      expected[i]=(double)x.host[i]*.5+(i<64?-1.:1.)*(double)x.host[partner]*.25;
    }
    x.upload();cosine.upload();sine.upload();
    void *args[]={&x.device,&cosine.device,&sine.device,&out.device};
    launch(module,"rope_f16",128,args);out.download();compare("rope_f16",out.host,expected,0,0);
  }
  {
    Buffer<_Float16> x(256);Buffer<float> out(1);out.host[0]=1.25f;
    double expected=1.25;
    for(unsigned i=0;i<256;++i){x.host[i]=(_Float16)((int(i%17)-8)*.125f);expected+=(double)x.host[i];}
    x.upload();out.upload();void *args[]={&x.device,&out.device};
    launch(module,"reduction_f16",128,args);out.download();compare("reduction_f16",out.host,{expected},0,0);
  }
  {
    Buffer<_Float16> x(1024),out(1024);std::vector<double> expected(1024);
    for(unsigned i=0;i<1024;++i)x.host[i]=(_Float16)((int(i%33)-16)*.125f);
    for(unsigned row=0;row<4;++row){double total=0;for(unsigned j=0;j<256;++j)total+=std::exp((double)x.host[row*256+j]);for(unsigned j=0;j<256;++j)expected[row*256+j]=std::exp((double)x.host[row*256+j])/total;}
    unsigned input_stride=256,output_stride=256,n_rows=4,n_cols=256;
    x.upload();void *args[]={&out.device,&x.device,&input_stride,&output_stride,&n_rows,&n_cols};
    launch(module,"softmax_f16",128,args);out.download();compare("softmax_f16",out.host,expected,0.000002,0.002);
  }
  {
    Buffer<_Float16>x(4096),weight(4096),out(4096);std::vector<double>expected(4096);double squares=0;
    for(unsigned i=0;i<4096;++i){x.host[i]=(_Float16)((int(i%33)-16)*.125f);weight.host[i]=(_Float16)(.5f+(i%9)*.125f);squares+=(double)x.host[i]*(double)x.host[i];}
    double scale=1./std::sqrt(squares/4096.+(double)1.e-6f);
    for(unsigned i=0;i<4096;++i)expected[i]=(double)x.host[i]*(double)weight.host[i]*scale;
    x.upload();weight.upload();void *args[]={&x.device,&weight.device,&out.device};
    launch(module,"rmsnorm_f16",512,args);out.download();compare("rmsnorm_f16",out.host,expected,0.00001,0.002);
  }
  {
    Buffer<_Float16>a(32*4096),x(4096),out(32);std::vector<double>expected(32,0);
    for(unsigned k=0;k<4096;++k)x.host[k]=(_Float16)((int(k%17)-8)*.125f);
    for(unsigned row=0;row<32;++row)for(unsigned k=0;k<4096;++k){a.host[row*4096+k]=(_Float16)((int((row*7+k)%23)-11)*.125f);expected[row]+=(double)a.host[row*4096+k]*(double)x.host[k];}
    a.upload();x.upload();void *args[]={&a.device,&x.device,&out.device};
    launch(module,"matvec_f16",128,args);out.download();compare("matvec_f16",out.host,expected,0.00001,0.002);
  }
  check(hipModuleUnload(module),"unload");
  std::printf("PASS exact-native f16 corpus:9 kernels device=%s arch=%s\n",device.name,device.gcnArchName);
}

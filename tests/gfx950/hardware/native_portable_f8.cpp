// Independent OCP E4M3 decoding and numeric checks of exact portable-f8.s.
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

static void check(hipError_t error, const char *operation) {
  if (error != hipSuccess) { std::fprintf(stderr,"%s: %s\n",operation,hipGetErrorString(error)); std::exit(1); }
}
template<class T> struct Buffer {
  std::vector<T> host; T *device{};
  explicit Buffer(size_t n):host(n) { check(hipMalloc(&device,n*sizeof(T)),"allocate"); check(hipMemset(device,0xff,n*sizeof(T)),"initialize storage sentinel"); }
  void upload(){check(hipMemcpy(device,host.data(),host.size()*sizeof(T),hipMemcpyHostToDevice),"upload");}
  void download(){check(hipMemcpy(host.data(),device,host.size()*sizeof(T),hipMemcpyDeviceToHost),"download");}
  ~Buffer(){(void)hipFree(device);}
};
static double decode(unsigned char byte) {
  unsigned exponent=(byte>>3)&15, fraction=byte&7;
  double value=exponent?std::ldexp(1.+fraction/8.,int(exponent)-7):std::ldexp(double(fraction),-9);
  if(exponent==15 && fraction==7) value=NAN;
  return byte&128?-value:value;
}
static unsigned char pattern(unsigned i) { return ((i*17)%73) | ((i&1)?128:0); }
static void launch(hipModule_t module,const char *name,unsigned block,void **args) {
  hipFunction_t function{};check(hipModuleGetFunction(&function,module,name),name);
  check(hipModuleLaunchKernel(function,1,1,1,block,1,1,0,nullptr,args,nullptr),"launch");
  check(hipDeviceSynchronize(),"synchronize");
}
static void compare(const char *name,const std::vector<_Float16>& actual,const std::vector<double>& expected,
                    double atol=0.00003,double rtol=0.002) {
  double maximum=0;
  for(size_t i=0;i<actual.size();++i){double a=(double)actual[i],error=std::abs(a-expected[i]);maximum=std::max(maximum,error);
    if(!std::isfinite(a)||error>atol+rtol*std::abs(expected[i])){
      std::fprintf(stderr,"%s i=%zu expected=%.12g actual=%.12g error=%.12g\n",name,i,expected[i],a,error);std::exit(1);}}
  std::printf("PASS %s elements=%zu max_abs_error=%.9g atol=%.9g rtol=%.9g\n",name,actual.size(),maximum,atol,rtol);
}
int main(int argc,char **argv) {
  if(argc!=2){std::fprintf(stderr,"usage: %s portable-f8.hsaco\n",argv[0]);return 2;}
  hipDeviceProp_t device{};check(hipGetDeviceProperties(&device,0),"device properties");
  if(std::string(device.gcnArchName).find("gfx950")!=0)return 2;
  hipModule_t module{};check(hipModuleLoad(&module,argv[1]),"load exact FP8 assembly");
  for(std::string name:{"relu_f8","silu_f8","sigmoid_f8","swiglu_f8"}) {
    unsigned n=(name=="relu_f8"||name=="swiglu_f8")?2048:1024;
    unsigned block=name=="silu_f8"?256:name=="swiglu_f8"?512:128;
    Buffer<unsigned char>x(n),value(n);Buffer<_Float16>out(n);std::vector<double>expected(n);
    for(unsigned i=0;i<n;++i){x.host[i]=pattern(i);value.host[i]=pattern(i+11);double a=decode(x.host[i]);
      expected[i]=name=="relu_f8"?std::max(a,0.):1./(1.+std::exp(-a));
      if(name=="silu_f8"||name=="swiglu_f8")expected[i]*=a;
      if(name=="swiglu_f8")expected[i]*=decode(value.host[i]);}
    x.upload();value.upload();void *two[]={&x.device,&out.device};void *three[]={&x.device,&value.device,&out.device};
    launch(module,name.c_str(),block,name=="swiglu_f8"?three:two);out.download();compare(name.c_str(),out.host,expected);
  }
  {
    Buffer<unsigned char>x(128),cosine(128),sine(128);Buffer<_Float16>out(128);std::vector<double>expected(128);
    for(unsigned i=0;i<128;++i){x.host[i]=pattern(i);cosine.host[i]=0x30;sine.host[i]=0x28;}
    for(unsigned i=0;i<128;++i){double a=decode(x.host[i]),partner=(i<64?-1.:1.)*decode(x.host[i^64]);
      _Float16 first=(_Float16)((_Float16)(a*.25)*(_Float16).5),second=(_Float16)((_Float16)(partner*.25)*(_Float16).25);
      expected[i]=(double)(_Float16)((_Float16)(first+second)*(_Float16)4);}
    x.upload();cosine.upload();sine.upload();void *args[]={&x.device,&cosine.device,&sine.device,&out.device};
    launch(module,"rope_f8",128,args);out.download();compare("rope_f8",out.host,expected,0,0);
  }
  {
    Buffer<unsigned char>x(4096),weight(4096);Buffer<_Float16>out(4096);std::vector<double>expected(4096);double squares=0;
    for(unsigned i=0;i<4096;++i){x.host[i]=pattern(i);weight.host[i]=pattern(i+7);double a=decode(x.host[i]);squares+=a*a;}
    double scale=1./std::sqrt(squares/4096.+(double)1.e-6f);
    for(unsigned i=0;i<4096;++i)expected[i]=decode(x.host[i])*scale*decode(weight.host[i]);
    x.upload();weight.upload();void *args[]={&x.device,&weight.device,&out.device};
    launch(module,"rmsnorm_f8",512,args);out.download();compare("rmsnorm_f8",out.host,expected);
  }
  {
    Buffer<unsigned char>a(64*4096),x(4096);Buffer<_Float16>out(64);std::vector<double>expected(64,0);
    for(unsigned k=0;k<4096;++k)x.host[k]=pattern(k);
    for(unsigned row=0;row<64;++row)for(unsigned k=0;k<4096;++k){a.host[row*4096+k]=pattern(row*7+k+3);expected[row]+=decode(a.host[row*4096+k])*decode(x.host[k]);}
    a.upload();x.upload();void *args[]={&a.device,&x.device,&out.device};
    launch(module,"matvec_f8",128,args);out.download();compare("matvec_f8",out.host,expected);
  }
  check(hipModuleUnload(module),"unload");
  std::printf("PASS exact-native OCP E4M3 corpus:7 kernels device=%s arch=%s\n",device.name,device.gcnArchName);
}

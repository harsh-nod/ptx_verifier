// Independent dense softmax(QK^T/8)V reference for exact native attention.
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

static void check(hipError_t error,const char *operation){if(error!=hipSuccess){std::fprintf(stderr,"%s: %s\n",operation,hipGetErrorString(error));std::exit(1);}}
template<class T>struct Buffer{
  std::vector<T>host;T*device{};
  explicit Buffer(size_t n):host(n){check(hipMalloc(&device,n*sizeof(T)),"allocate");check(hipMemset(device,0xff,n*sizeof(T)),"initialize sentinel");}
  void upload(){check(hipMemcpy(device,host.data(),host.size()*sizeof(T),hipMemcpyHostToDevice),"upload");}
  void download(){check(hipMemcpy(host.data(),device,host.size()*sizeof(T),hipMemcpyDeviceToHost),"download");}
  ~Buffer(){(void)hipFree(device);}
};
static void test(hipModule_t module,const char *name,unsigned queries,unsigned keys){
  constexpr unsigned width=64;
  Buffer<_Float16>q(queries*width),k(keys*width),v(keys*width),out(queries*width);Buffer<float>lse(queries);
  hipFunction_t function{};check(hipModuleGetFunction(&function,module,name),"attention entry");
  double output_maximum=0,lse_maximum=0;
  for(unsigned seed=0;seed<3;++seed){
    for(unsigned row=0;row<queries;++row)for(unsigned d=0;d<width;++d)q.host[row*width+d]=(_Float16)((int((row*11+d*7+seed)%19)-9)*.0625f);
    for(unsigned row=0;row<keys;++row)for(unsigned d=0;d<width;++d){
      k.host[row*width+d]=(_Float16)((int((row*13+d*3+seed*5)%23)-11)*.0625f);
      v.host[row*width+d]=(_Float16)((int((row*17+d*5+seed*7)%29)-14)*.0625f);}
    q.upload();k.upload();v.upload();check(hipMemset(out.device,0xff,queries*width*sizeof(_Float16)),"reset output sentinel");check(hipMemset(lse.device,0xff,queries*sizeof(float)),"reset LSE sentinel");
    void *args[]={&q.device,&k.device,&v.device,&out.device,&lse.device};
    check(hipModuleLaunchKernel(function,1,1,1,128,1,1,0,nullptr,args,nullptr),"attention launch");check(hipDeviceSynchronize(),"attention synchronize");out.download();lse.download();
    std::vector<double>scores(keys),probabilities(keys);
    for(unsigned row=0;row<queries;++row){
      for(unsigned key=0;key<keys;++key){double dot=0;for(unsigned d=0;d<width;++d)dot+=(double)q.host[row*width+d]*(double)k.host[key*width+d];scores[key]=dot*.125;}
      double maximum=*std::max_element(scores.begin(),scores.end()),denominator=0;
      for(unsigned key=0;key<keys;++key){probabilities[key]=std::exp(scores[key]-maximum);denominator+=probabilities[key];}
      double expected_lse=maximum+std::log(denominator),lse_error=std::abs(lse.host[row]-expected_lse);lse_maximum=std::max(lse_maximum,lse_error);
      if(!std::isfinite(lse.host[row])||lse_error>0.00002){std::fprintf(stderr,"%s LSE seed=%u row=%u expected=%.12g actual=%.12g\n",name,seed,row,expected_lse,lse.host[row]);std::exit(1);}
      for(unsigned d=0;d<width;++d){double expected=0;for(unsigned key=0;key<keys;++key)expected+=probabilities[key]*(double)v.host[key*width+d];expected/=denominator;
        double actual=(double)out.host[row*width+d],error=std::abs(actual-expected);output_maximum=std::max(output_maximum,error);
        if(!std::isfinite(actual)||error>0.00008+0.002*std::abs(expected)){std::fprintf(stderr,"%s seed=%u row=%u d=%u expected=%.12g actual=%.12g\n",name,seed,row,d,expected,actual);std::exit(1);}}
    }
  }
  std::printf("PASS %s Q=%u T=%u D=64 patterns=3 output_checks=%u LSE_checks=%u max_output_abs_error=%.9g max_lse_abs_error=%.9g output_atol=8e-5 output_rtol=.002 lse_atol=2e-5\n",name,queries,keys,queries*64*3,queries*3,output_maximum,lse_maximum);
}
int main(int argc,char **argv){
  if(argc!=2){std::fprintf(stderr,"usage: %s native-flash-attention.hsaco\n",argv[0]);return 2;}
  hipDeviceProp_t device{};check(hipGetDeviceProperties(&device,0),"device properties");if(std::string(device.gcnArchName).find("gfx950")!=0)return 2;
  hipModule_t module{};check(hipModuleLoad(&module,argv[1]),"load exact attention assembly");
  test(module,"flash_attention_reduced",32,32);test(module,"flash_attention_full",128,1024);
  check(hipModuleUnload(module),"unload");std::printf("PASS exact-native attention device=%s arch=%s\n",device.name,device.gcnArchName);
}

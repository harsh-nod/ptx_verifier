// Exact assembly validation of packed 3D IDs and two-wave LDS/MFMA pipelines.
#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

static void check(hipError_t error,const char *operation){
  if(error!=hipSuccess){std::fprintf(stderr,"%s: %s\n",operation,hipGetErrorString(error));std::exit(1);}
}
template<class T>struct Buffer{
  std::vector<T>host;T*device{};
  explicit Buffer(size_t n):host(n){check(hipMalloc(&device,n*sizeof(T)),"allocate");}
  void upload(){check(hipMemcpy(device,host.data(),host.size()*sizeof(T),hipMemcpyHostToDevice),"upload");}
  void download(){check(hipMemcpy(host.data(),device,host.size()*sizeof(T),hipMemcpyDeviceToHost),"download");}
  ~Buffer(){(void)hipFree(device);}
};
template<class T>static void pipeline(const char *path,const char *kernel,unsigned ksize){
  hipModule_t module{};hipFunction_t function{};
  check(hipModuleLoad(&module,path),"load exact matrix assembly");
  check(hipModuleGetFunction(&function,module,kernel),"matrix entry");
  Buffer<T>a(32*ksize),b(ksize*16),out(32*16);
  for(unsigned seed=0;seed<17;++seed){
    for(unsigned row=0;row<32;++row)for(unsigned k=0;k<ksize;++k)
      a.host[row*ksize+k]=(T)((int((row*13+k*7+seed)%17)-8)*.125f);
    for(unsigned k=0;k<ksize;++k)for(unsigned col=0;col<16;++col)
      b.host[k*16+col]=(T)((int((k*11+col*5+seed)%19)-9)*.125f);
    for(auto &value:out.host)value=(T)-999;
    a.upload();b.upload();out.upload();void *args[]={&a.device,&b.device,&out.device};
    check(hipModuleLaunchKernel(function,1,1,1,128,1,1,0,nullptr,args,nullptr),"matrix launch");
    check(hipDeviceSynchronize(),"matrix synchronize");out.download();
    for(unsigned row=0;row<32;++row)for(unsigned col=0;col<16;++col){
      double sum=0;for(unsigned k=0;k<ksize;++k)sum+=(double)a.host[row*ksize+k]*(double)b.host[k*16+col];
      double expected=(double)(T)sum,actual=(double)out.host[row*16+col];
      if(actual!=expected){std::fprintf(stderr,"%s seed=%u row=%u col=%u expected=%.12g actual=%.12g\n",kernel,seed,row,col,expected,actual);std::exit(1);}
    }
  }
  std::printf("PASS %s M=32 N=16 K=%u patterns=17 output_checks=8704 exact_dyadic=true\n",kernel,ksize);
  check(hipModuleUnload(module),"unload matrix");
}
int main(int argc,char **argv){
  if(argc!=4){std::fprintf(stderr,"usage: %s ids.hsaco pipeline-f32.hsaco pipeline-f16.hsaco\n",argv[0]);return 2;}
  hipDeviceProp_t device{};check(hipGetDeviceProperties(&device,0),"device properties");
  if(std::string(device.gcnArchName).find("gfx950")!=0)return 2;
  hipModule_t module{};hipFunction_t function{};
  check(hipModuleLoad(&module,argv[1]),"load 3D assembly");check(hipModuleGetFunction(&function,module,"ids_3d"),"3D entry");
  Buffer<float>out(24);for(auto &value:out.host)value=-999;out.upload();void *args[]={&out.device};
  check(hipModuleLaunchKernel(function,1,1,1,4,3,2,0,nullptr,args,nullptr),"3D launch");check(hipDeviceSynchronize(),"3D synchronize");out.download();
  for(unsigned z=0;z<2;++z)for(unsigned y=0;y<3;++y)for(unsigned x=0;x<4;++x){
    unsigned index=x+4*(y+3*z);float expected=x+10*y+100*z;
    if(out.host[index]!=expected){std::fprintf(stderr,"3D index=%u expected=%g actual=%g\n",index,expected,out.host[index]);return 1;}}
  std::printf("PASS ids_3d block=4,3,2 output_checks=24 exact=true\n");check(hipModuleUnload(module),"unload IDs");
  pipeline<float>(argv[2],"pipelined_mfma_f32",8);
  pipeline<_Float16>(argv[3],"pipelined_mfma_f16",32);
  std::printf("PASS exact-native IDs and pipelines device=%s arch=%s\n",device.name,device.gcnArchName);
}

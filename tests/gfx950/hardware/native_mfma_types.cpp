// Basis and dense coordinate checks of native CDNA4 F16/BF16/FP8 MFMA.
#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

static void check(hipError_t error,const char *operation){if(error!=hipSuccess){std::fprintf(stderr,"%s: %s\n",operation,hipGetErrorString(error));std::exit(1);}}
template<class T>struct Buffer{
  std::vector<T>host;T*device{};
  explicit Buffer(size_t n):host(n){check(hipMalloc(&device,n*sizeof(T)),"allocate");}
  void upload(){check(hipMemcpy(device,host.data(),host.size()*sizeof(T),hipMemcpyHostToDevice),"upload");}
  void download(){check(hipMemcpy(host.data(),device,host.size()*sizeof(T),hipMemcpyDeviceToHost),"download");}
  ~Buffer(){(void)hipFree(device);}
};
static uint16_t half_bits(float value){_Float16 half=(_Float16)value;uint16_t bits;std::memcpy(&bits,&half,2);return bits;}
static uint16_t bf16_bits(float value){uint32_t bits;std::memcpy(&bits,&value,4);return bits>>16;}
static unsigned char e4m3_bits(float value){const unsigned char codes[]={0,0x38,0x40,0x44,0x48,0x4a,0x4c,0x4e,0x50};return codes[(unsigned)value];}

template<class Storage,class Encode>static void test(hipModule_t module,const char *name,unsigned msize,unsigned ksize,Encode encode,bool fp8){
  unsigned items=msize*ksize/64,count=msize*ksize,outputs=msize*msize;
  Buffer<Storage>physical_a(64*items),physical_b(64*items);Buffer<float>out(outputs);
  std::vector<float>a(count),b(count);
  hipFunction_t function{};check(hipModuleGetFunction(&function,module,name),"MFMA entry");
  for(unsigned pattern=0;pattern<2*count+1;++pattern){
    for(unsigned row=0;row<msize;++row)for(unsigned k=0;k<ksize;++k)
      a[row*ksize+k]=pattern<count?(row*ksize+k==pattern?1.f:0.f):1.f+(row*3+k*5)%8;
    for(unsigned k=0;k<ksize;++k)for(unsigned col=0;col<msize;++col)
      b[k*msize+col]=pattern>=count&&pattern<2*count?(k*msize+col==pattern-count?1.f:0.f):1.f+(k*7+col*3)%8;
    for(unsigned coordinate=0;coordinate<msize;++coordinate)for(unsigned k=0;k<ksize;++k){
      unsigned groups=64/msize;
      unsigned lane=fp8?coordinate+msize*((k/16)%groups):coordinate+msize*(k/items);
      unsigned component=fp8?k%16+16*(k/(16*groups)):k%items;
      physical_a.host[lane*items+component]=encode(a[coordinate*ksize+k]);
      physical_b.host[lane*items+component]=encode(b[k*msize+coordinate]);
    }
    physical_a.upload();physical_b.upload();check(hipMemset(out.device,0xff,outputs*sizeof(float)),"initialize output sentinel");void *args[]={&physical_a.device,&physical_b.device,&out.device};
    check(hipModuleLaunchKernel(function,1,1,1,64,1,1,0,nullptr,args,nullptr),"MFMA launch");check(hipDeviceSynchronize(),"MFMA synchronize");out.download();
    for(unsigned row=0;row<msize;++row)for(unsigned col=0;col<msize;++col){
      double expected=0;for(unsigned k=0;k<ksize;++k)expected+=(double)a[row*ksize+k]*b[k*msize+col];
      unsigned groups=64/msize;
      unsigned lane=msize*((row/4)%groups)+col,item=(row/(4*groups))*4+row%4;
      unsigned destination=lane*(outputs/64)+item;
      if(out.host[destination]!=expected){std::fprintf(stderr,"%s pattern=%u row=%u col=%u expected=%g actual=%g\n",name,pattern,row,col,expected,out.host[destination]);std::exit(1);}
    }
  }
  std::printf("PASS %s M=N=%u K=%u A_basis=%u B_basis=%u dense=1 output_checks=%u exact_integer=true\n",name,msize,ksize,count,count,(2*count+1)*outputs);
}
int main(int argc,char **argv){
  if(argc!=2){std::fprintf(stderr,"usage: %s cdna4-mfma-types.hsaco\n",argv[0]);return 2;}
  hipDeviceProp_t device{};check(hipGetDeviceProperties(&device,0),"device properties");if(std::string(device.gcnArchName).find("gfx950")!=0)return 2;
  hipModule_t module{};check(hipModuleLoad(&module,argv[1]),"load exact CDNA4 assembly");
  test<uint16_t>(module,"mfma_f16_k32",16,32,half_bits,false);
  test<uint16_t>(module,"mfma_bf16_k32",16,32,bf16_bits,false);
  test<unsigned char>(module,"mfma_e4m3_k128",16,128,e4m3_bits,true);
  test<unsigned char>(module,"mfma_e4m3_32_k64",32,64,e4m3_bits,true);
  check(hipModuleUnload(module),"unload");
  std::printf("PASS exact-native CDNA4 matrix types device=%s arch=%s\n",device.name,device.gcnArchName);
}

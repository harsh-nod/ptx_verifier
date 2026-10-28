// Numerical check for exact checked-in native-mamba2-scan.s, not a compiled
// GPU kernel in this driver. llvm-mc gfx950 -> ld.lld -shared -> HIP module.
// Run native-scan native-mamba2-scan.hsaco [patterns=3]. Selectedworkgroupzero.
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>
static void check(hipError_t e,const char *what) {if(e!=hipSuccess)throw std::runtime_error(std::string(what)+": "+hipGetErrorString(e));}
template<class T> struct Buffer {
  std::vector<T> host; T *device{};
  explicit Buffer(size_t n):host(n){check(hipMalloc(&device,n*sizeof(T)),"allocate");}
  ~Buffer(){if(device)(void)hipFree(device);}
  void upload(){check(hipMemcpy(device,host.data(),host.size()*sizeof(T),hipMemcpyHostToDevice),"upload");}
  void download(){check(hipMemcpy(host.data(),device,host.size()*sizeof(T),hipMemcpyDeviceToHost),"download");}
};
constexpr unsigned Rows=32, Features=128, Steps=128, State=32, Pitch=1024, Guard=64;
static uint16_t bits(_Float16 x){uint16_t b;std::memcpy(&b,&x,2);return b;}
static _Float16 from_bits(uint16_t b){_Float16 x;std::memcpy(&x,&b,2);return x;}
static uint32_t mix(uint32_t x){x^=x>>16;x*=0x7feb352dU;x^=x>>15;x*=0x846ca68bU;return x^(x>>16);}
static float coordinate(unsigned a,unsigned b,unsigned seed,uint32_t domain){return (int(mix(domain^(a+3)*0x9e3779b9U^(b+7)*0x85ebca6bU^(seed+11)*0xc2b2ae35U)%31)-15)/64.0f;}
struct Errors{double max_abs=0,max_rel=0;uint64_t values=0,gaps=0,guards=0;};
static Errors validate(const std::vector<_Float16>& actual,const std::vector<_Float16>& expected,bool zero) {
  Errors result;
  if(actual.size()!=Rows*Pitch+2*Guard||expected.size()!=Rows*Features)throw std::runtime_error("checker size");
  for(unsigned i=0;i<actual.size();++i){
    bool guard=i<Guard||i>=Guard+Rows*Pitch;
    unsigned q=i-Guard;
    bool gap=!guard&&q%Pitch>=Features;
    if(guard||gap){if(bits(actual[i])!=0x7e00)throw std::runtime_error(guard?"guard overwrite":"pitched gap overwrite");if(guard)++result.guards;else++result.gaps;continue;}
    unsigned row=q/Pitch,col=q%Pitch;
    if(bits(actual[i])==0x7e00)throw std::runtime_error("missing output");
    double got=float(actual[i]),want=float(expected[row*Features+col]);
    if(!std::isfinite(got)||!std::isfinite(want))throw std::runtime_error("nonfinite output");
    if(zero){if(bits(actual[i])!=0)throw std::runtime_error("out_x must be exact positivezero");}
    else {
      double abs=std::abs(got-want),rel=abs/std::max(std::abs(want),1e-20);
      result.max_abs=std::max(result.max_abs,abs);result.max_rel=std::max(result.max_rel,rel);
      if(abs>3e-5+0.002*std::abs(want))throw std::runtime_error("numerical mismatch row="+std::to_string(row)+" col="+std::to_string(col)+" got="+std::to_string(got)+" want="+std::to_string(want));
    }
    ++result.values;
  }
  return result;
}
static void host_controls(){
  std::vector<_Float16> expected(Rows*Features,(_Float16)1),good(Rows*Pitch+2*Guard,from_bits(0x7e00));
  for(unsigned r=0;r<Rows;++r)for(unsigned c=0;c<Features;++c)good[Guard+r*Pitch+c]=(_Float16)1;
  (void)validate(good,expected,false);
  for(unsigned index:{Guard,Guard+Features,0u,unsigned(good.size()-1)}){auto bad=good;bad[index]=index==Guard?from_bits(0x7e00):(_Float16)0;bool rejected=false;try{(void)validate(bad,expected,false);}catch(const std::runtime_error&){rejected=true;}if(!rejected)throw std::runtime_error("host negative not detected");}
  bool rejected=false;try{(void)validate(good,std::vector<_Float16>(Rows*Features,(_Float16)0),true);}catch(const std::runtime_error&){rejected=true;}if(!rejected)throw std::runtime_error("zero companion negative not detected");
  std::puts("PASS host checker detects missing output, all pitched gaps, prefix/suffix guards and nonzero companion");
}
int main(int argc,char **argv){try{
  if(argc<2)throw std::runtime_error("usage: native-scan SCAN.hsaco [patterns=3]");host_controls();
  hipDeviceProp_t props{};check(hipGetDeviceProperties(&props,0),"device properties");
  std::printf("DEVICE name=%s arch=%s wave=%d selected_workgroup=0,0,0\n",props.name,props.gcnArchName,props.warpSize);
  hipModule_t module{};check(hipModuleLoad(&module,argv[1]),"load exact native assembly");hipFunction_t function{};check(hipModuleGetFunction(&function,module,"mamba2_chunk_scan_full"),"lookup");
  unsigned patterns=argc>2?unsigned(std::atoi(argv[2])):3;if(patterns<3)throw std::runtime_error("at least3 independent patterns required");
  Buffer<float> cb(Rows*Steps),prev(Features*State),dt(Steps),da(Steps);
  Buffer<_Float16> x(Steps*Pitch),c(Rows*64),out(Rows*Pitch+2*Guard),out_x(Rows*Pitch+2*Guard);
  for(unsigned pattern=0;pattern<patterns;++pattern){
    for(unsigned r=0;r<Rows;++r)for(unsigned k=0;k<Steps;++k)cb.host[r*Steps+k]=pattern==0?0:coordinate(r,k,pattern,0x193a);
    for(unsigned n=0;n<Features;++n)for(unsigned j=0;j<State;++j)prev.host[n*State+j]=pattern==1?0:coordinate(n,j,pattern,0x35b9)+float((n+j)%7)/10000.0f;
    for(unsigned r=0;r<Steps;++r){dt.host[r]=0.125f+float(mix(r+pattern*31)%17)/64.0f;da.host[r]=coordinate(r,0,pattern,0x5cb1);for(unsigned n=0;n<Pitch;++n)x.host[r*Pitch+n]=(_Float16)coordinate(r,n,pattern,0x7d5f);}
    for(unsigned r=0;r<Rows;++r)for(unsigned j=0;j<64;++j)c.host[r*64+j]=(_Float16)coordinate(r,j,pattern,0x9ec3);
    std::vector<_Float16> reference(Rows*Features),zero(Rows*Features,(_Float16)0);
    for(unsigned r=0;r<Rows;++r)for(unsigned n=0;n<Features;++n){
      float state=0;for(unsigned j=0;j<State;++j)state=std::fma(float(c.host[r*64+j]),float((_Float16)prev.host[n*State+j]),state);
      state*=std::exp(da.host[r]);float scan=0;
      for(unsigned k=0;k<Steps;++k){float decay=std::exp(std::min(da.host[r]-da.host[k],0.0f));float weighted=cb.host[r*Steps+k]*decay;weighted*=dt.host[k];scan=std::fma(float((_Float16)weighted),float(x.host[k*Pitch+n]),scan);}
      reference[r*Features+n]=(_Float16)(state+scan);
    }
    cb.upload();prev.upload();dt.upload();da.upload();x.upload();c.upload();std::fill(out.host.begin(),out.host.end(),from_bits(0x7e00));std::fill(out_x.host.begin(),out_x.host.end(),from_bits(0x7e00));out.upload();out_x.upload();
    _Float16 *out_ptr=out.device+Guard,*zero_ptr=out_x.device+Guard;void *args[]={&cb.device,&x.device,&c.device,&prev.device,&dt.device,&da.device,&out_ptr,&zero_ptr};
    check(hipModuleLaunchKernel(function,1,1,1,128,1,1,0,nullptr,args,nullptr),"launch exact native workgroup");check(hipDeviceSynchronize(),"synchronize");out.download();out_x.download();
    auto errors=validate(out.host,reference,false),zeros=validate(out_x.host,zero,true);
    std::printf("PASS mamba2_chunk_scan_full pattern=%u mode=%s outputs=%llu companion_zeros=%llu gaps=%llu guards=%llu max_abs=%.12g max_rel=%.12g atol=3e-5 rtol=.002 rows32 features128 stateK32 scanK128 Xpitch1024 Cpitch64\n",pattern,pattern==0?"state_only":pattern==1?"scan_only":"mixed",(unsigned long long)errors.values,(unsigned long long)zeros.values,(unsigned long long)(errors.gaps+zeros.gaps),(unsigned long long)(errors.guards+zeros.guards),errors.max_abs,errors.max_rel);
  }
  check(hipModuleUnload(module),"unload");return 0;
}catch(const std::exception&e){std::fprintf(stderr,"FAIL %s\n",e.what());return 1;}}

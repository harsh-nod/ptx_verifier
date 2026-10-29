; Actual native16-bit expected-count boundaries, not PTX byte-credit arithmetic.
target triple = "amdgcn-amd-amdhsa"
@counter = internal addrspace(3) global target("amdgcn.named.barrier", 0) poison

define amdgpu_kernel void @named_expected_one() #0 {
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @counter, i32 1)
  ret void
}
define amdgpu_kernel void @named_expected_maximum() #0 {
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @counter, i32 65535)
  ret void
}
; Deliberate CPU-only non-NULL count0 control.
define amdgpu_kernel void @named_expected_zero() #0 {
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @counter, i32 0)
  ret void
}
; NULL is a distinct no-op and cannot inherit the non-NULL count0 rejection.
define amdgpu_kernel void @named_null_zero() #0 {
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) null, i32 0)
  ret void
}

declare void @llvm.amdgcn.s.barrier.init(ptr addrspace(3), i32)
attributes #0 = { "target-cpu"="gfx1250" "target-features"="+wavefrontsize32" "amdgpu-flat-work-group-size"="32,32" }

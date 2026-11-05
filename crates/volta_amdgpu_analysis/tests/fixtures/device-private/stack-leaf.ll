; New complete compiler fixture: active per-work-item volatile private DWORD.
; Public LLVM source only; no generated instruction is removed or rewritten.
target triple = "amdgcn-amd-amdhsa"
declare i32 @llvm.amdgcn.workitem.id.x() #2

define hidden float @stack_leaf(float %x) #0 {
entry:
  %slot = alloca float, align 4, addrspace(5)
  store volatile float %x, ptr addrspace(5) %slot, align 4
  %saved = load volatile float, ptr addrspace(5) %slot, align 4
  %sum = fadd float %saved, 1.000000e+00
  ret float %sum
}

define amdgpu_kernel void @stack_leaf_copy64(ptr addrspace(1) noalias %out, ptr addrspace(1) noalias %in) #1 {
entry:
  %lane = call i32 @llvm.amdgcn.workitem.id.x()
  %index = zext i32 %lane to i64
  %src = getelementptr inbounds float, ptr addrspace(1) %in, i64 %index
  %value = load float, ptr addrspace(1) %src, align 4
  %sum = call float @stack_leaf(float %value)
  %dst = getelementptr inbounds float, ptr addrspace(1) %out, i64 %index
  store float %sum, ptr addrspace(1) %dst, align 4
  ret void
}
attributes #0 = { noinline nounwind "amdgpu-no-dispatch-ptr" "amdgpu-no-queue-ptr" "amdgpu-no-dispatch-id" "amdgpu-no-implicitarg-ptr" }
attributes #1 = { nounwind "amdgpu-flat-work-group-size"="64,64" "amdgpu-no-dispatch-ptr" "amdgpu-no-queue-ptr" "amdgpu-no-dispatch-id" "amdgpu-no-implicitarg-ptr" }
attributes #2 = { nounwind memory(none) speculatable }

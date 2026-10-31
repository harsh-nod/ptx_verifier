; Complete 64-lane F32 copy/add module with an actual noinline device call.
; Neither function depends on dispatch/queue/implicitarg pointer or dispatch ID.
target triple = "amdgcn-amd-amdhsa"
declare i32 @llvm.amdgcn.workitem.id.x() #2

define hidden float @qualified_leaf_add1(float %x) #0 {
entry:
  %sum = fadd float %x, 1.000000e+00
  ret float %sum
}

define amdgpu_kernel void @qualified_leaf_add1_copy64(ptr addrspace(1) noalias %out, ptr addrspace(1) noalias %in) #1 {
entry:
  %lane = call i32 @llvm.amdgcn.workitem.id.x()
  %index = zext i32 %lane to i64
  %src = getelementptr inbounds float, ptr addrspace(1) %in, i64 %index
  %value = load float, ptr addrspace(1) %src, align 4
  %sum = call float @qualified_leaf_add1(float %value)
  %dst = getelementptr inbounds float, ptr addrspace(1) %out, i64 %index
  store float %sum, ptr addrspace(1) %dst, align 4
  ret void
}
attributes #0 = { noinline nounwind memory(none) "amdgpu-no-dispatch-ptr" "amdgpu-no-queue-ptr" "amdgpu-no-dispatch-id" "amdgpu-no-implicitarg-ptr" }
attributes #1 = { nounwind "amdgpu-flat-work-group-size"="64,64" "amdgpu-no-dispatch-ptr" "amdgpu-no-queue-ptr" "amdgpu-no-dispatch-id" "amdgpu-no-implicitarg-ptr" }
attributes #2 = { nounwind memory(none) speculatable }

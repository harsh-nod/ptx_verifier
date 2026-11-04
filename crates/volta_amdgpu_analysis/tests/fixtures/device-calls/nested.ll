; A complete standalone source module: native functions are never extracted.
target triple = "amdgcn-amd-amdhsa"
define hidden i32 @leaf(i32 %x) #0 {
entry:
  %sum = add i32 %x, 4
  ret i32 %sum
}
define hidden i32 @outer(i32 %x) #0 {
entry:
  %part = call i32 @leaf(i32 %x)
  %sum = add i32 %part, 3
  ret i32 %sum
}
define amdgpu_kernel void @device_call_nested(ptr addrspace(1) %out) #1 {
entry:
  %sum = call i32 @outer(i32 0)
  store i32 %sum, ptr addrspace(1) %out, align 4
  ret void
}
attributes #0 = { noinline nounwind memory(none) }
attributes #1 = { nounwind "amdgpu-flat-work-group-size"="1,64" }

; Allocated native resources and ordinary payload remain distinct.
target triple = "amdgcn-amd-amdhsa"
@protocol_bar = internal addrspace(3) global target("amdgcn.named.barrier", 0) poison
@protocol_word = internal addrspace(3) global float poison, align 4

define amdgpu_kernel void @named_initialization_42(ptr addrspace(1) %out, i32 %initialize_late) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  br i1 %producer, label %init, label %rendezvous
init:
  %late = icmp ne i32 %initialize_late, 0
  br i1 %late, label %rendezvous, label %initialize
initialize:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @protocol_bar, i32 1)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @protocol_bar)
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %produce, label %consume
produce:
  %lead = icmp eq i32 %tid, 0
  br i1 %lead, label %write, label %signal
write:
  ; Keep a real F32 value role: an untyped MOV/store alone is also valid U32 bits.
  %typed42 = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 4.200000e+01)
  store volatile float %typed42, ptr addrspace(3) @protocol_word, align 4
  br label %signal
signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @protocol_bar, i32 0)
  br label %end
consume:
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %reader = icmp eq i32 %tid, 32
  br i1 %reader, label %read, label %end
read:
  %value = load volatile float, ptr addrspace(3) @protocol_word, align 4
  %op = getelementptr float, ptr addrspace(1) %out, i32 1
  store float %value, ptr addrspace(1) %op, align 4
  br label %end
end:
  ret void
}

define amdgpu_kernel void @named_live_reinitialization_42(ptr addrspace(1) %out, i32 %reinitialize_live) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  br i1 %producer, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @protocol_bar, i32 1)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @protocol_bar)
  call void @llvm.amdgcn.s.barrier()
  %again = icmp ne i32 %reinitialize_live, 0
  %reset = and i1 %producer, %again
  br i1 %reset, label %resetlive, label %dispatch
resetlive:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @protocol_bar, i32 1)
  br label %dispatch
dispatch:
  br i1 %producer, label %produce, label %consume
produce:
  %lead = icmp eq i32 %tid, 0
  br i1 %lead, label %write, label %signal
write:
  ; Keep a real F32 value role: an untyped MOV/store alone is also valid U32 bits.
  %typed42 = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 4.200000e+01)
  store volatile float %typed42, ptr addrspace(3) @protocol_word, align 4
  br label %signal
signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @protocol_bar, i32 0)
  br label %end
consume:
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %reader = icmp eq i32 %tid, 32
  br i1 %reader, label %read, label %end
read:
  %value = load volatile float, ptr addrspace(3) @protocol_word, align 4
  %op = getelementptr float, ptr addrspace(1) %out, i32 1
  store float %value, ptr addrspace(1) %op, align 4
  br label %end
end:
  ret void
}

define amdgpu_kernel void @named_new_lifetime_count_change(ptr addrspace(1) %out, i32 %ordered) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  %lead = icmp eq i32 %tid, 0
  %reader = icmp eq i32 %tid, 32
  br i1 %producer, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @protocol_bar, i32 2)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @protocol_bar)
  br i1 %lead, label %write, label %signal
write:
  %seven = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  store volatile float %seven, ptr addrspace(3) @protocol_word, align 4
  br label %signal
signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @protocol_bar, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br i1 %reader, label %read, label %leave
read:
  %value = load volatile float, ptr addrspace(3) @protocol_word, align 4
  store float %value, ptr addrspace(1) %out, align 4
  br label %leave
leave:
  call void @llvm.amdgcn.s.barrier.leave(i16 1)
  %gate = icmp ne i32 %ordered, 0
  br i1 %gate, label %lifetimegate, label %dispatchnew
lifetimegate:
  call void @llvm.amdgcn.s.barrier()
  br label %dispatchnew
dispatchnew:
  br i1 %producer, label %newinit, label %end
newinit:
  call void asm sideeffect "s_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @protocol_bar, i32 1)
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @protocol_bar)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @protocol_bar, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br i1 %lead, label %marker, label %end
marker:
  %seven2 = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  %op = getelementptr float, ptr addrspace(1) %out, i32 1
  store float %seven2, ptr addrspace(1) %op, align 4
  br label %end
end:
  ret void
}

define amdgpu_kernel void @named_count_mismatch_7(ptr addrspace(1) %out, i32 %unused) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  %lead = icmp eq i32 %tid, 0
  %reader = icmp eq i32 %tid, 32
  br i1 %producer, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @protocol_bar, i32 3)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @protocol_bar)
  br i1 %lead, label %write, label %signal
write:
  %seven = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  store volatile float %seven, ptr addrspace(3) @protocol_word, align 4
  br label %signal
signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @protocol_bar, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br i1 %reader, label %read, label %leave
read:
  %value = load volatile float, ptr addrspace(3) @protocol_word, align 4
  store float %value, ptr addrspace(1) %out, align 4
  br label %leave
leave:
  call void @llvm.amdgcn.s.barrier.leave(i16 1)
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %newinit, label %end
newinit:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @protocol_bar, i32 1)
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @protocol_bar)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @protocol_bar, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br i1 %lead, label %marker, label %end
marker:
  %seven2 = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  %op = getelementptr float, ptr addrspace(1) %out, i32 1
  store float %seven2, ptr addrspace(1) %op, align 4
  br label %end
end:
  ret void
}

define amdgpu_kernel void @named_wait_without_first_arrival(ptr addrspace(1) %out, i32 %unused) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  br i1 %producer, label %init, label %join
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @protocol_bar, i32 1)
  br label %join
join:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @protocol_bar)
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  ret void
}

declare i32 @llvm.amdgcn.workitem.id.x()
declare void @llvm.amdgcn.s.barrier() convergent nounwind
declare void @llvm.amdgcn.s.barrier.init(ptr addrspace(3), i32) convergent nounwind
declare void @llvm.amdgcn.s.barrier.join(ptr addrspace(3)) convergent nounwind
declare void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3), i32) convergent nounwind
declare void @llvm.amdgcn.s.barrier.wait(i16) convergent nounwind
declare void @llvm.amdgcn.s.barrier.leave(i16) convergent nounwind
attributes #0 = { nounwind "amdgpu-flat-work-group-size"="64,64" "target-cpu"="gfx1250" }

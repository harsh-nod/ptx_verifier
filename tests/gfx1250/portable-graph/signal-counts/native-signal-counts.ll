; Public native signal-time expected-count updates use M0 bits22:16.
target triple = "amdgcn-amd-amdhsa"
@count_bar = internal addrspace(3) global target("amdgcn.named.barrier", 0) poison
@count_word = internal addrspace(3) global float poison, align 4

define amdgpu_kernel void @named_phase_count_update7(ptr addrspace(1) %out) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  %lead = icmp eq i32 %tid, 0
  %reader = icmp eq i32 %tid, 32
  br i1 %producer, label %init, label %join
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @count_bar, i32 2)
  br label %join
join:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @count_bar)
  call void @llvm.amdgcn.s.barrier()
  br i1 %lead, label %write, label %signal
write:
  %seven = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  store volatile float %seven, ptr addrspace(3) @count_word, align 4
  br label %signal
signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 2)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br i1 %reader, label %read, label %gate
read:
  %value = load volatile float, ptr addrspace(3) @count_word, align 4
  store float %value, ptr addrspace(1) %out, align 4
  br label %gate
gate:
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %second, label %end
second:
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 1)
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

define amdgpu_kernel void @named_signal_count_deadlock7(ptr addrspace(1) %out) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  %lead = icmp eq i32 %tid, 0
  %reader = icmp eq i32 %tid, 32
  br i1 %producer, label %init, label %join
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @count_bar, i32 2)
  br label %join
join:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @count_bar)
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %dispatch, label %delayconsumer
delayconsumer:
  call void asm sideeffect "s_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0", "~{memory}"()
  br label %dispatch
dispatch:
  br i1 %lead, label %write, label %signal
write:
  %seven = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  store volatile float %seven, ptr addrspace(3) @count_word, align 4
  br label %signal
signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 3)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br i1 %reader, label %read, label %gate
read:
  %value = load volatile float, ptr addrspace(3) @count_word, align 4
  store float %value, ptr addrspace(1) %out, align 4
  br label %gate
gate:
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %second, label %end
second:
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 1)
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

define amdgpu_kernel void @named_signal_count_deadlock7_reverse(ptr addrspace(1) %out) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  %lead = icmp eq i32 %tid, 0
  %reader = icmp eq i32 %tid, 32
  br i1 %producer, label %init, label %join
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @count_bar, i32 2)
  br label %join
join:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @count_bar)
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %delayproducer, label %dispatch
delayproducer:
  call void asm sideeffect "s_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0", "~{memory}"()
  br label %dispatch
dispatch:
  br i1 %lead, label %write, label %signal
write:
  %seven = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  store volatile float %seven, ptr addrspace(3) @count_word, align 4
  br label %signal
signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 3)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br i1 %reader, label %read, label %gate
read:
  %value = load volatile float, ptr addrspace(3) @count_word, align 4
  store float %value, ptr addrspace(1) %out, align 4
  br label %gate
gate:
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %second, label %end
second:
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 1)
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

define amdgpu_kernel void @named_decrease_below_arrived7(ptr addrspace(1) %out) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  %lead = icmp eq i32 %tid, 0
  br i1 %producer, label %init, label %join
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @count_bar, i32 3)
  br label %join
join:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @count_bar)
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %produce, label %consume
produce:
  br i1 %lead, label %write, label %arrive
write:
  %seven = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  store volatile float %seven, ptr addrspace(3) @count_word, align 4
  br label %arrive
arrive:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 3)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 3)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  ret void
consume:
  call void asm sideeffect "s_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 1)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  ret void
}

define amdgpu_kernel void @named_equal_arrived_boundary7(ptr addrspace(1) %out) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  %lead = icmp eq i32 %tid, 0
  br i1 %producer, label %init, label %join
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @count_bar, i32 2)
  br label %join
join:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @count_bar)
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %produce, label %consume
produce:
  br i1 %lead, label %write, label %arrive
write:
  %seven = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  store volatile float %seven, ptr addrspace(3) @count_word, align 4
  br label %arrive
arrive:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 2)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  ret void
consume:
  call void asm sideeffect "s_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0\0As_nop 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 1)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  ret void
}

define amdgpu_kernel void @named_zero_update_marker7(ptr addrspace(1) %out) #1 {
entry:

  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @count_bar, i32 1)
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @count_bar)
  br label %loop
loop:
  %i = phi i32 [0, %entry], [%next, %loop]
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 0)
  %next = add nuw i32 %i, 1
  %done = icmp eq i32 %next, 1
  br i1 %done, label %wait, label %loop
wait:
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %seven = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  store float %seven, ptr addrspace(1) %out, align 4
  ret void
}

define amdgpu_kernel void @named_null_update_marker7(ptr addrspace(1) %out) #1 {
entry:
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) null, i32 127)
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @count_bar, i32 1)
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @count_bar)
  br label %loop
loop:
  %i = phi i32 [0, %entry], [%next, %loop]
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 0)
  %next = add nuw i32 %i, 1
  %done = icmp eq i32 %next, 1
  br i1 %done, label %wait, label %loop
wait:
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %seven = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  store float %seven, ptr addrspace(1) %out, align 4
  ret void
}

define amdgpu_kernel void @named_max_signal_count7(ptr addrspace(1) %out) #1 {
entry:

  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @count_bar, i32 1)
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @count_bar)
  br label %loop
loop:
  %i = phi i32 [0, %entry], [%next, %loop]
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @count_bar, i32 127)
  %next = add nuw i32 %i, 1
  %done = icmp eq i32 %next, 127
  br i1 %done, label %wait, label %loop
wait:
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %seven = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  store float %seven, ptr addrspace(1) %out, align 4
  ret void
}

declare i32 @llvm.amdgcn.workitem.id.x()
declare void @llvm.amdgcn.s.barrier() convergent nounwind
declare void @llvm.amdgcn.s.barrier.init(ptr addrspace(3), i32) convergent nounwind
declare void @llvm.amdgcn.s.barrier.join(ptr addrspace(3)) convergent nounwind
declare void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3), i32) convergent nounwind
declare void @llvm.amdgcn.s.barrier.wait(i16) convergent nounwind
attributes #0 = { nounwind "amdgpu-flat-work-group-size"="64,64" "target-cpu"="gfx1250" }
attributes #1 = { nounwind "amdgpu-flat-work-group-size"="1,64" "target-cpu"="gfx1250" }

; Genuine LLVM compiler input: allocated named objects and separate LDS payloads.
target triple = "amdgcn-amd-amdhsa"

@bar = internal addrspace(3) global target("amdgcn.named.barrier", 0) poison
@word = internal addrspace(3) global float poison, align 4

define amdgpu_kernel void @named_identity(ptr addrspace(1) %in, ptr addrspace(1) %out) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  br i1 %producer, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @bar, i32 2)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @bar)
  %lead = icmp eq i32 %tid, 0
  br i1 %lead, label %produce, label %signal
produce:
  %v = load float, ptr addrspace(1) %in, align 4
  store volatile float %v, ptr addrspace(3) @word, align 4
  br label %signal
signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @bar, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %consume = icmp eq i32 %tid, 32
  br i1 %consume, label %read, label %leave
read:
  %result = load volatile float, ptr addrspace(3) @word, align 4
  store float %result, ptr addrspace(1) %out, align 4
  br label %leave
leave:
  call void @llvm.amdgcn.s.barrier.leave(i16 1)
  ret void
}

define amdgpu_kernel void @named_encoded_wait_uses_last_join(ptr addrspace(1) %in, ptr addrspace(1) %out) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  br i1 %producer, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @bar, i32 2)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @bar)
  %lead = icmp eq i32 %tid, 0
  br i1 %lead, label %produce, label %signal
produce:
  %v = load float, ptr addrspace(1) %in, align 4
  store volatile float %v, ptr addrspace(3) @word, align 4
  br label %signal
signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @bar, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 2)
  %consume = icmp eq i32 %tid, 32
  br i1 %consume, label %read, label %leave
read:
  %result = load volatile float, ptr addrspace(3) @word, align 4
  store float %result, ptr addrspace(1) %out, align 4
  br label %leave
leave:
  call void @llvm.amdgcn.s.barrier.leave(i16 1)
  ret void
}


define amdgpu_kernel void @named_reinitialized_identity(ptr addrspace(1) %in, ptr addrspace(1) %out) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  %lead = icmp eq i32 %tid, 0
  %consume = icmp eq i32 %tid, 32
  br label %loop
loop:
  %stage = phi i32 [0, %entry], [%next, %recycle]
  br i1 %producer, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @bar, i32 2)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @bar)
  br i1 %lead, label %produce, label %signal
produce:
  %ip = getelementptr float, ptr addrspace(1) %in, i32 %stage
  %v = load float, ptr addrspace(1) %ip, align 4
  store volatile float %v, ptr addrspace(3) @word, align 4
  br label %signal
signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @bar, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br i1 %consume, label %read, label %leave
read:
  %result = load volatile float, ptr addrspace(3) @word, align 4
  %op = getelementptr float, ptr addrspace(1) %out, i32 %stage
  store float %result, ptr addrspace(1) %op, align 4
  br label %leave
leave:
  call void @llvm.amdgcn.s.barrier.leave(i16 1)
  call void @llvm.amdgcn.s.barrier()
  br label %recycle
recycle:
  %next = add nuw i32 %stage, 1
  %done = icmp eq i32 %next, 2
  br i1 %done, label %end, label %loop
end:
  ret void
}

define amdgpu_kernel void @named_subset_drop(ptr addrspace(1) %in, ptr addrspace(1) %out) #1 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %initializer = icmp ult i32 %tid, 32
  br i1 %initializer, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @bar, i32 3)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @bar)
  %dropper = icmp uge i32 %tid, 64
  br i1 %dropper, label %leave, label %work
work:
  %lead = icmp eq i32 %tid, 0
  br i1 %lead, label %produce, label %signal
produce:
  %v = load float, ptr addrspace(1) %in, align 4
  store volatile float %v, ptr addrspace(3) @word, align 4
  br label %signal
signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @bar, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %consume = icmp eq i32 %tid, 32
  br i1 %consume, label %read, label %leave
read:
  %result = load volatile float, ptr addrspace(3) @word, align 4
  store float %result, ptr addrspace(1) %out, align 4
  br label %leave
leave:
  call void @llvm.amdgcn.s.barrier.leave(i16 1)
  ret void
}

define amdgpu_kernel void @named_null_unjoin(ptr addrspace(1) %in, ptr addrspace(1) %out) #0 {
entry:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) null, i32 0)
  call void @llvm.amdgcn.s.barrier.leave(i16 0)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) null, i32 5)
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) null)
  call void @llvm.amdgcn.s.barrier.wait(i16 0)
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %initializer = icmp ult i32 %tid, 32
  br i1 %initializer, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @bar, i32 2)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @bar)
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) null)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  call void @llvm.amdgcn.s.barrier.leave(i16 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %lead = icmp eq i32 %tid, 0
  br i1 %lead, label %copy, label %end
copy:
  %v = load float, ptr addrspace(1) %in, align 4
  store float %v, ptr addrspace(1) %out, align 4
  br label %end
end:
  ret void
}

define amdgpu_kernel void @named_two_arrivals_one_wave(ptr addrspace(1) %in, ptr addrspace(1) %out) #2 {
entry:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @bar, i32 2)
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @bar)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @bar, i32 0)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @bar, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %v = load float, ptr addrspace(1) %in, align 4
  store float %v, ptr addrspace(1) %out, align 4
  call void @llvm.amdgcn.s.barrier.leave(i16 1)
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

attributes #1 = { nounwind "amdgpu-flat-work-group-size"="96,96" "target-cpu"="gfx1250" }
attributes #2 = { nounwind "amdgpu-flat-work-group-size"="1,1" "target-cpu"="gfx1250" }

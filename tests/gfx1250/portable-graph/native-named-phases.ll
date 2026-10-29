; Genuine allocated objects; each logical participant is one native wave.
target triple = "amdgcn-amd-amdhsa"
@full = internal addrspace(3) global target("amdgcn.named.barrier", 0) poison
@empty = internal addrspace(3) global target("amdgcn.named.barrier", 0) poison
@word = internal addrspace(3) global float poison, align 4

define amdgpu_kernel void @named_two_object_handshake(ptr addrspace(1) %in, ptr addrspace(1) %out) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  br i1 %producer, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @full, i32 2)
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @empty, i32 2)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @full)
  br i1 %producer, label %producer0, label %consumer0
producer0:
  %lead = icmp eq i32 %tid, 0
  br i1 %lead, label %write0, label %produce0signal
write0:
  %first = load float, ptr addrspace(1) %in, align 4
  store volatile float %first, ptr addrspace(3) @word, align 4
  br label %produce0signal
produce0signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @full, i32 0)
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @empty)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @empty, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 2)
  br i1 %lead, label %write1, label %produce1signal
write1:
  %ip = getelementptr float, ptr addrspace(1) %in, i32 1
  %second = load float, ptr addrspace(1) %ip, align 4
  store volatile float %second, ptr addrspace(3) @word, align 4
  br label %produce1signal
produce1signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @full)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @full, i32 0)
  br label %end
consumer0:
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @full, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %reader = icmp eq i32 %tid, 32
  br i1 %reader, label %read0, label %consume0signal
read0:
  %v0 = load volatile float, ptr addrspace(3) @word, align 4
  store float %v0, ptr addrspace(1) %out, align 4
  br label %consume0signal
consume0signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @empty)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @empty, i32 0)
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @full)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @full, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br i1 %reader, label %read1, label %end
read1:
  %v1 = load volatile float, ptr addrspace(3) @word, align 4
  %op = getelementptr float, ptr addrspace(1) %out, i32 1
  store float %v1, ptr addrspace(1) %op, align 4
  br label %end
end:
  ret void
}

define amdgpu_kernel void @named_independent_object_counts() #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %firstwave = icmp ult i32 %tid, 32
  br i1 %firstwave, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @full, i32 1)
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @empty, i32 2)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  br i1 %firstwave, label %solo0, label %together
solo0:
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @full)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @full, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br label %together
together:
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @empty)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @empty, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 2)
  br i1 %firstwave, label %solo1, label %end
solo1:
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @full)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @full, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br label %end
end:
  ret void
}

define amdgpu_kernel void @named_three_arrivals_expression(ptr addrspace(1) %in, ptr addrspace(1) %out) #1 {
entry:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @full, i32 1)
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %lead = icmp eq i32 %tid, 0
  br i1 %lead, label %body, label %end
body:
  %a = load float, ptr addrspace(1) %in, align 4
  %ip1 = getelementptr float, ptr addrspace(1) %in, i32 1
  %b = load float, ptr addrspace(1) %ip1, align 4
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @full, i32 0)
  %ip2 = getelementptr float, ptr addrspace(1) %in, i32 2
  %c = load float, ptr addrspace(1) %ip2, align 4
  %sum = fadd float %a, %b
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @full, i32 0)
  %product = fmul float %sum, %c
  %result = fsub float %product, %a
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @full, i32 0)
  store float %result, ptr addrspace(1) %out, align 4
  br label %end
end:
  ret void
}

; Flag 0 is the safe counterpart. Flag 1 is a CPU-only mismatched-ID deadlock.
define amdgpu_kernel void @named_selected_object_copy(ptr addrspace(1) %in, ptr addrspace(1) %out, i32 %different) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  br i1 %producer, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @full, i32 2)
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @empty, i32 2)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  %lead = icmp eq i32 %tid, 0
  br i1 %lead, label %write, label %join
write:
  %value = load float, ptr addrspace(1) %in, align 4
  store volatile float %value, ptr addrspace(3) @word, align 4
  br label %join
join:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  %nonzero = icmp ne i32 %different, 0
  %consumer = xor i1 %producer, true
  %selectother = and i1 %nonzero, %consumer
  br i1 %selectother, label %joinother, label %joinfull
joinother:
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @empty)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @empty, i32 0)
  br label %wait
joinfull:
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @full)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @full, i32 0)
  br label %wait
wait:
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %reader = icmp eq i32 %tid, 32
  br i1 %reader, label %read, label %end
read:
  %v = load volatile float, ptr addrspace(3) @word, align 4
  store float %v, ptr addrspace(1) %out, align 4
  br label %end
end:
  ret void
}

declare i32 @llvm.amdgcn.workitem.id.x()
declare void @llvm.amdgcn.s.barrier() convergent nounwind
declare void @llvm.amdgcn.s.barrier.init(ptr addrspace(3), i32) convergent nounwind
declare void @llvm.amdgcn.s.barrier.join(ptr addrspace(3)) convergent nounwind
declare void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3), i32) convergent nounwind
declare void @llvm.amdgcn.s.barrier.wait(i16) convergent nounwind
attributes #0 = { nounwind "amdgpu-flat-work-group-size"="64,64" "target-cpu"="gfx1250" }
attributes #1 = { nounwind "amdgpu-flat-work-group-size"="32,32" "target-cpu"="gfx1250" }

; Two consumers use count-1 full and count-2 empty without joining each other.
; skip_consumer=0 is safe. Values 1/2 are CPU-only missing-consumer controls.
target triple = "amdgcn-amd-amdhsa"
@lifecycle_full = internal addrspace(3) global target("amdgcn.named.barrier", 0) poison
@lifecycle_empty = internal addrspace(3) global target("amdgcn.named.barrier", 0) poison
@lifecycle_word = internal addrspace(3) global float poison, align 4

define amdgpu_kernel void @named_independent_consumers(ptr addrspace(1) %in, ptr addrspace(1) %out, i32 %skip_consumer) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  br i1 %producer, label %init, label %choose
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @lifecycle_full, i32 1)
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @lifecycle_empty, i32 2)
  br label %choose
choose:
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %joinempty, label %joinfull
joinempty:
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @lifecycle_empty)
  br label %rendezvous
joinfull:
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @lifecycle_full)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %produce0, label %consume0
produce0:
  %lead = icmp eq i32 %tid, 0
  br i1 %lead, label %write0, label %signal0
write0:
  %first = load float, ptr addrspace(1) %in, align 4
  store volatile float %first, ptr addrspace(3) @lifecycle_word, align 4
  br label %signal0
signal0:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @lifecycle_full, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br i1 %lead, label %write1, label %signal1
write1:
  %ip = getelementptr float, ptr addrspace(1) %in, i32 1
  %second = load float, ptr addrspace(1) %ip, align 4
  store volatile float %second, ptr addrspace(3) @lifecycle_word, align 4
  br label %signal1
signal1:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @lifecycle_full, i32 0)
  br label %end
consume0:
  call void @llvm.amdgcn.s.barrier.wait(i16 2)
  %lane = and i32 %tid, 31
  %reader = icmp eq i32 %lane, 0
  %wave = lshr i32 %tid, 5
  %consumer = sub i32 %wave, 1
  %outbase = shl i32 %consumer, 1
  br i1 %reader, label %read0, label %releaseempty
read0:
  %v0 = load volatile float, ptr addrspace(3) @lifecycle_word, align 4
  %op0 = getelementptr float, ptr addrspace(1) %out, i32 %outbase
  store float %v0, ptr addrspace(1) %op0, align 4
  br label %releaseempty
releaseempty:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  ; Join phase 1 before unblocking the producer's next full arrival.
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @lifecycle_full)
  %arrive = icmp ne i32 %wave, %skip_consumer
  br i1 %arrive, label %signalempty, label %consume1
signalempty:
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @lifecycle_empty, i32 0)
  br label %consume1
consume1:
  call void @llvm.amdgcn.s.barrier.wait(i16 2)
  br i1 %reader, label %read1, label %end
read1:
  %v1 = load volatile float, ptr addrspace(3) @lifecycle_word, align 4
  %outnext = add i32 %outbase, 1
  %op = getelementptr float, ptr addrspace(1) %out, i32 %outnext
  store float %v1, ptr addrspace(1) %op, align 4
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
attributes #0 = { nounwind "amdgpu-flat-work-group-size"="96,96" "target-cpu"="gfx1250" }

; Exact portable markers with one logical participant per native wave.
target triple = "amdgcn-amd-amdhsa"
@lifecycle_full = internal addrspace(3) global target("amdgcn.named.barrier", 0) poison
@lifecycle_empty = internal addrspace(3) global target("amdgcn.named.barrier", 0) poison
@lifecycle_word = internal addrspace(3) global float poison, align 4
@lifecycle_tile = internal addrspace(3) global [4 x float] poison, align 16

; The consumer joins but does not arrive. Only out[1] is written.
define amdgpu_kernel void @named_wait_only_consumer_42(ptr addrspace(1) %out) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  br i1 %producer, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @lifecycle_full, i32 1)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @lifecycle_full)
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %produce, label %consume
produce:
  %lead = icmp eq i32 %tid, 0
  br i1 %lead, label %write, label %signal
write:
  ; Keep a real F32 value role: an untyped MOV/store alone is also valid U32 bits.
  %typed42 = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 4.200000e+01)
  store volatile float %typed42, ptr addrspace(3) @lifecycle_word, align 4
  br label %signal
signal:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @lifecycle_full, i32 0)
  br label %end
consume:
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %reader = icmp eq i32 %tid, 32
  br i1 %reader, label %read, label %end
read:
  %value = load volatile float, ptr addrspace(3) @lifecycle_word, align 4
  %op = getelementptr float, ptr addrspace(1) %out, i32 1
  store float %value, ptr addrspace(1) %op, align 4
  br label %end
end:
  ret void
}

; Safe skip=0. skip=1 is a CPU-only missing-arrival deadlock control.
define amdgpu_kernel void @named_two_marker_ones(ptr addrspace(1) %out, i32 %skip) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  br i1 %producer, label %init, label %rendezvous
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @lifecycle_full, i32 2)
  br label %rendezvous
rendezvous:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @lifecycle_full)
  %allarrive = icmp eq i32 %skip, 0
  %arrive = or i1 %allarrive, %producer
  br i1 %arrive, label %signal, label %wait
signal:
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @lifecycle_full, i32 0)
  br label %wait
wait:
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %lane = and i32 %tid, 31
  %lead = icmp eq i32 %lane, 0
  br i1 %lead, label %write, label %end
write:
  %wave = lshr i32 %tid, 5
  %op = getelementptr float, ptr addrspace(1) %out, i32 %wave
  %typed1 = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 1.000000e+00)
  store float %typed1, ptr addrspace(1) %op, align 4
  br label %end
end:
  ret void
}

; Native phase completion marker, without inventing transaction-byte credits.
define amdgpu_kernel void @named_one_arrival_marker(ptr addrspace(1) %out) #1 {
entry:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @lifecycle_full, i32 1)
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @lifecycle_full)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @lifecycle_full, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %typed1 = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 1.000000e+00)
  store float %typed1, ptr addrspace(1) %out, align 4
  ret void
}

; Hardware WAIT supplies the wait/exit behavior rather than a PTX polling loop.
define amdgpu_kernel void @named_wait_then_copy_exit(ptr addrspace(1) %in, ptr addrspace(1) %out) #1 {
entry:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @lifecycle_full, i32 1)
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @lifecycle_full)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @lifecycle_full, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %value = load float, ptr addrspace(1) %in, align 4
  store float %value, ptr addrspace(1) %out, align 4
  ret void
}

define amdgpu_kernel void @named_copy_then_metadata_phase_7(ptr addrspace(1) %in, ptr addrspace(1) %out) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  br i1 %producer, label %init, label %rendezvous0
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @lifecycle_full, i32 1)
  br label %rendezvous0
rendezvous0:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @lifecycle_full)
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %produce0, label %consume0
produce0:
  %lead = icmp eq i32 %tid, 0
  br i1 %lead, label %copy, label %signal0
copy:
  %tile = load <4 x float>, ptr addrspace(1) %in, align 16
  store volatile <4 x float> %tile, ptr addrspace(3) @lifecycle_tile, align 16
  br label %signal0
signal0:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @lifecycle_full, i32 0)
  br label %rendezvous1
consume0:
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  br label %rendezvous1
rendezvous1:
  call void @llvm.amdgcn.s.barrier()
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @lifecycle_full)
  call void @llvm.amdgcn.s.barrier()
  br i1 %producer, label %produce1, label %consume1
produce1:
  %lead1 = icmp eq i32 %tid, 0
  br i1 %lead1, label %write, label %signal1
write:
  %typed7 = call float asm sideeffect "v_add_f32 $0, 0, $1", "=v,v"(float 7.000000e+00)
  store volatile float %typed7, ptr addrspace(3) @lifecycle_word, align 4
  br label %signal1
signal1:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @lifecycle_full, i32 0)
  br label %end
consume1:
  call void @llvm.amdgcn.s.barrier.wait(i16 1)
  %reader = icmp eq i32 %tid, 32
  br i1 %reader, label %read, label %end
read:
  %value = load volatile float, ptr addrspace(3) @lifecycle_word, align 4
  store float %value, ptr addrspace(1) %out, align 4
  br label %end
end:
  ret void
}

; The buffer begins free. The producer skips an imaginary prior empty phase,
; then waits for the actual consumer release before writing the second value.
define amdgpu_kernel void @named_producer_first_buffer_is_free(ptr addrspace(1) %in, ptr addrspace(1) %out) #0 {
entry:
  %tid = call i32 @llvm.amdgcn.workitem.id.x()
  %producer = icmp ult i32 %tid, 32
  br i1 %producer, label %init, label %choose
init:
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @lifecycle_full, i32 1)
  call void @llvm.amdgcn.s.barrier.init(ptr addrspace(3) @lifecycle_empty, i32 1)
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
  %reader = icmp eq i32 %tid, 32
  br i1 %reader, label %read0, label %releaseempty
read0:
  %v0 = load volatile float, ptr addrspace(3) @lifecycle_word, align 4
  store float %v0, ptr addrspace(1) %out, align 4
  br label %releaseempty
releaseempty:
  call void asm sideeffect "s_wait_dscnt 0", "~{memory}"()
  ; Join phase 1 before unblocking the producer's next full arrival.
  call void @llvm.amdgcn.s.barrier.join(ptr addrspace(3) @lifecycle_full)
  call void @llvm.amdgcn.s.barrier.signal.var(ptr addrspace(3) @lifecycle_empty, i32 0)
  call void @llvm.amdgcn.s.barrier.wait(i16 2)
  br i1 %reader, label %read1, label %end
read1:
  %v1 = load volatile float, ptr addrspace(3) @lifecycle_word, align 4
  %op = getelementptr float, ptr addrspace(1) %out, i32 1
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
attributes #0 = { nounwind "amdgpu-flat-work-group-size"="64,64" "target-cpu"="gfx1250" }
; These two kernels are tested only at block 1. A wider compilation range keeps
; the real hardware WAIT rather than LLVM replacing it with a wave-only marker.
attributes #1 = { nounwind "amdgpu-flat-work-group-size"="1,64" "target-cpu"="gfx1250" }

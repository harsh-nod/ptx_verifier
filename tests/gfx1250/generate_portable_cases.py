#!/usr/bin/env python3
"""Describe bounded workload computations independently of their native code.

This does not rewrite assembly, change input programs, or certify a result.
All cases stay pending until the native analyzer and independent specs pass.
"""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "fixtures/native-portable-workloads.hip"
ASSEMBLY = SOURCE.with_suffix(".s")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    specs = ROOT / "specs/portable"
    specs.mkdir(parents=True, exist_ok=True)
    cases = []

    def case(kernel, family, dims, arrays, expression, block=32, params=None):
        # Array tuples: name, length, kind, optional explicit base.
        configured = []
        for index, item in enumerate(arrays):
            name, length, kind, *base = item
            configured.append({"name": name, "length": length, "kind": kind,
                               "element_size": 4,
                               "base_address": base[0] if base else (index + 1) * 65536})
        path = specs / (kernel + ".spec")
        path.write_text(expression + "\n")
        cases.append({"kernel": kernel, "family": family,
                      "source": str(SOURCE.relative_to(ROOT)),
                      "assembly": str(ASSEMBLY.relative_to(ROOT)),
                      "block": [block, 1, 1], "grid": [1, 1, 1], "workgroup": [0, 0, 0],
                      "dimensions": dims, "arrays": configured,
                      "params": params or ["ptr:" + a[0] for a in arrays],
                      "spec": str(path.relative_to(ROOT)),
                      "expected_outputs": sum(a[1] for a in arrays if a[2] == "out"),
                      "required": True,
                      "scope": "Bounded complete mathematical computation on decoded F32 inputs; not original-shape or original-dtype PTX parity. Hardware untested.",
                      "software_validation": "pending", "hardware_validation": "not_performed_by_this_generator",
                      "source_sha256": sha(SOURCE), "assembly_sha256": sha(ASSEMBLY),
                      "spec_sha256": sha(path)})

    unary = [("x", 64, "in"), ("out", 64, "out")]
    for kernel, family, formula in [
        ("relu", "ReLUKernel", "max(x[i],0)"),
        ("sigmoid", "SigmoidKernel", "1/(1+exp(-x[i]))"),
        ("silu", "SiLUKernel", "x[i]/(1+exp(-x[i]))"),
    ]:
        case("portable_" + kernel, family, {"N": 64}, unary,
             f"dim N; array x[N]; array out[N]; out[i]={formula};", block=64)
    case("portable_swiglu", "SwiGLUKernel", {"N":64},
         [("gate",64,"in"),("value",64,"in"),("out",64,"out")],
         "dim N; array gate[N]; array value[N]; array out[N]; out[i]=gate[i]*value[i]/(1+exp(-gate[i]));",block=64)
    case("portable_rope", "RoPEKernel", {"H":2,"D":16},
         [("x",32,"in"),("cosine",32,"in"),("sine",32,"in"),("out",32,"out")],
         "dim H; dim D; array x[H,D]; array cosine[H,D]; array sine[H,D]; array out[H,D]; out[h,j]=x[h,j]*cosine[h,j]+(2*h-1)*x[1-h,j]*sine[h,j];")
    case("portable_reduction", "ReductionSumKernel", {"R":2,"N":32},
         [("x",64,"in"),("out",2,"out")],
         "dim R; dim N; array x[R,N]; array out[R]; out[r]=sum(k in 0..N,x[r,k]);")
    case("portable_softmax", "SoftmaxKernel", {"R":2,"C":32},
         [("x",64,"in"),("out",64,"out")],
         "dim R; dim C; array x[R,C]; array out[R,C]; out[r,c]=exp(x[r,c]-max(k in 0..C,x[r,k]))/sum(k in 0..C,exp(x[r,k]-max(j in 0..C,x[r,j])));",block=64)
    case("portable_rmsnorm", "RMSNormKernel", {"R":2,"N":32},
         [("x",64,"in"),("weight",64,"in"),("out",64,"out")],
         "dim R; dim N; array x[R,N]; array weight[R,N]; array out[R,N]; out[r,i]=x[r,i]*weight[r,i]/sqrt(sum(k in 0..N,x[r,k]*x[r,k])/N+0.0000009999999974752427);",block=64)
    case("portable_matvec", "MatrixVectorMultiplicationKernel", {"M":4,"K":32},
         [("a",128,"in"),("x",32,"in"),("out",4,"out")],
         "dim M; dim K; array a[M,K]; array x[K]; array out[M]; out[i]=sum(k in 0..K,a[i,k]*x[k]);")
    dot = "sum(k in 0..K,a[i,k]*b[k,j])"
    case("portable_gemm", "MatrixMultiplication", {"M":4,"N":8,"K":16},
         [("a",64,"in"),("b",128,"in"),("out",32,"out")],
         f"dim M; dim N; dim K; array a[M,K]; array b[K,N]; array out[M,N]; out[i,j]={dot};")
    value = f"({dot}+addend[i,j])"
    case("portable_gemm_add_silu", "FusedGEMMAddSiLUKernel", {"M":4,"N":8,"K":16},
         [("a",64,"in"),("b",128,"in"),("addend",32,"in"),("out",32,"out")],
         f"dim M; dim N; dim K; array a[M,K]; array b[K,N]; array addend[M,N]; array out[M,N]; out[i,j]={value}/(1+exp(-{value}));")

    for batched in [False,True]:
        batches = 2 if batched else 1
        outputs = [(f"out{b}{j}",2,"out",196608+(b*4+j)*8)
                   for b in range(batches) for j in range(4)]
        arrays = [("a",batches*64,"in"),("packed",batches*4,"index")] + outputs
        declarations = "dim M; dim K; " + ("dim B; array a[B,M,K]; " if batched else "array a[M,K]; ")
        declarations += " ".join(f"array {a[0]}[M];" for a in outputs)
        equations = []
        # Independent host integers decode every bit of the configured word.
        # No expression is inferred from the compiled instruction stream.
        for b in range(batches):
            for j in range(4):
                word = b*4+j
                terms = []
                for k in range(32):
                    coefficient = 2*((word >> k)&1)-1
                    index = f"{b},i,{k}" if batched else f"i,{k}"
                    terms.append(f"({coefficient})*a[{index}]")
                equations.append(f"out{b}{j}[i]="+"+".join(terms)+";")
        case("portable_bitdelta_batched" if batched else "portable_bitdelta",
             "BitDeltaNeurIPS2024BatchedMatmul" if batched else "BitDeltaNeurIPS2024Matmul",
             {"B":batches,"M":2,"K":32} if batched else {"M":2,"K":32}, arrays,
             declarations+"\n"+"\n".join(equations),
             params=["ptr:a","ptr:packed","ptr:out00"])
        cases[-1]["scope"] = "Complete bounded 1-bit-weight matmul with all 32 unpacked bits; concrete IndexInput packed[i]=i, arbitrary symbolic decoded F32 A. This does not validate arbitrary symbolic packed words or original large PTX shapes."

    case("portable_convolution", "Convolution2DKernel",
         {"C":2,"H":5,"W":5,"O":2,"R":3,"S":3,"OH":3,"OW":3},
         [("x",50,"in"),("weight",36,"in"),("out",18,"out")],
         "dim C; dim H; dim W; dim O; dim R; dim S; dim OH; dim OW; array x[C,H,W]; array weight[O,C,R,S]; array out[O,OH,OW]; out[o,h,w]=sum(c in 0..C,sum(r in 0..R,sum(s in 0..S,x[c,h+r,w+s]*weight[o,c,r,s])));")
    case("portable_mamba_state", "Mamba2ChunkStateForward", {"T":8,"PITCH":4,"M":4,"N":4},
         [("x",32,"in"),("b",32,"in"),("dt",8,"in"),("da",8,"in"),("states",16,"out")],
         "dim T; dim PITCH; dim M; dim N; array x[T,PITCH]; array b[T,PITCH]; array dt[T]; array da[T]; array states[M,N]; states[i,j]=sum(t in 0..T,x[t,i]*b[t,j]*dt[t]*exp(min(da[T-1]-da[t],0)));")
    case("portable_mamba_scan", "Mamba2ChunkScanForward", {"R":2,"N":4,"S":4,"T":8},
         [("cb",16,"in"),("x",32,"in"),("c",8,"in"),("prev",16,"in"),("dt",8,"in"),("da",8,"in"),("out",8,"out"),("out_x",8,"out")],
         "dim R; dim N; dim S; dim T; array cb[R,T]; array x[T,N]; array c[R,S]; array prev[N,S]; array dt[T]; array da[T]; array out[R,N]; array out_x[R,N]; out[r,i]=exp(da[r])*sum(j in 0..S,c[r,j]*prev[i,j])+sum(t in 0..T,cb[r,t]*exp(min(da[r]-da[t],0))*dt[t]*x[t,i]); out_x[r,i]=0;")

    # Natural exp is represented through the same pinned reciprocal-LOG2_E
    # abstraction as existing native tests. Log result retains encoded factors.
    log_factor = "1.4426950216293335*0.6931471824645996"
    for mode,family in [("flash","FlashAttentionNeurIPS2022Forward"),
                        ("forgetting","ForgettingAttentionICLR2025Forward"),
                        ("sage","SageAttentionICLR2025")]:
        arrays = [("q",8,"in"),("k",32,"in"),("v",32,"in")]
        extra = ""
        if mode == "forgetting":
            arrays.append(("log_lambda",8,"in")); extra = "array log_lambda[T];"
        if mode == "sage":
            arrays.extend([("q_scale",1,"in"),("k_scale",2,"in")])
            extra = "array q_scale[ONE]; array k_scale[TWO];"
        arrays.append(("out",8,"out"))
        if mode != "sage": arrays.append(("lse",2,"out"))
        def sc(key,half=None):
            d = f"sum(a in 0..D,q[i,a]*k[{key},a])"
            if mode == "forgetting": return f"({d}*0.125-log_lambda[{key}])"
            if mode == "sage": return f"({d}*q_scale[0]*k_scale[{half}])"
            return f"({d}*0.125)"
        if mode == "sage":
            maximum = f"max(max(j in 0..HALF,{sc('j',0)}),max(j in 0..HALF,{sc('j+HALF',1)}))"
            denominator = "+".join(f"sum(j in 0..HALF,exp({sc(key,half)}-{maximum}))" for key,half in [('j',0),('j+HALF',1)])
            numerator = "+".join(f"sum(j in 0..HALF,exp({sc(key,half)}-{maximum})*v[{key},d])" for key,half in [('j',0),('j+HALF',1)])
        else:
            maximum = f"max(j in 0..T,{sc('j')})"
            denominator = f"sum(j in 0..T,exp({sc('j')}-{maximum}))"
            numerator = f"sum(j in 0..T,exp({sc('j')}-{maximum})*v[j,d])"
        text = "dim Q; dim T; dim D; dim HALF; dim ONE; dim TWO; array q[Q,D]; array k[T,D]; array v[T,D]; "+extra+f" array out[Q,D]; out[i,d]=({numerator})/({denominator});"
        if mode != "sage":
            text += f" array lse[Q]; lse[i]={maximum}+log({denominator})*{log_factor}"
            text += "+log_lambda[i];" if mode == "forgetting" else ";"
        case(f"portable_{mode}_attention",family,{"Q":2,"T":8,"D":4,"HALF":4,"ONE":1,"TWO":2},arrays,text)
        if mode == "sage": cases[-1]["scope"] += " Q/K values are decoded F32 values; int8 packing and quantization are outside this case."

    score = "(2*sum(d in 0..D,x[i,d]*y[j,d])+g_hat[j]+log_b[j])"
    maximum = f"max(j in 0..T,{score})"
    total = f"sum(j in 0..T,exp({score}-{maximum}))"
    case("portable_sinkhorn","FlashSinkhornFusedSchurMatvec",{"R":2,"T":8,"D":4},
         [("x",8,"in"),("y",32,"in"),("f_hat",2,"in"),("g_hat",8,"in"),("log_b",8,"in"),("f_out",2,"out")],
         "dim R; dim T; dim D; array x[R,D]; array y[T,D]; array f_hat[R]; array g_hat[T]; array log_b[T]; array f_out[R];"+
         f"f_out[i]=0.5*f_hat[i]-0.5*({maximum}+log({total})*{log_factor});")
    assert len(cases) == 20 and len({c["family"] for c in cases}) == 20
    output = ROOT / "portable-cases.json"
    output.write_text(json.dumps({"schema_version":1,"target":"gfx1250",
        "scope":"Twenty bounded workload-family mathematical counterparts. Complete configured footprints; no original-shape/dtype/workgroup-grid parity or hardware claim.",
        "cases":cases},indent=2)+"\n")
    print(f"Wrote {len(cases)} required family cases and independent specs")


if __name__ == "__main__":
    main()

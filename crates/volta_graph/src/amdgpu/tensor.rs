//! Public LLVM/FlyDSL bounded plain-2D tensor descriptor contract.
//!
//! LLVM `AMDGPUDMAOperations.md` at 5fd50ec8 and FlyDSL `tdm_ops.py`
//! at f37f7a2 define the transfer/descriptor recipe. This decoder deliberately
//! excludes padding, multicast, atomic barriers, iteration, gather and OOB fill.

/// Captured uniform descriptor words, with no claim of successful memory issue.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AmdTensorDescriptor {
    pub d0: [u32; 4],
    pub d1: [u32; 8],
    pub d2: [u32; 4],
    pub d3: [u32; 4],
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AmdTensorFootprint {
    pub width: u64,
    pub rows: u64,
    pub cols: u64,
    pub stride: u64,
    pub global: u64,
    pub shared: u64,
    pub bytes: u64,
    pub global_end: u64,
    pub shared_end: u64,
}

impl AmdTensorDescriptor {
    /// `None` is the descriptor predicate's no-op, not an access.
    pub fn decode(&self) -> Result<Option<AmdTensorFootprint>, &'static str> {
        let (d0, d1) = (&self.d0, &self.d1);
        if d0[0] > 1
            || d0[3] & 0xfe00_0000 != 0x8000_0000
            || d1[0] & !0x30000 != 0
            || self.d2.iter().chain(&self.d3).any(|&x| x != 0)
        {
            return Err(
                "tensor descriptor requires bounded non-padded 2D global/LDS profile without multicast/atomic/iteration/gather",
            );
        }
        if d0[0] == 0 {
            return Ok(None);
        }
        let data_size = (d1[0] >> 16) & 3;
        if data_size > 2 {
            return Err("unsupported tensor element width");
        }
        let width = 1u64 << data_size;
        let dim0 = ((d1[1] >> 16) as u64) | (((d1[2] & 65535) as u64) << 16);
        let dim1 = ((d1[2] >> 16) as u64) | (((d1[3] & 65535) as u64) << 16);
        let cols = (d1[3] >> 16) as u64;
        let rows = (d1[4] & 65535) as u64;
        let stride = d1[5] as u64;
        if d1[1] & 65535 != 0
            || d1[4] >> 16 != 0
            || d1[6] != 0
            || d1[7] != 0
            || cols == 0
            || rows == 0
            || cols > dim0
            || rows > dim1
            || stride < dim0
        {
            return Err("tensor 2D shape/stride/OOB descriptor unsupported");
        }
        let global = d0[2] as u64 | (((d0[3] & 0x1ffffff) as u64) << 32);
        let shared = d0[1] as u64;
        let bytes = rows
            .checked_mul(cols)
            .and_then(|x| x.checked_mul(width))
            .ok_or("tensor tile size overflow")?;
        let global_end = (rows - 1)
            .checked_mul(stride)
            .and_then(|x| x.checked_add(cols))
            .and_then(|x| x.checked_mul(width))
            .and_then(|x| x.checked_add(global))
            .ok_or("tensor global address overflow")?;
        let shared_end = shared
            .checked_add(bytes)
            .ok_or("tensor LDS address overflow")?;
        Ok(Some(AmdTensorFootprint {
            width,
            rows,
            cols,
            stride,
            global,
            shared,
            bytes,
            global_end,
            shared_end,
        }))
    }
}

/// Identifies a typed native abort; the event and all prefix premises must still
/// be independently validated before it is a finding.
pub const TENSOR_BOUNDS_ABORT_REASON: &str = "tensor footprint exceeds LDS capacity";

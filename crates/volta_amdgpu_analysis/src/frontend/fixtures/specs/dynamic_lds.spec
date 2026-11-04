// Compiler ABI places the32-byte-aligned extern window after12static bytes.
dim N; dim INPUT;
array x[INPUT];
array out[N];
out[i] = x[1-i]+x[3-i];

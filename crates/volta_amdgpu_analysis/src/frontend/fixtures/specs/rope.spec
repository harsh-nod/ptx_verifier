// Single workgroup zero: two opposite halves, 64 positions per half.
dim H;
dim D;
array x[H, D];
array cosine[H, D];
array sine[H, D];
array out[H, D];
out[h, j] = x[h, j] * cosine[h, j]
          + (2 * h - 1) * x[1 - h, j] * sine[h, j];

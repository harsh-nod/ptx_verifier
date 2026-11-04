// Complete logical opposite-half rotation. Native storage remains F16 or E4M3.
dim H; dim D; array input[H,D]; array cos[H,D]; array sin[H,D]; array output[H,D];
output[h,j] = input[h,j] * cos[h,j] + (2*h-1) * input[1-h,j] * sin[h,j];

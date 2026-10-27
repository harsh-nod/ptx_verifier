// Three records match the actual native2/4/3-dword stores; selected group0.
// max(1-abs(i-j),0) selects record field j for integer output index i.
dim TWO; dim FOUR; dim THREE; dim GX; dim GY; dim GZ; dim X; dim Y; dim Z;
array grid_xy[TWO];
array grid_z_and_group[FOUR];
array block_xyz[THREE];
grid_xy[i] = GX*max(1-abs(i),0)+GY*max(1-abs(i-1),0);
grid_z_and_group[i] = GZ*max(1-abs(i),0);
block_xyz[i] = X*max(1-abs(i),0)+Y*max(1-abs(i-1),0)+Z*max(1-abs(i-2),0);

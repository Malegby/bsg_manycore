//This kernel performs a list of operations on two float vectors
//Operatiosn incluce <add, sub, mul, div, compare, convert> 

#include "bsg_manycore.h"
#include "bsg_set_tile_x_y.h"

#define BSG_TILE_GROUP_X_DIM bsg_tiles_X
#define BSG_TILE_GROUP_Y_DIM bsg_tiles_Y
#include "bsg_tile_group_barrier.h"
INIT_TILE_GROUP_BARRIER(r_barrier, c_barrier, 0, bsg_tiles_X-1, 0, bsg_tiles_Y-1);

typedef union data_t {
	int hb_mc_int;
	float hb_mc_float;
} hb_mc_data_t;


int  __attribute__ ((noinline)) kernel_float_all_ops(float *A, float *B,
                                                     float *res_add, float *res_sub,
                                                     float *res_mul, float *res_div,
                                                     float *res_compare, float *res_convert,
                                                     int N, int block_size_x) {
	if (__bsg_id == 0)
		bsg_print_stat_start(__bsg_tile_group_id);

	int start_x = block_size_x * (__bsg_tile_group_id_y * __bsg_grid_dim_x + __bsg_tile_group_id_x); 
	for (int iter_x = __bsg_id; iter_x < block_size_x; iter_x += bsg_tiles_X * bsg_tiles_Y) { 
		int i = start_x + iter_x;
		res_add[i] = A[i] + B[i];
		res_sub[i] = A[i] - B[i];
		res_mul[i] = A[i] * B[i];
		res_div[i] = A[i] / B[i];
		if (A[i] >= B[i]) {
			res_compare[i] = 1.0;
		}
		else { 
			res_compare[i] = 0.0;
		}
		hb_mc_data_t data;
		data.hb_mc_float = A[i]; 
		res_convert[i] = (float) data.hb_mc_int;
	}

	bsg_tile_group_barrier(&r_barrier, &c_barrier); 

	if (__bsg_id == 0)
		bsg_print_stat_end(__bsg_tile_group_id);

	bsg_tile_group_barrier(&r_barrier, &c_barrier); 

  return 0;
}

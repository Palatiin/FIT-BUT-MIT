/**
 * @file BatchMandelCalculator.cc
 * @author Matus Remen <xremen01@stud.fit.vutbr.cz>
 * @brief Implementation of Mandelbrot calculator that uses SIMD paralelization over small batches
 * @date 4.11.2023
 */

#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <immintrin.h>
#include <stdlib.h>
#include <stdexcept>

#include "BatchMandelCalculator.h"


template<class T>
struct LineValues {
	T *zRe;
	T *zIm;
	bool *active;

	LineValues<T>(const unsigned width){
		zRe = ((T *) _mm_malloc(width * sizeof(T), 64));
		zIm = ((T *) _mm_malloc(width * sizeof(T), 64));
		active = ((bool *) _mm_malloc(width * sizeof(bool), 64));
	}

	~LineValues<T>(){
		_mm_free(zRe);
		_mm_free(zIm);
		_mm_free(active);
	}
};


BatchMandelCalculator::BatchMandelCalculator (unsigned matrixBaseSize, unsigned limit) :
	BaseMandelCalculator(matrixBaseSize, limit, "BatchMandelCalculator")
{
	data = ((unsigned short *) _mm_malloc(height * width * sizeof(unsigned short), 64));
	for (unsigned i = 0; i < height * width; ++i)
		data[i] = 0;
}

BatchMandelCalculator::~BatchMandelCalculator() {
	_mm_free(data);
}


unsigned short * BatchMandelCalculator::calculateMandelbrot () {
	unsigned short * data_ptr = data;

	unsigned block_size = height / 8;
	unsigned height_blocks = height / block_size;
	unsigned width_blocks = width / block_size;
	height_blocks = height_blocks ? height_blocks : 1;
	width_blocks = width_blocks ? width_blocks : 1;
	
	for (unsigned glob_row = 0; glob_row < height_blocks / 2; ++glob_row){

		for (unsigned glob_col = 0; glob_col < width_blocks; ++glob_col){

			for (unsigned row = 0; row < block_size; ++row){

				float im = y_start + (row + glob_row * block_size) * dy;

				LineValues<float> lineValues(block_size);

				for (unsigned col = 0; col < block_size; ++col){
					lineValues.zRe[col] = x_start + (col + glob_col * block_size) * dx;
					lineValues.zIm[col] = im;
					lineValues.active[col] = true;
				}

				float * zRes = lineValues.zRe;
				float * zIms = lineValues.zIm;
				bool * active = lineValues.active;
				unsigned short finished_count = 0;
				for (unsigned i = 0; i < limit; ++i){
					#pragma omp simd simdlen(64) aligned(data_ptr, zRes, zIms, active: 64) reduction(+:finished_count)
					for (unsigned col = 0; col < block_size; ++col){
						if (active[col] == false)
							continue;
						float zIm = zIms[col];
						float zRe = zRes[col];

						float im2 = zIm * zIm;
						float re2 = zRe * zRe;
						if (re2 + im2 > 4.0f){
							active[col] = false;
							finished_count += 1;
							continue;
						}

						float re = x_start + (col + glob_col * block_size) * dx;

						data_ptr[(row + block_size * glob_row) * width + (col + block_size * glob_col)] += 1;
						data_ptr[(height - row - block_size * glob_row - 1) * width + (col + block_size * glob_col)] += 1;
						zIms[col] = 2.0f * zRe * zIm + im;
						zRes[col] = re2 - im2 + re;
					}

					if (finished_count == block_size)
						break;
				}
			}
		}
	}
	
	return data;
}

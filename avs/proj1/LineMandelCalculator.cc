/**
 * @file LineMandelCalculator.cc
 * @author Matus Remen <xremen01@stud.fit.vutbr.cz>
 * @brief Implementation of Mandelbrot calculator that uses SIMD paralelization over lines
 * @date 3.11.2023
 */
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <immintrin.h>
#include <stdlib.h>


#include "LineMandelCalculator.h"


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


LineMandelCalculator::LineMandelCalculator (unsigned matrixBaseSize, unsigned limit) :
	BaseMandelCalculator(matrixBaseSize, limit, "LineMandelCalculator")
{
	data = ((unsigned short *) _mm_malloc(height * width * sizeof(unsigned short), 64));
}

LineMandelCalculator::~LineMandelCalculator() {
	_mm_free(data);
};


unsigned short * LineMandelCalculator::calculateMandelbrot () {
	// initialize 
	for (unsigned i = 0; i < height * width; ++i)
		data[i] = 0;

	unsigned short * data_ptr = data;

	unsigned half = height / 2;
	for (unsigned row = 0; row < half; ++row){
		float im = y_start + row * dy;
		
		LineValues<float> lineValues(width);

		// init Re and Im values for the row
		for (unsigned col = 0; col < width; ++col){
			lineValues.zRe[col] = x_start + col * dx;
			lineValues.zIm[col] = im;
			lineValues.active[col] = true;
		}
		float * zRes = lineValues.zRe;
		float * zIms = lineValues.zIm;
		bool * active = lineValues.active;
		unsigned short finished_count = 0;
		for (unsigned i = 0; i < limit; ++i){
			#pragma omp simd simdlen(64) aligned(data_ptr, zRes, zIms, active: 64) reduction(+: finished_count)
			for (unsigned col = 0; col < width; ++col){
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
				
				float re = x_start + col * dx;
			
				data_ptr[row * width + col] += 1;
				data_ptr[(height - row - 1) * width + col] += 1;

				zIms[col] = 2.0f * zRe * zIm + im;
				zRes[col] = re2 - im2 + re;
			}

			if (finished_count == width)
				break;
		}
	}

	return data;
}

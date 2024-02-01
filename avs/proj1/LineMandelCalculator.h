/**
 * @file LineMandelCalculator.h
 * @author Matus Remen <xremen01@stud.fit.vutbr.cz>
 * @brief Implementation of Mandelbrot calculator that uses SIMD paralelization over lines
 * @date 3.11.2023
 */

#include <BaseMandelCalculator.h>

class LineMandelCalculator : public BaseMandelCalculator
{
public:
    LineMandelCalculator(unsigned matrixBaseSize, unsigned limit);
    ~LineMandelCalculator();
    unsigned short *calculateMandelbrot();

private:
    // all internal parameters
	unsigned short * data;
};

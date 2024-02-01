/**
 * @file	tree_mesh_builder.cpp
 *
 * @author  Matus Remen <xremen01@stud.fit.vutbr.cz>
 *
 * @brief   Parallel Marching Cubes implementation using OpenMP tasks + octree early elimination
 *
 * @date	14.12.2023
 **/

#include <iostream>
#include <math.h>
#include <limits>

#include "tree_mesh_builder.h"

#define CUT_OFF_tasks 2.0f


TreeMeshBuilder::TreeMeshBuilder(unsigned gridEdgeSize)
	: BaseMeshBuilder(gridEdgeSize, "Octree")
{
}

unsigned TreeMeshBuilder::marchCubes(const ParametricScalarField &field)
{
	Vec3_t<float> startPos;
	unsigned totalTriangles = 0;
	this->sqrt3Div2_times_gridResolution = sqrt(3.0f) / 2.0f * mGridResolution;
	this->floatMax = std::numeric_limits<float>::max();

	#pragma omp parallel shared(totalTriangles, field)
	#pragma omp single nowait
	totalTriangles = octree(startPos, field, (float) mGridSize);

	return totalTriangles;
}

float TreeMeshBuilder::evaluateFieldAt(const Vec3_t<float> &pos, const ParametricScalarField &field)
{
	// 1. Store pointer to and number of 3D points in the field
    //    (to avoid "data()" and "size()" call in the loop).
    const Vec3_t<float> *pPoints = field.getPoints().data();
    const unsigned count = unsigned(field.getPoints().size());

    float value = floatMax;

    // 2. Find minimum square distance from points "pos" to any point in the
    //    field.
	// #pragma omp simd reduction(min:value)
	for(unsigned i = 0; i < count; ++i)
    {
        float distanceSquared  = (pos.x - pPoints[i].x) * (pos.x - pPoints[i].x);
        distanceSquared       += (pos.y - pPoints[i].y) * (pos.y - pPoints[i].y);
        distanceSquared       += (pos.z - pPoints[i].z) * (pos.z - pPoints[i].z);

        // Comparing squares instead of real distance to avoid unnecessary
        // "sqrt"s in the loop.
        value = std::min(value, distanceSquared);
    }

    // 3. Finally take square root of the minimal square distance to get the real distance
    return sqrt(value);
}

void TreeMeshBuilder::emitTriangle(const BaseMeshBuilder::Triangle_t &triangle)
{
	#pragma omp critical
	mTriangles.push_back(triangle);
}

unsigned TreeMeshBuilder::octree(const Vec3_t<float> &pos, const ParametricScalarField &field, float gridSize)
{
	unsigned totalTrianglesCount = 0;
	float halfGridSize = gridSize / 2.0f;

	const Vec3_t<float> cubeCenter(
		(pos.x + halfGridSize) * mGridResolution,
		(pos.y + halfGridSize) * mGridResolution,
		(pos.z + halfGridSize) * mGridResolution
	);

	const float threshold = mIsoLevel + (sqrt3Div2_times_gridResolution * gridSize);
	if (evaluateFieldAt(cubeCenter, field) > threshold){
		return 0;
	}

	if (gridSize == 1.0f){  // CUT OFF for further cube division
		return buildCube(pos, field);
	}

	unsigned a,b,c,d,e,f,g,h = 0;

	std::vector<Vec3_t<float>> subCubes = subCubesPositions(pos, halfGridSize);
	#pragma omp task shared(a) firstprivate(subCubes, halfGridSize, gridSize, field) if(gridSize > CUT_OFF_tasks)
	a = octree(subCubes[0], field, halfGridSize);
	#pragma omp task shared(b) firstprivate(subCubes, halfGridSize, gridSize, field) if(gridSize > CUT_OFF_tasks)
	b = octree(subCubes[1], field, halfGridSize);
	#pragma omp task shared(c) firstprivate(subCubes, halfGridSize, gridSize, field) if(gridSize > CUT_OFF_tasks)
	c = octree(subCubes[2], field, halfGridSize);
	#pragma omp task shared(d) firstprivate(subCubes, halfGridSize, gridSize, field) if(gridSize > CUT_OFF_tasks)
	d = octree(subCubes[3], field, halfGridSize);
	#pragma omp task shared(e) firstprivate(subCubes, halfGridSize, gridSize, field) if(gridSize > CUT_OFF_tasks)
	e = octree(subCubes[4], field, halfGridSize);
	#pragma omp task shared(f) firstprivate(subCubes, halfGridSize, gridSize, field) if(gridSize > CUT_OFF_tasks)
	f = octree(subCubes[5], field, halfGridSize);
	#pragma omp task shared(g) firstprivate(subCubes, halfGridSize, gridSize, field) if(gridSize > CUT_OFF_tasks)
	g = octree(subCubes[6], field, halfGridSize);
	#pragma omp task shared(h) firstprivate(subCubes, halfGridSize, gridSize, field) if(gridSize > CUT_OFF_tasks)
	h = octree(subCubes[7], field, halfGridSize);

	#pragma omp taskwait
	return a + b + c + d + e + f + g + h;
}

std::vector<Vec3_t<float>> TreeMeshBuilder::subCubesPositions(const Vec3_t<float> &pos, float halfGridSize){
	return std::vector<Vec3_t<float>>{
		Vec3_t<float>(pos.x + sc_vertexNormPos[0].x * halfGridSize, pos.y + sc_vertexNormPos[0].y * halfGridSize, pos.z + sc_vertexNormPos[0].z * halfGridSize),
		Vec3_t<float>(pos.x + sc_vertexNormPos[1].x * halfGridSize, pos.y + sc_vertexNormPos[1].y * halfGridSize, pos.z + sc_vertexNormPos[1].z * halfGridSize),
		Vec3_t<float>(pos.x + sc_vertexNormPos[2].x * halfGridSize, pos.y + sc_vertexNormPos[2].y * halfGridSize, pos.z + sc_vertexNormPos[2].z * halfGridSize),
		Vec3_t<float>(pos.x + sc_vertexNormPos[3].x * halfGridSize, pos.y + sc_vertexNormPos[3].y * halfGridSize, pos.z + sc_vertexNormPos[3].z * halfGridSize),
		Vec3_t<float>(pos.x + sc_vertexNormPos[4].x * halfGridSize, pos.y + sc_vertexNormPos[4].y * halfGridSize, pos.z + sc_vertexNormPos[4].z * halfGridSize),
		Vec3_t<float>(pos.x + sc_vertexNormPos[5].x * halfGridSize, pos.y + sc_vertexNormPos[5].y * halfGridSize, pos.z + sc_vertexNormPos[5].z * halfGridSize),
		Vec3_t<float>(pos.x + sc_vertexNormPos[6].x * halfGridSize, pos.y + sc_vertexNormPos[6].y * halfGridSize, pos.z + sc_vertexNormPos[6].z * halfGridSize),
		Vec3_t<float>(pos.x + sc_vertexNormPos[7].x * halfGridSize, pos.y + sc_vertexNormPos[7].y * halfGridSize, pos.z + sc_vertexNormPos[7].z * halfGridSize),
	};
}


/**
 * @file    tree_mesh_builder.h
 *
 * @author  Matus Remen <xremen01@stud.fit.vutbr.cz>
 *
 * @brief   Parallel Marching Cubes implementation using OpenMP tasks + octree early elimination
 *
 * @date    14.12.2023
 **/

#ifndef TREE_MESH_BUILDER_H
#define TREE_MESH_BUILDER_H

#include "base_mesh_builder.h"

class TreeMeshBuilder : public BaseMeshBuilder
{
public:
    TreeMeshBuilder(unsigned gridEdgeSize);

protected:
    unsigned marchCubes(const ParametricScalarField &field);
    float evaluateFieldAt(const Vec3_t<float> &pos, const ParametricScalarField &field);
    void emitTriangle(const Triangle_t &triangle);
	const Triangle_t *getTrianglesArray() const { return mTriangles.data(); }

	float sqrt3Div2_times_gridResolution;
	float floatMax;
	unsigned octree(const Vec3_t<float> &pos, const ParametricScalarField &field, float mGridSize);
    std::vector<Vec3_t<float>> subCubesPositions(const Vec3_t<float> &pos, float halfGridSize);
	std::vector<Triangle_t> mTriangles;
};

#endif // TREE_MESH_BUILDER_H

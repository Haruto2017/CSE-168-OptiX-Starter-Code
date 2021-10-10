#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different geometries should be defined here.
 */

struct Triangle
{
    // TODO: define the triangle structure
    unsigned int vertice0;
    unsigned int vertice1;
    unsigned int vertice2;
    optix::float3 normal;

    Triangle(unsigned int v0, unsigned int v1, unsigned int v2, optix::float3 n)
    {
        vertice0 = v0;
        vertice1 = v1;
        vertice2 = v2;
        normal = n;
    }
};

struct Sphere
{


    // TODO: define the sphere structure


};

struct Attributes
{
    

    // TODO: define the attributes structure
};
#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

#include "Geometries.h"
#include "Light.h"

struct Scene
{
    // Info about the output image
    std::string outputFilename;
    unsigned int width, height;

    std::string integratorName;
    unsigned int lightsamples;
    unsigned int lightstratify;

    std::vector<optix::float3> vertices;

    std::vector<Triangle> triangles;
    std::vector<Sphere> spheres;

    std::vector<DirectionalLight> dlights;
    std::vector<PointLight> plights;
    //std::vector<ParallelogramLight> qlights;

    // TODO: add other variables that you need here
    optix::float3 eye;
    optix::float3 center;
    optix::float3 up;
    unsigned int fovy;
    unsigned int maxverts;
    unsigned int maxdepth;

    unsigned int spp;

    Scene()
    {
        outputFilename = "raytrace.png";
        integratorName = "raytracer";
        maxdepth = 1;
        lightsamples = 1;
        lightstratify = 0;
        spp = 1;
    }
};
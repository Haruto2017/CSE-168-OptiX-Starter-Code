#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different light sources should be defined here.
 */

struct PointLight
{
    // TODO: define the point light structure
    optix::float3 position;
    optix::float3 color;
    optix::float3 attenuation;
    PointLight(optix::float3 p, optix::float3 c, optix::float3 a)
    {
        position = p;
        color = c;
        attenuation = a;
    }
};

struct DirectionalLight
{
    // TODO: define the directional light structure
    optix::float3 direction;
    optix::float3 color;
    optix::float3 attenuation;
    DirectionalLight(optix::float3 d, optix::float3 c, optix::float3 a)
    {
        direction = optix::normalize(d);
        color = c;
        attenuation = a;
    }
};

struct ParallelogramLight
{
    optix::float3 a;
    optix::float3 ab;
    optix::float3 ac;
    optix::float3 intensity;
    ParallelogramLight(optix::float3 a, optix::float3 ab, optix::float3 ac, optix::float3 i)
    {
        this->a = a;
        this->ab = ab;
        this->ac = ac;
        intensity = i;
    }
};
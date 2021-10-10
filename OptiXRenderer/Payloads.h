#pragma once

#include <optixu/optixu_math_namespace.h>
#include "Geometries.h"

/**
 * Structures describing different payloads should be defined here.
 */

struct Payload
{
    optix::float3 radiance;
    bool done;
    // TODO: add more variable to payload if you need to
    unsigned int seed;
    int NEE;
    int depth;
    float3 origin;
    float3 dir;
    float3 pathTracingWeight;
};

struct ShadowPayload
{
    int isVisible;
};
#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>
#include "random.h"

#include "Payloads.h"

using namespace optix;

#define PI 3.1415926538

rtBuffer<float3, 2> resultBuffer; // used to store the render result

rtDeclareVariable(rtObject, root, , ); // Optix graph

rtDeclareVariable(uint2, launchIndex, rtLaunchIndex, ); // a 2d index (x, y)

rtDeclareVariable(int1, frameID, , );

// Camera info 

// TODO:: delcare camera varaibles here
rtDeclareVariable(uint, width, , );
rtDeclareVariable(uint, height, , );
rtDeclareVariable(float3, eye, , );
rtDeclareVariable(float3, center, , );
rtDeclareVariable(float3, up, , );
rtDeclareVariable(float, fov, , );
rtDeclareVariable(uint, spp, , );
rtDeclareVariable(uint, maxdepth, , );
rtDeclareVariable(uint, NEE, , );
rtDeclareVariable(uint, RR, , );
rtDeclareVariable(float, gamma, , );

RT_PROGRAM void generateRays()
{
    float3 result = make_float3(0.f);

    //rtPrintf("any\n");

    // TODO: calculate the ray direction (change the following lines)
    float aspect_ratio = (float)width / (float)height;

    float3 sum = make_float3(0);
    for (int i = 0; i < spp; ++i)
    {
        float3 origin = eye;
        size_t2 resultSize = resultBuffer.size();
        uint seed = tea<16>(launchIndex.x * resultSize.y + launchIndex.y, i);
        float3 camera_coord;
        if (i == 0)
        {
            camera_coord = make_float3(fov * aspect_ratio * (2.0 * ((launchIndex.x + 0.5) / width) - 1.0), fov * (2.0 * ((launchIndex.y + 0.5) / height) - 1.0), -1.0);
        }
        else
        {
            float u1 = rnd(seed);
            float u2 = rnd(seed);
            camera_coord = make_float3(fov * aspect_ratio * (2.0 * ((launchIndex.x + u1) / width) - 1.0), fov * (2.0 * ((launchIndex.y + u2) / height) - 1.0), -1.0);
        }
        //transform from screen space to world space
        Matrix<4, 4> camera_to_world;
        float3 z_axis = normalize(eye - center);
        float3 x_axis = normalize(cross(up, z_axis));
        camera_to_world.setCol(0, make_float4(x_axis.x, x_axis.y, x_axis.z, 0.0));
        camera_to_world.setCol(1, make_float4(up.x, up.y, up.z, 0.0));
        camera_to_world.setCol(2, make_float4(z_axis.x, z_axis.y, z_axis.z, 0.0));
        camera_to_world.setCol(3, make_float4(eye.x, eye.y, eye.z, 1.0));
        float4 p = camera_to_world * make_float4(camera_coord.x, camera_coord.y, camera_coord.z, 1.0);
        //get camera ray
        float3 dir = normalize(make_float3(p.x, p.y, p.z) - eye);
        float epsilon = 0.001f;
        // Shoot a ray to compute the color of the current pixel
        Payload payload;
        payload.done = false;
        payload.first = 1;
        if (NEE == 1)
        {
            payload.NEE = 1;
            payload.depth = maxdepth - 1;
        }
        else
        {
            payload.NEE = 0;
            payload.depth = maxdepth;
        }
        payload.RR = RR;
        payload.origin = origin;
        payload.dir = dir;
        payload.pathTracingWeight = make_float3(1.0);
        payload.radiance = make_float3(0);
        while (!payload.done && (payload.depth > 0 || RR))
        {
            payload.seed = tea<16>(i * resultSize.x * resultSize.y + launchIndex.x * resultSize.y + launchIndex.y, i * maxdepth + payload.depth);
            Ray ray = make_Ray(origin, dir, 0, epsilon, RT_DEFAULT_MAX);
            rtTrace(root, ray, payload);
            payload.first = 0;
            origin = payload.origin;
            dir = payload.dir;
            payload.depth--;
        }
        sum += payload.radiance;
        //rtPrintf("%d\n", payload.depth);
    }
    result = sum/spp;
    result = make_float3(pow(result.x, (float)(1 / gamma)), pow(result.y, (float)(1 / gamma)), pow(result.z, (float)(1 / gamma)));
    // Write the result
    resultBuffer[launchIndex] = result;
}
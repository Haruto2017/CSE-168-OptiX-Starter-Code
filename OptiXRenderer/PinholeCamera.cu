#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>

#include "Payloads.h"

using namespace optix;

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

RT_PROGRAM void generateRays()
{
    float3 result = make_float3(0.f);

    // TODO: calculate the ray direction (change the following lines)
    float3 origin = eye; 
    float aspect_ratio = (float)width / (float)height;
    float3 camera_coord = make_float3(fov * aspect_ratio * (2.0 * ((launchIndex.x + 0.5) / width) - 1.0), fov * (2.0 * ((launchIndex.y + 0.5) / height) - 1.0), -1.0);
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

    // TODO: modify the following lines if you need
    // Shoot a ray to compute the color of the current pixel
    Ray ray = make_Ray(origin, dir, 0, epsilon, RT_DEFAULT_MAX);
    Payload payload;
    rtTrace(root, ray, payload);

    // Write the result
    resultBuffer[launchIndex] = payload.radiance;
}
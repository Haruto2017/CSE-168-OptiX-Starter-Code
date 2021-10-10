#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>
#include "random.h"

#include "Payloads.h"
#include "Geometries.h"
#include "Light.h"

using namespace optix;

#define PI 3.1415926538

// Declare light buffers
rtBuffer<ParallelogramLight> qlights;
rtBuffer<PointLight> plights;
rtBuffer<DirectionalLight> dlights;

// Declare variables
rtDeclareVariable(Payload, payload, rtPayload, );
rtDeclareVariable(rtObject, root, , );

// Declare attibutes 
rtDeclareVariable(Attributes, attrib, attribute attrib, );
rtDeclareVariable(float3, intersection, attribute Intersection, );
rtDeclareVariable(float3, normal, attribute Normal, );
rtDeclareVariable(float3, view, attribute View, );

RT_PROGRAM void closestHit()
{
    // TDOO: calculate the color using the Blinn-Phong reflection model
    float3 result = attrib.emission + attrib.ambient;
    float epsilon = 0.001f;

    for (int i = 0; i < qlights.size(); ++i)
    {
        ParallelogramLight qlight = qlights[i];
        float3 u0 = qlight.a - intersection;
        float3 u1 = qlight.a + qlight.ab - intersection;
        float3 u2 = qlight.a + qlight.ab + qlight.ac - intersection;
        float3 u3 = qlight.a + qlight.ac - intersection;
        float theta0 = acos(dot(normalize(u0), normalize(u1)));
        float3 reverseL0 = normalize(cross(u0, u1));
        float theta1 = acos(dot(normalize(u1), normalize(u2)));
        float3 reverseL1 = normalize(cross(u1, u2));
        float theta2 = acos(dot(normalize(u2), normalize(u3)));
        float3 reverseL2 = normalize(cross(u2, u3));
        float theta3 = acos(dot(normalize(u3), normalize(u0)));
        float3 reverseL3 = normalize(cross(u3, u0));
        float3 irradiance = 0.5 * (theta0 * reverseL0 + theta1 * reverseL1 + theta2 * reverseL2 + theta3 * reverseL3);
        result += (attrib.diffuse / PI) * qlight.intensity * dot(irradiance, normal);
    }

    //payload.weight /= (1.0 + 0.1 * dis + 0.05 * dis * dis);
    payload.radiance = result;
}
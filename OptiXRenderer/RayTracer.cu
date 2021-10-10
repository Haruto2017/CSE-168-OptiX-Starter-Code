#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>
#include "random.h"

#include "Payloads.h"
#include "Geometries.h"
#include "Light.h"

using namespace optix;

// Declare light buffers
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
    for (int i = 0; i < plights.size(); ++i)
    {
        PointLight point = plights[i];
        float3 l = normalize(point.position - intersection);
        float dis = length(point.position - intersection);
        Ray shadowRay = make_Ray(intersection, l, 1, epsilon, dis);
        ShadowPayload shadowPayload;
        shadowPayload.isVisible = true;
        rtTrace(root, shadowRay, shadowPayload);
        if (shadowPayload.isVisible)
        {
            float3 light = point.color / (point.attenuation.x + point.attenuation.y * dis + point.attenuation.z * dis * dis);
            float3 h = normalize(-view + l);
            result += attrib.diffuse * light * fmaxf(0.0, dot(normal, l)) + light * pow(fmaxf(0, dot(normal, h)), attrib.shininess);
        }
    }
    for (int i = 0; i < dlights.size(); ++i)
    {
        DirectionalLight dir = dlights[i];
        float3 l = dir.direction;
        Ray shadowRay = make_Ray(intersection, l, 1, epsilon, RT_DEFAULT_MAX);
        ShadowPayload shadowPayload;
        shadowPayload.isVisible = true;
        rtTrace(root, shadowRay, shadowPayload);
        if (shadowPayload.isVisible)
        {
            float3 h = normalize(-view + l);
            result += attrib.diffuse * dir.color * fmaxf(0.0, dot(normal, l)) + dir.color * pow(fmaxf(0, dot(normal, h)), attrib.shininess);
        }
    }

    payload.radiance = result;
}
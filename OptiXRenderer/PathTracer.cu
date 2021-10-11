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
rtDeclareVariable(uint, lightsamples, , );
rtDeclareVariable(uint, lightstratify, , );

// Declare attibutes 
rtDeclareVariable(Attributes, attrib, attribute attrib, );
rtDeclareVariable(float3, intersection, attribute Intersection, );
rtDeclareVariable(float3, normal, attribute Normal, );
rtDeclareVariable(float3, view, attribute View, );
rtDeclareVariable(float, area, attribute Area, );

RT_PROGRAM void closestHit()
{
    float epsilon = 0.001f;
    float3 result = make_float3(0);
    //return the radiance if reach a light source
    if (abs(attrib.emission.x - 0.0) > epsilon || abs(attrib.emission.y - 0.0) > epsilon || abs(attrib.emission.z - 0.0) > epsilon)
    {
        if (payload.NEE == 0 || payload.first == 1)
        {
            payload.radiance += (attrib.emission / area) * payload.pathTracingWeight;
        }
        payload.done = true;
        return;
    }

    if (payload.NEE == 1)
    {
        for (int i = 0; i < qlights.size(); ++i)
        {
            ParallelogramLight qlight = qlights[i];
            float3 sum = make_float3(0, 0, 0);
            for (int j = 0; j < lightsamples; ++j)
            {
                float u1;
                float u2;
                if (lightstratify == 1)
                {
                    uint size = (uint)sqrt((float)lightsamples);
                    u1 = rnd(payload.seed) / size;
                    u2 = rnd(payload.seed) / size;
                    u1 += ((float)(j / size)) / size;
                    u2 += ((float)(j % size)) / size;
                }
                else
                {
                    u1 = rnd(payload.seed);
                    u2 = rnd(payload.seed);
                }
                //rtPrintf("%f %f \n", u1, u2);
                float3 xl = qlight.a + u1 * qlight.ab + u2 * qlight.ac;
                float3 l = normalize(xl - intersection);
                Ray shadowRay = make_Ray(intersection, l, 1, epsilon, length(xl - intersection) - epsilon);
                ShadowPayload shadowPayload;
                shadowPayload.isVisible = true;
                rtTrace(root, shadowRay, shadowPayload);
                if (!shadowPayload.isVisible)
                {
                    continue;
                }
                float3 r = 2 * normal * dot(normal, -view) + view;
                float3 brdf = attrib.diffuse / PI + attrib.specular * ((attrib.shininess + 2) / (2 * PI)) * pow(fmaxf(0.0, dot(r, l)), attrib.shininess);
                float costhetai = fmaxf(0.0, dot(normal, l));
                float3 nl = normalize(cross(qlight.ab, qlight.ac));
                float costhetao = fmaxf(0.0, dot(l, nl));
                float g = (costhetai * costhetao) / (length(xl - intersection) * length(xl - intersection));
                sum += brdf * g;
            }
            float A = length(cross(qlight.ab, qlight.ac));
            result += qlight.intensity * A * (sum / lightsamples);
        }
    }
    //indirect lighting
    float u1 = rnd(payload.seed);
    float u2 = rnd(payload.seed);
    float theta = acos(u1);
    float phi = 2 * PI * u2;
    float3 s = make_float3(cos(phi) * sin(theta), sin(theta) * sin(phi), cos(theta));
    float3 a;
    if (abs(normal.y - 1.0) < epsilon)
    {
        a = make_float3(1, 0, 0);
    }
    else
    {
        a = make_float3(0, 1, 0);
    }
    float3 u = normalize(cross(a, normal));
    float3 v = cross(normal, u);
    float3 l = s.x * u + s.y * v + s.z * normal;
    float3 r = 2 * normal * dot(normal, -view) + view;
    float3 brdf = attrib.diffuse / PI + attrib.specular * ((attrib.shininess + 2) / (2 * PI)) * pow(fmaxf(0.0, dot(r, l)), attrib.shininess);
    float3 currWeight = 2 * PI * brdf * dot(normal, l);
    
    payload.radiance += result * payload.pathTracingWeight;
    payload.pathTracingWeight *= currWeight;
    payload.origin = intersection;
    payload.dir = l;
    //payload.depth--;
}
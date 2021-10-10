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

RT_PROGRAM void closestHit()
{
    // TDOO: calculate the color using the Blinn-Phong reflection model
    float3 result = attrib.emission + attrib.ambient;
    float epsilon = 0.001f;
    
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

    //payload.weight /= (1.0 + 0.1 * dis + 0.05 * dis * dis);
    payload.radiance = result;
}
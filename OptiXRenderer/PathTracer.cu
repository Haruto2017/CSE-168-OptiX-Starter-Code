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
rtDeclareVariable(uint, importancesampling, , );

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
    uint brdf = attrib.brdf;
    //return the radiance if reach a light source (only check once when using next event estimation)
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
                float3 brdf_val;
                if (brdf == 1)
                {
                    float3 r = view - 2 * normal * dot(normal, view);
                    brdf_val = attrib.diffuse / PI + attrib.specular * ((attrib.shininess + 2) / (2 * PI)) * pow(fmaxf(0.0, dot(r, l)), attrib.shininess);
                }
                else
                {
                    if (dot(normal, l) < 0)
                    {
                        brdf_val = make_float3(0);
                    }
                    else
                    {
                        float3 h = normalize(-view + l);
                        //Normal Distribution Function term (GGX)
                        float a_2 = attrib.roughness * attrib.roughness;
                        float theta_h = acos(clamp(dot(h, normal), (float)epsilon, (float)1));
                        float br = pow(a_2 + tan(theta_h) * tan(theta_h), (float)2.0);
                        float bl = PI * pow(clamp(dot(h, normal), (float)epsilon, (float)1), (float)4.0);
                        float D = a_2 / (br * bl);

                        //Shadow Masking term (Smith G Function)
                        float G1_l = 0;
                        if (dot(l, normal) > 0)
                        {
                            float theta_l = acos(dot(l, normal));
                            G1_l = 2 / (1 + sqrt(1 + a_2 * pow(tan(theta_l), (float)2.0)));
                        }
                        float G1_v = 0;
                        if (dot(-view, normal) > 0)
                        {
                            float theta_v = acos(dot(-view, normal));
                            G1_v = 2 / (1 + sqrt(1 + a_2 * pow(tan(theta_v), (float)2.0)));
                        }
                        float G = G1_l * G1_v;

                        //Fresnel term (Schlick's Approximation)
                        float3 F = attrib.specular + (1 - attrib.specular) * pow(1 - clamp(dot(l, h), (float)epsilon, (float)1), (float)5.0);
                        //final output
                        brdf_val = F * G * D / (4 * dot(l, normal) * dot(-view, normal));
                        brdf_val += attrib.diffuse / PI;
                    }
                }
                float costhetai = fmaxf(0.0, dot(normal, l));
                float3 nl = normalize(cross(qlight.ab, qlight.ac));
                float costhetao = fmaxf(0.0, dot(l, nl));
                float g = (costhetai * costhetao) / (length(xl - intersection) * length(xl - intersection));
                sum += brdf_val * g;
            }
            float A = length(cross(qlight.ab, qlight.ac));
            result += qlight.intensity * A * (sum / lightsamples);
        }
    }
    //Russian Roulette
    float boost = 1.0;
    if (payload.RR == 1)
    {
        float curr = rnd(payload.seed);
        float q = 1 - fminf(fmaxf(fmaxf(payload.pathTracingWeight.x, payload.pathTracingWeight.y), payload.pathTracingWeight.z), 1.0);
        if (curr < q)
        {
            payload.done = true;
            payload.radiance += result * payload.pathTracingWeight;
            return;
        }
        else
        {
            boost = 1 / (1 - q);
        }
    }
    //indirect lighting
    float pdf_inver;
    float3 l;
    float3 h;
    //importance sampling the integrated function
    //sample the hemisphere, cosine term, or brdf
    if (importancesampling == 1)
    {
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
        l = s.x * u + s.y * v + s.z * normal;
        pdf_inver = 2 * PI;
    }
    else if (importancesampling == 2)
    {
        float u1 = rnd(payload.seed);
        float u2 = rnd(payload.seed);
        float theta = acos(u1 * u1);
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
        l = s.x * u + s.y * v + s.z * normal;
        pdf_inver = PI / dot(normal, l);
    }
    else if (importancesampling == 3)
    {
        if (brdf == 1)
        {
            float s_bar = (attrib.specular.x + attrib.specular.y + attrib.specular.z) / 3;
            float d_bar = (attrib.diffuse.x + attrib.diffuse.y + attrib.diffuse.z) / 3;
            float t;
            if (abs(s_bar) < epsilon && abs(d_bar < epsilon))
            {
                t = 1.0;
            }
            else
            {
                t = s_bar / (d_bar + s_bar);
            }
            float u1 = rnd(payload.seed);
            float u2 = rnd(payload.seed);
            float u3 = rnd(payload.seed);
            float theta;
            float3 w;
            float3 r = 2 * normal * dot(normal, -view) + view;
            if (u1 <= t)
            {
                theta = acos(pow(u2, (float)(1.0 / (attrib.shininess + 1))));
                w = r;
            }
            else
            {
                theta = acos(sqrt(u2));
                w = normal;
            }
            float phi = 2 * PI * u3;
            float3 s = make_float3(cos(phi) * sin(theta), sin(theta) * sin(phi), cos(theta));
            float3 a;
            if (abs(w.y - 1.0) < epsilon)
            {
                a = make_float3(1, 0, 0);
            }
            else
            {
                a = make_float3(0, 1, 0);
            }
            float3 u = normalize(cross(a, w));
            float3 v = cross(w, u);
            l = s.x * u + s.y * v + s.z * w;
            if (u1 <= t)
            {
                pdf_inver = t * ((attrib.shininess + 1) / (2 * PI)) * pow(dot(r, l), attrib.shininess);
                pdf_inver = 1 / pdf_inver;
            }
            else
            {
                pdf_inver = (1 - t) * dot(normal, l) / PI;
                pdf_inver = 1 / pdf_inver;
            }
        }
        else
        {
            float s_bar = (attrib.specular.x + attrib.specular.y + attrib.specular.z) / 3;
            float d_bar = (attrib.diffuse.x + attrib.diffuse.y + attrib.diffuse.z) / 3;
            float t;
            if (abs(s_bar) < epsilon && abs(d_bar < epsilon))
            {
                t = 1.0;
            }
            else
            {
                t = fmaxf(0.25, s_bar / (d_bar + s_bar));
            }
            float u1 = rnd(payload.seed);
            float u2 = rnd(payload.seed);
            float u3 = rnd(payload.seed);
            float theta;
            float phi;
            float3 w = normal;
            //float3 r = 2 * normal * dot(normal, -view) + view;
            //choose between the diffuse and the specular term
            if (u1 <= t)
            {
                phi = 2 * PI * u3;
                theta = atan(attrib.roughness * sqrt(u2) / clamp(sqrt(1 - u2), epsilon, (float)1));
            }
            else
            {
                phi = 2 * PI * u3;
                theta = acos(sqrt(u2));
            }
            //rotate to the hemisphere indicated by the surface normal
            float3 s = make_float3(cos(phi) * sin(theta), sin(theta) * sin(phi), cos(theta));
            float3 a;
            if (abs(w.y - 1.0) < epsilon)
            {
                a = make_float3(1, 0, 0);
            }
            else
            {
                a = make_float3(0, 1, 0);
            }
            float3 u = normalize(cross(a, w));
            float3 v = cross(w, u);
            l = s.x * u + s.y * v + s.z * w;
            h = normalize(-view + l);
            //we only found the half vector for the microfacet brdf so we need to reflect our view vector off the half vector
            if (u1 <= t)
            {
                h = make_float3(l.x, l.y, l.z);
                l = 2 * h * dot(h, -view) + view;
                if (dot(l, normal) < 0)
                {
                    payload.done = true;
                    pdf_inver = 0;
                }
                else
                {
                    float a_2 = attrib.roughness * attrib.roughness;
                    float cos_h = clamp(dot(h, normal), (float)epsilon, (float)1);
                    float theta_h = acos(cos_h);
                    float br = pow(a_2 + tan(theta_h) * tan(theta_h), (float)2.0);
                    float bl = PI * pow(cos(theta_h), (float)4.0);
                    float D = a_2 / (br * bl);

                    pdf_inver = t * cos_h * D / (4 * clamp(dot(h, l), epsilon, (float)1));
                    pdf_inver = 1 / pdf_inver;
                }
            }
            else
            {
                pdf_inver = (1 - t) * dot(normal, l) / PI;
                pdf_inver = 1 / pdf_inver;
            }
        }
    }
    float3 brdf_val;
    if (brdf == 1)
    {
        float3 r = view - 2 * normal * dot(normal, view);
        brdf_val = attrib.diffuse / PI + attrib.specular * ((attrib.shininess + 2) / (2 * PI)) * pow(fmaxf(0.0, dot(r, l)), attrib.shininess);
    }
    else
    {
        if (dot(l, normal) < 0)
        {
            //rtPrintf("any\n");
            brdf_val = make_float3(0);
        }
        else
        {
            //Normal Distribution Function term (GGX)
            float a_2 = attrib.roughness * attrib.roughness;
            float theta_h = acos(clamp(dot(h, normal), (float)epsilon, (float)1));
            float br = pow(a_2 + tan(theta_h) * tan(theta_h), (float)2.0);
            float bl = PI * pow(cos(theta_h), (float)4.0);
            float D = a_2 / (br * bl);

            //Shadow Masking term (Smith G Function)
            float G1_l = 0;
            if (dot(l, normal) > 0)
            {
                float theta_l = acos(dot(l, normal));
                G1_l = 2 / (1 + sqrt(1 + a_2 * pow(tan(theta_l), (float)2.0)));
            }
            float G1_v = 0;
            if (dot(-view, normal) > 0)
            {
                float theta_v = acos(dot(-view, normal));
                G1_v = 2 / (1 + sqrt(1 + a_2 * pow(tan(theta_v), (float)2.0)));
            }
            float G = G1_l * G1_v;

            //Fresnel term (Schlick's Approximation)
            float3 F = attrib.specular + (1 - attrib.specular) * pow(1 - clamp(dot(l, h), epsilon, (float)1), (float)5.0);
            //final output
            brdf_val = F * G * D/ (4 * clamp(dot(l, normal), epsilon, (float)1) * clamp(dot(-view, normal), epsilon, (float)1));
            brdf_val += attrib.diffuse / PI;
        }
    }
    float3 currWeight = pdf_inver * brdf_val * clamp(dot(l, normal), epsilon, (float)1);
    
    payload.radiance += 1.35 * result * payload.pathTracingWeight * boost;
    payload.pathTracingWeight *= currWeight;
    payload.origin = intersection;
    payload.dir = l;
}
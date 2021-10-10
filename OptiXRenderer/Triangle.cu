#include "optix.h"
#include "optix_device.h"
#include "Geometries.h"

using namespace optix;

rtBuffer<Triangle> triangles; // a buffer of all spheres
rtBuffer<float3> vertices;

rtDeclareVariable(Ray, ray, rtCurrentRay, );

// Attributes to be passed to material programs 
rtDeclareVariable(Attributes, attrib, attribute attrib, );

RT_PROGRAM void intersect(int primIndex)
{
    // Find the intersection of the current ray and triangle
    Triangle tri = triangles[primIndex];
    float3 v0 = vertices[tri.vertice0];
    float3 v1 = vertices[tri.vertice1];
    float3 v2 = vertices[tri.vertice2];
    float t;
    //if(primIndex > 800)
        //rtPrintf("i: %d\n", primIndex);
    // TODO: implement triangle intersection test here
    float u;
    float v;
    float3 v0v1 = v1 - v0;
    float3 v0v2 = v2 - v0;
    float3 pvec = cross(ray.direction, v0v2);
    float det = dot(v0v1, pvec);
    // Backface Culling
    float epsilon = 0.0001f;
    if (det < epsilon)
    {
        t = -1;
    }
    else
    {
        float invDet = 1 / det;
        float3 tvec = ray.origin - v0;
        u = dot(tvec, pvec) * invDet;
        if (u < 0 || u > 1)
        {
            t = -1;
        }
        else
        {
            float3 qvec = cross(tvec, v0v1);
            v = dot(ray.direction, qvec) * invDet;
            if (v < 0 || u + v > 1)
            {
                t = -1;
            }
            else
            {
                t = dot(v0v2, qvec) * invDet;
            }
        }
    }

    // Report intersection (material programs will handle the rest)
    if (rtPotentialIntersection(t))
    {
        // Pass attributes

        // TODO: assign attribute variables here

        rtReportIntersection(0);
    }
}

RT_PROGRAM void bound(int primIndex, float result[6])
{
    Triangle tri = triangles[primIndex];

    // TODO: implement triangle bouding box
    result[0] = -1000.f;
    result[1] = -1000.f;
    result[2] = -1000.f;
    result[3] = 1000.f;
    result[4] = 1000.f;
    result[5] = 1000.f;
}
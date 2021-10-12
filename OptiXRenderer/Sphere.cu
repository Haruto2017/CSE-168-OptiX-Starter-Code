#include <optix.h>
#include <optix_device.h>
#include "Geometries.h"

using namespace optix;

#define PI 3.1415926538

rtBuffer<Sphere> spheres; // a buffer of all spheres

rtDeclareVariable(Ray, ray, rtCurrentRay, );

// Attributes to be passed to material programs 
rtDeclareVariable(Attributes, attrib, attribute attrib, );
rtDeclareVariable(float3, intersection, attribute Intersection, );
rtDeclareVariable(float3, normal, attribute Normal, );
rtDeclareVariable(float3, view, attribute View, );
rtDeclareVariable(float, area, attribute Area, );

RT_PROGRAM void intersect(int primIndex)
{
    // Find the intersection of the current ray and sphere
    Sphere sphere = spheres[primIndex];
    float t;

    // TODO: implement sphere intersection test here
    float a = dot(ray.direction, ray.direction);
    float b = 2 * dot(ray.origin - sphere.center, ray.direction);
    float c = dot(ray.origin - sphere.center, ray.origin - sphere.center) - sphere.radius * sphere.radius;
    float delta = b * b - 4 * a * c;
    if (delta <= 0)
    {
        t = -1.0;
    }
    else
    {
        float t0 = (-b + sqrt(delta)) / (2 * a);
        float t1 = (-b - sqrt(delta)) / (2 * a);
        if (t0 > ray.tmin && t1 > ray.tmin)
        {
            t = (t0 < t1) ? t0 : t1;
        }
        else if (t0 > ray.tmin)
        {
            t = t0;
        }
        else
        {
            t = t1;
        }
    }

    // Report intersection (material programs will handle the rest)
    if (rtPotentialIntersection(t))
    {
        // Pass attributes

        // TODO: assign attribute variables here
        attrib.ambient = sphere.ambient;
        attrib.emission = sphere.emission;
        attrib.diffuse = sphere.diffuse;
        attrib.specular = sphere.specular;
        attrib.shininess = sphere.shininess;
        attrib.roughness = sphere.roughness;
        attrib.brdf = sphere.brdf;

        intersection = ray.origin + t * ray.direction;
        normal = normalize(intersection - sphere.center);
        view = ray.direction;
        area = 4 * PI * sphere.radius * sphere.radius;

        rtReportIntersection(0);
    }
}

RT_PROGRAM void bound(int primIndex, float result[6])
{
    Sphere sphere = spheres[primIndex];

    // TODO: implement sphere bouding box
    result[0] = -1000.f;
    result[1] = -1000.f;
    result[2] = -1000.f;
    result[3] = 1000.f;
    result[4] = 1000.f;
    result[5] = 1000.f;
}
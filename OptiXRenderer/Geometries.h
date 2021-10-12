#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different geometries should be defined here.
 */

struct Triangle
{
    // TODO: define the triangle structure
    optix::float3 vertice0;
    optix::float3 vertice1;
    optix::float3 vertice2;
    optix::float3 normal;

    optix::float3 ambient;
    optix::float3 diffuse;
    optix::float3 emission;
    optix::float3 specular;
    float shininess;
    float roughness;
    unsigned int brdf;

    Triangle(optix::float3 v0, optix::float3 v1, optix::float3 v2, optix::float3 a, optix::float3 d, optix::float3 e, optix::float3 s, float shininess, float roughness, unsigned int brdf)
    {
        vertice0 = v0;
        vertice1 = v1;
        vertice2 = v2;
        normal = optix::normalize(optix::cross(vertice1 - vertice0, vertice2 - vertice0));

        ambient = a;
        diffuse = d;
        emission = e;
        specular = s;
        this->shininess = shininess;
        this->roughness = roughness;
        this->brdf = brdf;
    }
};

struct Sphere
{
    optix::float3 center;
    float radius;

    optix::float3 ambient;
    optix::float3 diffuse;
    optix::float3 emission;
    optix::float3 specular;
    float shininess;
    float roughness;
    unsigned int brdf;

    Sphere(optix::float3 c, float r, optix::float3 a, optix::float3 d, optix::float3 e, optix::float3 s, float shininess, float roughness, unsigned int brdf)
    {
        center = c;
        radius = r;

        ambient = a;
        diffuse = d;
        emission = e;
        specular = s;
        this->shininess = shininess;
        this->roughness = roughness;
        this->brdf = brdf;
    }
};

struct Attributes
{
    // TODO: define the attributes structure
    optix::float3 ambient;
    optix::float3 diffuse;
    optix::float3 emission;
    optix::float3 specular;
    float shininess;
    float roughness;
    float brdf;
};
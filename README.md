# Optix-Based-Path-Tracer

A Path Tracer built with Nvidia Optix. The Optix Skeleton is provided by [CSE168 at UCSD][https://github.com/CSE168sp20/CSE-168-OptiX-Starter-Code]. 
In this renderer, the following functionalities are implemented and more are coming.

##List of Implementation
1. Geometry and Light Representation
2. Ray-Geometry Intersection Checking for Triangles (Moller Trumbore Algorithm) and Spheres
3. Ray Generation with Camera Ray Calculation
4. Analytic Solution for Solving the Rendering Equation with Direct Polygon Lights
5. Monte Carlo Integration for Solving the Rendering Equation with Direct Polygon Lights
6. Monte Carlo Path Tracing where recursions are done iteratively
7. Separation of Indirect and Direct Lighting Calculation (Next Event Estimator) for Path Tracing
8. Russian Roulette for Unbiased Path Tracing
9. Cosine and Modified Phong Material BRDF Importance Sampling for Indirect Light
10. GGX Microfacet Materials with BRDF Importance Sampling

##Planned Fuctionalities
1. Linearly Transformed Cosine
2. Temporal and Bilateral Filtering

#include "SceneLoader.h"

void SceneLoader::rightMultiply(const optix::Matrix4x4& M)
{
    optix::Matrix4x4& T = transStack.top();
    T = T * M;
}

optix::float3 SceneLoader::transformPoint(optix::float3 v)
{
    optix::float4 vh = transStack.top() * optix::make_float4(v, 1);
    return optix::make_float3(vh) / vh.w; 
}

optix::float3 SceneLoader::transformNormal(optix::float3 n)
{
    return optix::make_float3(transStack.top() * make_float4(n, 0));
}

template <class T>
bool SceneLoader::readValues(std::stringstream& s, const int numvals, T* values)
{
    for (int i = 0; i < numvals; i++)
    {
        s >> values[i];
        if (s.fail())
        {
            std::cout << "Failed reading value " << i << " will skip" << std::endl;
            return false;
        }
    }
    return true;
}


std::shared_ptr<Scene> SceneLoader::load(std::string sceneFilename)
{
    // Attempt to open the scene file 
    std::ifstream in(sceneFilename);
    if (!in.is_open())
    {
        // Unable to open the file. Check if the filename is correct.
        throw std::runtime_error("Unable to open scene file " + sceneFilename);
    }

    auto scene = std::make_shared<Scene>();
    //Transformation
    transStack.push(optix::Matrix4x4::identity());
    std::stack<float> sphere_scale;
    sphere_scale.push(1.0);
    //Materials
    optix::float3 ambient = optix::make_float3(0, 0, 0);
    optix::float3 diffuse = optix::make_float3(0, 0, 0);
    optix::float3 emission = optix::make_float3(0, 0, 0);
    optix::float3 specular = optix::make_float3(0, 0, 0);
    float shininess = 1.0;
    float roughness = 1.0;
    unsigned int brdf = 1;

    optix::float3 attenuation = optix::make_float3(1, 0, 0);

    std::string str, cmd;

    // Read a line in the scene file in each iteration
    while (std::getline(in, str))
    {
        // Ruled out comment and blank lines
        if ((str.find_first_not_of(" \t\r\n") == std::string::npos) 
            || (str[0] == '#'))
        {
            continue;
        }

        // Read a command
        std::stringstream s(str);
        s >> cmd;

        // Some arrays for storing values
        float fvalues[12];
        int ivalues[3];
        std::string svalues[1];

        if (cmd == "size" && readValues(s, 2, fvalues))
        {
            scene->width = (unsigned int)fvalues[0];
            scene->height = (unsigned int)fvalues[1];
        }
        else if (cmd == "output" && readValues(s, 1, svalues))
        {
            scene->outputFilename = svalues[0];
        }
        else if (cmd == "camera" && readValues(s, 10, fvalues))
        {
            scene->eye.x = fvalues[0];
            scene->eye.y = fvalues[1];
            scene->eye.z = fvalues[2];
            scene->center.x = fvalues[3];
            scene->center.y = fvalues[4];
            scene->center.z = fvalues[5];
            scene->up.x = fvalues[6];
            scene->up.y = fvalues[7];
            scene->up.z = fvalues[8];
            scene->fovy = (unsigned int)fvalues[9];
        }
        else if (cmd == "maxverts" && readValues(s, 1, fvalues))
        {
            scene->maxverts = (unsigned int)fvalues[0];
        }
        else if (cmd == "vertex" && readValues(s, 3, fvalues))
        {
            scene->vertices.push_back(optix::make_float3(fvalues[0], fvalues[1], fvalues[2]));
        }
        else if (cmd == "tri" && readValues(s, 3, fvalues))
        {
            scene->triangles.push_back(Triangle(transformPoint(scene->vertices[(unsigned int)fvalues[0]]), 
                transformPoint(scene->vertices[(unsigned int)fvalues[1]]), transformPoint(scene->vertices[(unsigned int)fvalues[2]]), ambient, diffuse, emission, specular, shininess, roughness, brdf));
        }
        else if (cmd == "sphere" && readValues(s, 4, fvalues))
        {
            scene->spheres.push_back(Sphere(transformPoint(optix::make_float3(fvalues[0], fvalues[1], fvalues[2])), fvalues[3] * sphere_scale.top(), ambient, diffuse, emission, specular, shininess, roughness, brdf));
        }
        else if (cmd == "pushTransform")
        {
            transStack.push(transStack.top());
            sphere_scale.push(sphere_scale.top());
        }
        else if (cmd == "popTransform")
        {
            transStack.pop();
            sphere_scale.pop();
        }
        else if (cmd == "translate" && readValues(s, 3, fvalues))
        {
            optix::Matrix<4, 4> translate = optix::Matrix4x4::translate(optix::make_float3(float(fvalues[0]), float(fvalues[1]), float(fvalues[2])));
            rightMultiply(translate);
        }
        else if (cmd == "rotate" && readValues(s, 4, fvalues))
        {
            optix::Matrix<4, 4> rotate = optix::Matrix4x4::rotate(fvalues[3] * M_PI / 180, optix::make_float3(float(fvalues[0]), float(fvalues[1]), float(fvalues[2])));
            rightMultiply(rotate);
        }
        else if (cmd == "scale" && readValues(s, 3, fvalues))
        {
            optix::Matrix<4, 4> scale = optix::Matrix4x4::scale(optix::make_float3(float(fvalues[0]), float(fvalues[1]), float(fvalues[2])));
            rightMultiply(scale);
            float& temp = sphere_scale.top();
            temp = temp * (fvalues[0] + fvalues[1] + fvalues[2]) / 3;
        }
        else if (cmd == "ambient" && readValues(s, 3, fvalues))
        {
            ambient = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "diffuse" && readValues(s, 3, fvalues))
        {
            diffuse = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "emission" && readValues(s, 3, fvalues))
        {
            emission = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "specular" && readValues(s, 3, fvalues))
        {
            specular = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "shininess" && readValues(s, 1, fvalues))
        {
            shininess = fvalues[0];
        }
        else if (cmd == "point" && readValues(s, 6, fvalues))
        {
            scene->plights.push_back(PointLight(optix::make_float3(fvalues[0], fvalues[1], fvalues[2]), optix::make_float3(fvalues[3], fvalues[4], fvalues[5]), attenuation));
        }
        else if (cmd == "directional" && readValues(s, 6, fvalues))
        {
            scene->dlights.push_back(DirectionalLight(optix::make_float3(fvalues[0], fvalues[1], fvalues[2]), optix::make_float3(fvalues[3], fvalues[4], fvalues[5]), attenuation));
        }
        else if (cmd == "attenuation" && readValues(s, 3, fvalues))
        {
            attenuation = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "maxdepth" && readValues(s, 1, fvalues))
        {
            scene->maxdepth = fvalues[0];
        }
        else if (cmd == "integrator" && readValues(s, 1, svalues))
        {
            scene->integratorName = svalues[0];
        }
        else if (cmd == "quadLight" && readValues(s, 12, fvalues))
        {
            optix::float3 a = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
            optix::float3 ab = optix::make_float3(fvalues[3], fvalues[4], fvalues[5]);
            optix::float3 ac = optix::make_float3(fvalues[6], fvalues[7], fvalues[8]);
            optix::float3 intensity = optix::make_float3(fvalues[9], fvalues[10], fvalues[11]);
            scene->qlights.push_back(ParallelogramLight(a, ab, ac, intensity));
            optix::float3 t_ambient = optix::make_float3(0, 0, 0);
            optix::float3 t_diffuse = optix::make_float3(0, 0, 0);
            optix::float3 t_emission = intensity / 2;
            optix::float3 t_specular = optix::make_float3(0, 0, 0);;
            float t_shininess = 1.0;
            scene->triangles.push_back(Triangle(a, a + ab + ac, a + ab, t_ambient, t_diffuse, t_emission, t_specular, t_shininess, 1.0, 1));
            scene->triangles.push_back(Triangle(a, a + ac, a + ab + ac, t_ambient, t_diffuse, t_emission, t_specular, t_shininess, 1.0, 1));
        }
        else if (cmd == "lightsamples" && readValues(s, 1, fvalues))
        {
            scene->lightsamples = (unsigned int)fvalues[0];
        }
        else if (cmd == "lightstratify" && readValues(s, 1, svalues))
        {
            scene->lightstratify = svalues[0].compare("on") ? 0 : 1;
        }
        else if (cmd == "spp" && readValues(s, 1, fvalues))
        {
            scene->spp = (unsigned int)fvalues[0];
        } 
        else if (cmd == "nexteventestimation" && readValues(s, 1, svalues))
        {
            scene->NEE = svalues[0].compare("on") ? 0 : 1;
        }
        else if (cmd == "russianroulette" && readValues(s, 1, svalues))
        {
            scene->RR = svalues[0].compare("on") ? 0 : 1;
        }
        else if (cmd == "importancesampling" && readValues(s, 1, svalues))
        {
            unsigned int temp = 0;
            temp += svalues[0].compare("hemisphere") ? 0 : 1;
            temp += svalues[0].compare("cosine") ? 0 : 2;
            temp += svalues[0].compare("brdf") ? 0 : 3;
            scene->IS = temp;
        }
        else if (cmd == "brdf" && readValues(s, 1, svalues))
        {
            brdf = svalues[0].compare("phong") ? 0 : 1;
        }
        else if (cmd == "roughness" && readValues(s, 1, fvalues))
        {
            roughness = fvalues[0];
        }
        else if (cmd == "gamma" && readValues(s, 1, fvalues))
        {
            scene->gamma = fvalues[0];
        }
    }

    in.close();

    return scene;
}
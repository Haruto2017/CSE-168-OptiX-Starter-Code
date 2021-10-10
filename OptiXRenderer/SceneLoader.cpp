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

    transStack.push(optix::Matrix4x4::identity());

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
            optix::float3 v0 = scene->vertices[(unsigned int)fvalues[0]];
            optix::float3 v1 = scene->vertices[(unsigned int)fvalues[1]];
            optix::float3 v2 = scene->vertices[(unsigned int)fvalues[2]];
            optix::float3 n = optix::normalize(optix::cross(v1 - v0, v2 - v0));
            scene->triangles.push_back(Triangle((unsigned int)fvalues[0], (unsigned int)fvalues[1], (unsigned int)fvalues[2], n));
        }
    }

    in.close();

    return scene;
}
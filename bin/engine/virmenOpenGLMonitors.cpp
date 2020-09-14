#include <mex.h>
#include "GLFW/glfw3.h"
#include <stdint.h>


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{   
    
    int width, height;
    int x, y;
    int *monitorInfo;
    const GLFWvidmode *mode;
    int dummy;
    int numMonitors;
    GLFWmonitor** allMonitors;
    int i;
    
    mexAtExit(glfwTerminate);
    if (glfwInit() != GL_TRUE)
      mexErrMsgIdAndTxt("virmenOpenGLMonitors:glfwInit", "Failed to initialize OpenGL graphics.");
    
    allMonitors = glfwGetMonitors(&numMonitors);
    
    glfwGetMonitorPos(glfwGetPrimaryMonitor(), &x, &y);
    mode = glfwGetVideoMode(glfwGetPrimaryMonitor());
    width = mode->width;
    height = mode->height;
    plhs[0] = mxCreateNumericMatrix(4, numMonitors+1, mxINT32_CLASS, mxREAL);
    monitorInfo = (int*) mxGetData(plhs[0]);
    monitorInfo[0] = x;
    monitorInfo[1] = y;
    monitorInfo[2] = width;
    monitorInfo[3] = height;
    
    for (i = 0; i < numMonitors; i++) {
        glfwGetMonitorPos(allMonitors[i], &x, &y);
        mode = glfwGetVideoMode(allMonitors[i]);
        width = mode->width;
        height = mode->height;
        monitorInfo = (int*) mxGetData(plhs[0]);
        monitorInfo[4*i+4] = x;
        monitorInfo[4*i+5] = y;
        monitorInfo[4*i+6] = width;
        monitorInfo[4*i+7] = height;
    }
    
    glfwTerminate();
}
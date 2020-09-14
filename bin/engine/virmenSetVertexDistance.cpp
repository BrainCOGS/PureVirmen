#include "mex.h"
#include "cPointer.h"
#include "GLEW/glew.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
  const double* distance = mxGetPr(prhs[1]);
  const size_t  nVertices = mxGetNumberOfElements(prhs[1]);
  GLfloat* vertexArray = matToCPointer<GLfloat>(prhs[2]);

  for ( size_t col = 0; col < nVertices; ++col )
    vertexArray[3*col+2] = distance[col];

}

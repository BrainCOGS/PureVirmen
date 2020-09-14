#include "mex.h"
#include <cstdint>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) 
{
    
    mwSize          nTria       = mxGetN(prhs[0]);
    
    const int32_t*  tria        = (const int32_t*) mxGetPr(prhs[0]);
    const double*   vertexArray = mxGetPr(prhs[1]);
    const mwSize    nDim        = static_cast<mwSize>(mxGetScalar(prhs[2]));
    const double    nVert       = mxGetScalar(prhs[3]);
    const bool*     isVisible   = (const bool*) mxGetPr(prhs[4]);
    
    mwSize          dims[3];
    dims[0]                     = 3;
    dims[1]                     = nTria;
    dims[2]                     = nDim;
    plhs[0]                     = mxCreateNumericArray(3, dims, mxINT32_CLASS, mxREAL);
    int32_t*        newTria     = (int32_t*) mxGetPr(plhs[0]);
    
    
    const mwSize    nCoord      = static_cast<mwSize>( 3*nVert );
    
    for ( mwSize d = 0; d < nDim; d++ ) {
        for ( mwSize index = 0; index < nTria; index++ ) {
            newTria[3*nTria*d+3*index] = 0;
            newTria[3*nTria*d+3*index+1] = 0;
            newTria[3*nTria*d+3*index+2] = 0;
            if (isVisible[index]==1 && (vertexArray[nCoord*d+3*tria[3*index]+2]==1 || vertexArray[nCoord*d+3*tria[3*index+1]+2]==1 || vertexArray[nCoord*d+3*tria[3*index+2]+2]==1)) {
                newTria[3*nTria*d+3*index] = tria[3*index];
                newTria[3*nTria*d+3*index+1] = tria[3*index+1];
                newTria[3*nTria*d+3*index+2] = tria[3*index+2];
            }
        }
    }
    
    return;
}

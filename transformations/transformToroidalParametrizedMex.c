#include "mex.h"
#include "math.h"

/**
 *  Matlab code used to fit the measured toroidal screen angles (a) at given radii (r) as seen in
 *  the toroidCalibration Virmen world.
 *
 *    r = 0.3:0.05:0.7;
 *    s = -pi/7:0.01:pi/4;
 *    a = [-16,-11,-4.58,2,8,15,21,28,35] * pi/180;       % REPLACE ME
 *    f = fit(a',r','poly1')
 *    figure; hold on; plot(a,r,'+'); plot(s,f(s),'r-');
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    mwSize ncols, index;
    double *coord3new, *coord3;
    double r, rinv, rnew;
    const double pi=3.14159;
    
    ncols = mxGetN(prhs[0]);
    plhs[0] = mxCreateDoubleMatrix(3,ncols,mxREAL);

    coord3new = mxGetPr(plhs[0]);
    coord3 = mxGetPr(prhs[0]);
    
    for ( index = 0; index < ncols; index++ ) {
        coord3new[3*index+2] = 1;
        r = sqrt(coord3[3*index]*coord3[3*index]+coord3[3*index+1]*coord3[3*index+1]);
        if ( r == 0 ) continue;
        
        rnew = TOROIDP1 * atan(coord3[3*index+2]/r) + TOROIDP2;
        rinv = 1;
        if ( rnew < 0 ) {
            rnew = 0;
            coord3new[3*index+2] = 0;
        }
        if ( rnew > 1 ) {
            rnew = 1;
            coord3new[3*index+2] = 0;
        }
        
        coord3new[3*index] = rnew*coord3[3*index]/r;
        coord3new[3*index+1] = rnew*coord3[3*index+1]/r;
        
/*        // pmask = vertexArray(2,:)>vertexArray(1,:) | vertexArray(2,:)>-vertexArray(1,:); turn invisible a wedge one quqarter of the world behind the animal
        if ( (coord3[3*index+1] < coord3[3*index]) && (coord3[3*index+1] < -coord3[3*index]) ) {
            rnew = 1;
            coord3new[3*index+2] = 0;
        }
 */       
        
        //

    }
    return;
}

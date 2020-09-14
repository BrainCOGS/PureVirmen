#include "mex.h"
#include <cmath>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {


const double pi = 3.1415926;

const double tanElevMax=std::abs(std::tan(45*pi/180)); //max visible elevation 35
const double tanAzimMax=std::abs(std::tan(125*pi/180)); //max visible azimuth 125


//spherical screen radius and coordinates relative to the animal head
// s is sphere, m is mouse, 0 is center of spherical mirror
const double Rs=8; 
const double xsm=17.5/25.4; 
const double ysm=0;
const double zsm=16.5/25.4; //
const double xOm=7.5*std::cos(58*pi/180);
const double yOm=0;
const double zOm=-7.5*std::sin(58*pi/180);
//radius of the spherical mirror (Silver coated lens LA1740-Thorlabs)
const double r=43.8/25.4;
//projector position P1 relative to the mirror center O
const double xP1o=11.30;
const double yP1o=0;
const double zP1o=-1.25;

mwSize ncols = mxGetN(prhs[0]);
plhs[0] = mxCreateDoubleMatrix(3,ncols,mxREAL);

double *coord3new = mxGetPr(plhs[0]);
double *coord3    = mxGetPr(prhs[0]);


const double c=xsm*xsm + ysm*ysm + zsm*zsm - Rs*Rs;
const double aab=std::sqrt(xP1o*xP1o+zP1o*zP1o);
const double sinpsi= zP1o/aab;
const double cospsi= xP1o/aab;
const double xP1opsi=cospsi*xP1o+sinpsi*zP1o;
const double yP1opsi=yP1o;
const double zP1opsi=-sinpsi*xP1o+cospsi*zP1o;


for ( int index = 0; index < ncols; index++ ) {
    
    const double a=std::pow(coord3[3*index+1],2)+
      std::pow(coord3[3*index+0],2)+
      std::pow(coord3[3*index+2],2);
    const double b=-2*(coord3[3*index+1]*xsm+coord3[3*index]*ysm+coord3[3*index+2]*zsm);
    const double t1=(-b+std::sqrt(b*b-4*a*c))/(2*a) ;
    const double t2=(-b-std::sqrt(b*b-4*a*c))/(2*a) ;
    double t = 0;
    if(t1>=0){t=t1;}
    if(t2>0) {t=t2;}
            
    const double xP2o=coord3[3*index+1]*t-xOm;
    const double yP2o=coord3[3*index+0]*t-yOm;
    const double zP2o=coord3[3*index+2]*t-zOm;


    const double xP2opsi=cospsi*xP2o+sinpsi*zP2o;
    const double yP2opsi=yP2o;
    const double zP2opsi=-sinpsi*xP2o+cospsi*zP2o;

    const double aac=sqrt(zP2opsi*zP2opsi+yP2opsi*yP2opsi);
    const double sinalpha=yP2opsi/aac;
    const double cosalpha=zP2opsi/aac;

    const double P2x=xP2opsi;
    const double P2y=cosalpha*yP2opsi-sinalpha*zP2opsi;
    const double P2z=sinalpha*yP2opsi+ cosalpha*zP2opsi;

    const double P1x=xP1opsi;
    const double P1y=cosalpha*yP1opsi-sinalpha*zP1opsi;
    const double P1z=sinalpha*yP1opsi+ cosalpha*zP1opsi;

    const double P1norm=std::sqrt(P1x*P1x+P1y*P1y+P1z*P1z);
    const double P2norm=std::sqrt(P2x*P2x+P2y*P2y+P2z*P2z);
    const double P3x=P1x/P1norm+P2x/P2norm;
    const double P3y=P1y/P1norm+P2y/P2norm;
    const double P3z=P1z/P1norm+P2z/P2norm;
    const double P3norm=std::sqrt(P3x*P3x+P3y*P3y+P3z*P3z);
    const double YY=std::sqrt(
                  std::pow((P1y*P3z - P1z*P3y),2)+
                  std::pow((P1z*P3x - P1x*P3z),2)+
                  std::pow((P1x*P3y - P1y*P3x),2)
                );
    const double XX=(P1x*P3x + P1y*P3y + P1z*P3z);

    const double sintheta=YY/(P1norm*P3norm);
    const double costheta=XX/(P1norm*P3norm);

    const double sinphi=r*sintheta/std::sqrt(std::pow(r*sintheta,2)+std::pow(P1x-r*costheta,2));

    coord3new[3*index]=   1.1*5.5122*(sinphi*sinalpha-0.019);
    coord3new[3*index+1]= 5.5122*(sinphi*cosalpha-0.0931); 

    coord3new[3*index+2]=1;
    if( std::sqrt ( std::pow(coord3[3*index+2],2)
                  / ( std::pow(coord3[3*index],2)
                    + std::pow(coord3[3*index+1],2)
                    ) ) > tanElevMax 
      || ( coord3[3*index+1] < 0
        && std::abs(coord3[3*index+1]/coord3[3*index])>tanAzimMax)
       )
    {
      coord3new[3*index+2]=0;
    }
}
}
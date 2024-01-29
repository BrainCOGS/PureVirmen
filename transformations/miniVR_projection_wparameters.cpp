//DomeProjection.m
// Stephan Thiberge 02/08/2018

// Creating correctly warped images given a particular projector, mirror, 
// and dome arrangement requires finding the point on the projector frustum 
// for any point on the dome. The problem is three-dimensional but can be 
// turned into a simpler two dimensional problem by firstly translating the 
// geometry so the spherical mirror is at the origin and then rotating the 
// geometry so that the point on the mirror, dome, and projector lies in a 
// single plane.
//  The projector is located at P1, the mirror is of radius r, and the 
// position on the dome is P2. The path length from the projector to the 
// mirror is L1, the path length from the dome to the mirror is L2.
// Fermat’s principle states that light travels by the shortest route, so 
// the reflection point on the mirror can be found by minimising the total 
// light path length from the projector to the position on the dome, namely 
// minimising (L1^2 + L2^2)^1/2
// It is quite simple in the case of a spherical mirror: the line at 
// mid-angle between the vectors OP1 and OP2 and its intersection with the
// surface of the mirror defines the reflection point.

// IT IS IMPORTANT TO KEEP THE ANIMALS EYES (later refered as "animal" or 
// "mouse" AT HEIGHT ZERO. In the world the initial conditions should be 
// set for z=0; The floor is then in the negative z values (e.g. -2, if we 
// assume units are cm and animal is mouse)

#include "mex.h"
#include <cmath>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  
const double pi = 3.1415926;

const double tanElevMax=std::abs(std::tan(45*pi/180)); //max visible elevation 45
const double tanElevMin=std::abs(std::tan(45*pi/180)); //min visible elevation -30
const double tanElevMinAtBack=std::abs(std::tan(0*pi/180)); //min visible elevation -30
const double tanAzimMax=std::abs(std::tan(125*pi/180)); //max visible azimuth 125
//const double ProjectorAspectRatio = 1024.0/768.0; 

//Spherical screen radius and coordinates relative to the animal head/eyes
// s is center of spherical dome, 
// m is the mouse eyes,
// O is center of spherical mirror
//units below are inches and degrees

double *params = mxGetDoubles(prhs[1]);
const double Rs= params[0];
//Screen's center location relative to the animal
//const double xsm=1.375; //1.25; //between 1.5 and 2 TUNED to adjust horizon line in all directions
const double xsm = params[1];
//const double ysm=0;
const double ysm =params[2];
//const double zsm=12/25.4; //12mm
const double zsm = params[3];
//Mirror position measurement is facilitated knowing that the center of 
// spherical mirror is (43.8-24.2=)19.6mm (0.77in) behind the back surface.
//const double xOm=5.062; //5.361; 
const double xOm = params[4];
//const double yOm=0;   // if not 0, update to the code below is required
const double yOm = params[5];
//const double zOm=-6.03; //-6.349;
const double zOm = params[6];
//radius of the spherical mirror (Silver coated lens LA1740-Thorlabs)
const double r   = params[7];
//projector position P1 relative to the mirror center O
//const double xP1o=11.4; //11.4
const double xP1o = params[8];
//const double yP1o=0;  // if not 0, update to the code below is required
const double yP1o = params[9];
//const double zP1o=-1.5; //-1.15  -1.4; //between -0.5 and -0.75 ****
const double zP1o = params[10];

const double hrescaling = params[11];
const double hshift     = params[12];

const double vrescaling = params[13];
const double vshift     = params[14];


//some usefull constants values
const double c=xsm*xsm + ysm*ysm + zsm*zsm - Rs*Rs; //
const double aab=std::sqrt(xP1o*xP1o+zP1o*zP1o);
//psi is the angle between the horizontal Ox
// and the axis projector-mirror (OP1)
const double sinpsi= zP1o/aab;
const double cospsi= xP1o/aab;
const double xP1opsi=cospsi*xP1o+sinpsi*zP1o; //this is always aab
const double yP1opsi=yP1o; //this is always 0
const double zP1opsi=-sinpsi*xP1o+cospsi*zP1o; //this is always 0

// //1------figuring out the amplification and translation of the projection system
// //for the estimation of the hardware parameters given above
// 
// //We adjust the position of two objects in virmen such that they end on two
// // physical landmarks position: e.g right in front of the animal, and at 
// // 90deg.
// // We note these Virmen object coordinates, and input them in a .m file 
// // containg the same code as below was written: 
// // SphericalDome_CalibrationCalculation.m
// // We not now the coordinates Coord3New of these two points. 
// // As long as the projector/screen/mirror are not moved, these are the 
// // values that should be output in order to display properly the landmark
// // positions.
// // We have adjusted the Virmen object such that
// //Point 1 is (0,0) displayed right in front of the animal, at the height of the eyes.
// //Point 2 is located at angles (90, 26.56), 
// //    that's on the right side of the animal at a height 
// //    equal to half the horizontal distance from the animal (tan=0.5)
// const double Coord3New1P1=-0.0275;
// const double Coord3New2P1=-0.0453; 
// const double Coord3New1P2=0.4215;
// const double Coord3New2P2=0.1106;

// 
// //The values sinalpha, cosalpha, sinphi for the 2 directions 
// //(0,0) and (90, 26.56) are determined in the m file.
// //With the hardware configuration distances  defined above gives
// 
// const double coord30_Pt1=0;
// const double coord31_Pt1=10000;   //0deg in front of animal
// const double coord32_Pt1=0;
// 
// const double coord30_Pt2=100;  //90 deg of animal,26.56deg up
// const double coord31_Pt2=0;
// const double coord32_Pt2=50;
// 
// const double a_Pt1= std::pow(coord31_Pt1,2)+  std::pow(coord30_Pt1,2)+  std::pow(coord32_Pt1,2);
// const double b_Pt1= -2*(coord31_Pt1*xsm+coord30_Pt1*ysm+coord32_Pt1*zsm);
// const double t_Pt1=(-b_Pt1+std::sqrt(b_Pt1*b_Pt1-4*a_Pt1*c))/(2*a_Pt1) ;
// const double xP2o_Pt1=coord31_Pt1*t_Pt1-xOm;
// const double yP2o_Pt1=coord30_Pt1*t_Pt1-yOm;
// const double zP2o_Pt1=coord32_Pt1*t_Pt1-zOm;
// const double xP2opsi_Pt1=cospsi*xP2o_Pt1+sinpsi*zP2o_Pt1;
// const double yP2opsi_Pt1=yP2o_Pt1;
// const double zP2opsi_Pt1=-sinpsi*xP2o_Pt1+cospsi*zP2o_Pt1;
// const double aac_Pt1=std::sqrt(zP2opsi_Pt1*zP2opsi_Pt1+yP2opsi_Pt1*yP2opsi_Pt1);
// 
// const double sinalpha_Pt1=yP2opsi_Pt1/aac_Pt1;
// const double cosalpha_Pt1=zP2opsi_Pt1/aac_Pt1;
// 
// const double P2x_Pt1=xP2opsi_Pt1;
// const double P2y_Pt1=cosalpha_Pt1*yP2opsi_Pt1-sinalpha_Pt1*zP2opsi_Pt1;
// const double P2z_Pt1=sinalpha_Pt1*yP2opsi_Pt1+ cosalpha_Pt1*zP2opsi_Pt1;
// const double P1x_Pt1=xP1opsi;
// const double P1y_Pt1=cosalpha_Pt1*yP1opsi-sinalpha_Pt1*zP1opsi;
// const double P1z_Pt1=sinalpha_Pt1*yP1opsi+ cosalpha_Pt1*zP1opsi;
// const double P1norm_Pt1=std::sqrt(P1x_Pt1*P1x_Pt1+P1y_Pt1*P1y_Pt1+P1z_Pt1*P1z_Pt1);
// const double P2norm_Pt1=std::sqrt(P2x_Pt1*P2x_Pt1+P2y_Pt1*P2y_Pt1+P2z_Pt1*P2z_Pt1);
// const double P3x_Pt1=P1x_Pt1/P1norm_Pt1+P2x_Pt1/P2norm_Pt1;
// const double P3y_Pt1=P1y_Pt1/P1norm_Pt1+P2y_Pt1/P2norm_Pt1;
// const double P3z_Pt1=P1z_Pt1/P1norm_Pt1+P2z_Pt1/P2norm_Pt1;
// const double P3norm_Pt1=std::sqrt(P3x_Pt1*P3x_Pt1+P3y_Pt1*P3y_Pt1+P3z_Pt1*P3z_Pt1);
// const double YY_Pt1=std::sqrt(std::pow((P1y_Pt1*P3z_Pt1 - P1z_Pt1*P3y_Pt1),2)+std::pow((P1z_Pt1*P3x_Pt1 - P1x_Pt1*P3z_Pt1),2)+ std::pow((P1x_Pt1*P3y_Pt1 - P1y_Pt1*P3x_Pt1),2));
// const double XX_Pt1=(P1x_Pt1*P3x_Pt1 + P1y_Pt1*P3y_Pt1 + P1z_Pt1*P3z_Pt1);
// const double sintheta_Pt1=YY_Pt1/(P1norm_Pt1*P3norm_Pt1);
// const double costheta_Pt1=XX_Pt1/(P1norm_Pt1*P3norm_Pt1);
// 
// const double sinphi1=r*sintheta_Pt1/std::sqrt(std::pow(r*sintheta_Pt1,2)+std::pow(P1x_Pt1-r*costheta_Pt1,2));
// 
// const double a_Pt2= std::pow(coord31_Pt2,2)+  std::pow(coord30_Pt2,2)+  std::pow(coord32_Pt2,2);
// const double b_Pt2= -2*(coord31_Pt2*xsm+coord30_Pt2*ysm+coord32_Pt2*zsm);
// const double t_Pt2=(-b_Pt2+std::sqrt(b_Pt2*b_Pt2-4*a_Pt2*c))/(2*a_Pt2) ;
// const double xP2o_Pt2=coord31_Pt2*t_Pt2-xOm;
// const double yP2o_Pt2=coord30_Pt2*t_Pt2-yOm;
// const double zP2o_Pt2=coord32_Pt2*t_Pt2-zOm;
// const double xP2opsi_Pt2=cospsi*xP2o_Pt2+sinpsi*zP2o_Pt2;
// const double yP2opsi_Pt2=yP2o_Pt2;
// const double zP2opsi_Pt2=-sinpsi*xP2o_Pt2+cospsi*zP2o_Pt2;
// const double aac_Pt2=std::sqrt(zP2opsi_Pt2*zP2opsi_Pt2+yP2opsi_Pt2*yP2opsi_Pt2);
// 
// const double sinalpha_Pt2=yP2opsi_Pt2/aac_Pt2;
// const double cosalpha_Pt2=zP2opsi_Pt2/aac_Pt2;
// 
// const double P2x_Pt2=xP2opsi_Pt2;
// const double P2y_Pt2=cosalpha_Pt2*yP2opsi_Pt2-sinalpha_Pt2*zP2opsi_Pt2;
// const double P2z_Pt2=sinalpha_Pt2*yP2opsi_Pt2+ cosalpha_Pt2*zP2opsi_Pt2;
// const double P1x_Pt2=xP1opsi;
// const double P1y_Pt2=cosalpha_Pt2*yP1opsi-sinalpha_Pt2*zP1opsi;
// const double P1z_Pt2=sinalpha_Pt2*yP1opsi+ cosalpha_Pt2*zP1opsi;
// const double P1norm_Pt2=std::sqrt(P1x_Pt2*P1x_Pt2+P1y_Pt2*P1y_Pt2+P1z_Pt2*P1z_Pt2);
// const double P2norm_Pt2=std::sqrt(P2x_Pt2*P2x_Pt2+P2y_Pt2*P2y_Pt2+P2z_Pt2*P2z_Pt2);
// const double P3x_Pt2=P1x_Pt2/P1norm_Pt2+P2x_Pt2/P2norm_Pt2;
// const double P3y_Pt2=P1y_Pt2/P1norm_Pt2+P2y_Pt2/P2norm_Pt2;
// const double P3z_Pt2=P1z_Pt2/P1norm_Pt2+P2z_Pt2/P2norm_Pt2;
// const double P3norm_Pt2=std::sqrt(P3x_Pt2*P3x_Pt2+P3y_Pt2*P3y_Pt2+P3z_Pt2*P3z_Pt2);
// const double YY_Pt2=std::sqrt(std::pow((P1y_Pt2*P3z_Pt2 - P1z_Pt2*P3y_Pt2),2)+std::pow((P1z_Pt2*P3x_Pt2 - P1x_Pt2*P3z_Pt2),2)+ std::pow((P1x_Pt2*P3y_Pt2 - P1y_Pt2*P3x_Pt2),2));
// const double XX_Pt2=(P1x_Pt2*P3x_Pt2 + P1y_Pt2*P3y_Pt2 + P1z_Pt2*P3z_Pt2);
// const double sintheta_Pt2=YY_Pt2/(P1norm_Pt2*P3norm_Pt2);
// const double costheta_Pt2=XX_Pt2/(P1norm_Pt2*P3norm_Pt2);
// 
// const double sinphi2=r*sintheta_Pt2/std::sqrt(std::pow(r*sintheta_Pt2,2)+std::pow(P1x_Pt2-r*costheta_Pt2,2));
// 
// const double sinalpha2=sinalpha_Pt2;
// const double cosalpha2=cosalpha_Pt2;
// const double sinalpha1=sinalpha_Pt1;
// const double cosalpha1=cosalpha_Pt1;
// 
// //Coord3New1P1=A*sinphi1sinalpha1+B;
// //Coord3New2P1=C*sinphi1cosalpha1+D;
// //Coord3New1P2=A*sinphi2sinalpha2+B;
// //Coord3New2P2=C*sinphi2cosalpha2+D;
// 
// // A=(Coord3New1P1-Coord3New1P2)/(sinphi1*sinalpha1-sinphi2*sinalpha2);
// // B= Coord3New1P1 - A*sinphi1sinalpha1 ;
// // C=(Coord3New2P1-Coord3New2P2)/(sinphi1*cosalpha1-sinphi2*cosalpha2);
// // D= Coord3New2P1 - C*sinphi1cosalpha1 ;
// const double A=(Coord3New1P1 - Coord3New1P2)/(sinphi1*sinalpha1-sinphi2*sinalpha2);
// const double B= Coord3New1P1 - A*sinphi1*sinalpha1 ;
// const double C=(Coord3New2P1 - Coord3New2P2)/(sinphi1*cosalpha1-sinphi2*cosalpha2);
// const double D= Coord3New2P1 - C*sinphi1*cosalpha1 ;





//2------begining of calculation of vertex coordinates

mwSize ncols = mxGetN(prhs[0]);
plhs[0] = mxCreateDoubleMatrix(3,ncols,mxREAL);

double *coord3new = mxGetPr(plhs[0]);
double *coord3    = mxGetPr(prhs[0]);



for ( int index = 0; index < ncols; index++ ) {

  
//  1- 
// For a vertex V of coordinates (x,y,z) in the coordinates system in which
// the animal is at the origin, what are the coordinates of the projected point 
// P2 on the sphere (intersection point P2 between the screen and the line 
// MV) 
// 
// In the coord where M is the origin, the line MV expressed in a parametic form is
// x=xVm*t; y=yVm*t; z=zVm*t;
// and the sphere equation is
// (x-xsm)^2+(y-ysm)^2+(z-zsm)^2=Rs^2;
// Substitution leads to: 
// at^2+bt+c=0
// %where a, b and c are defined as:
    const double a=std::pow(coord3[3*index+1],2)+
      std::pow(coord3[3*index+0],2)+
      std::pow(coord3[3*index+2],2);
    const double b=-2*(coord3[3*index+1]*xsm+coord3[3*index]*ysm+coord3[3*index+2]*zsm);
// c was defined above
//  The two solutions for t are:
    const double t1=(-b+std::sqrt(b*b-4*a*c))/(2*a) ;
    const double t2=(-b-std::sqrt(b*b-4*a*c))/(2*a) ;
//  going from M to V, the parameter t should increase in value from 0 to tsol, 
//  the solution is therefore the positive one (...what??)
    double t = 0;
    if(t1>=0){t=t1;} //it seems it is always t1(...true??)
    if(t2>0) {t=t2;}


//  reinjecting in the original parametric equation, the Line MV intercepts 
//  the spherical projection screen at P2:
//      xP2m=xVm*t; yP2m=yVm*t; zP2m=zVm*t; 
//  2-
//  The point P2 in the coord system where the spherical mirror center is 
//  the origin is: xP2o=xP2m-xOo; yP2o=yP2m-yOm; zP2o=zP2m-zOm;
    const double xP2o=coord3[3*index+1]*t-xOm;
    const double yP2o=coord3[3*index+0]*t-yOm;
    const double zP2o=coord3[3*index+2]*t-zOm;

//  2bis-
//  If P1 is not exactly on the horizontal line crossing the center O, what
//  is the angle psi between the line Ox and the line OP1?
//     aab=(xP1o^2+zP1o^2)^(1/2); sinpsi= zP1o/aab; cospsi= xP1o/aab;
//  2ter-
//  What are the coordinates of P2 in the psi-rotated coordinates system 
//  centered on O?
//  Rot_Oy=[cospsi 0 sinpsi; 0 1 0; -sinpsi 0 cospsi];
//  P2xyz=Rot_Oy*[xP2o; yP2o; zP2o];
//  
//  xP2opsi=P2xyz(1);  yP2opsi=P2xyz(2);  zP2opsi=P2xyz(3); 

    const double xP2opsi=cospsi*xP2o+sinpsi*zP2o;
    const double yP2opsi=yP2o;
    const double zP2opsi=-sinpsi*xP2o+cospsi*zP2o;
// % 2quart-
// % what is the angle alpha between the plan OP1P2 and the plan Ox'z'?
// % this is equivalent to asking the angle between the vectors OP2 and Oz'
    const double aac=sqrt(zP2opsi*zP2opsi+yP2opsi*yP2opsi);
    const double sinalpha=yP2opsi/aac;
    const double cosalpha=zP2opsi/aac;
// % 3-
// % What are the coordinates of P2 in the alpha-rotated coordinates system 
// % centered on O?
// % Rot_OP1axis=[1 0 0; 0 cosalpha -sinalpha; 0 sinalpha cosalpha];
// % P2xyz=Rot_OP1axis*[xP2opsi yP2opsi zP2opsi]';
// % P2x=P2xyz(1) ; P2y=P2xyz(2); P2z=P2xyz(3);
    const double P2x=xP2opsi;
    const double P2y=cosalpha*yP2opsi-sinalpha*zP2opsi; //this is always 0
    const double P2z=sinalpha*yP2opsi+ cosalpha*zP2opsi; //this is always aac
// % Because P1 is not on the horizontal line crossing the center O (but 
// % slightly below), P1 coordinates are changing when we rotate the 
// % referential by psi and alpha:
// % P1opsi=Rot_Oy*[xP1o yP1o zP1o]';
// % P1xyz=Rot_OP1axis*[P1opsi(1) P1opsi(2) P1opsi(3)]';
// % P1x=P1xyz(1); P1y=P1xyz(2); P1z=P1xyz(3);
// xP1opsi=cospsi*xP1o+sinpsi*zP1o; yP1opsi=yP1o;zP1opsi=-sinpsi*xP1o+cospsi*zP1o;
    const double P1x=xP1opsi;
    const double P1y=cosalpha*yP1opsi-sinalpha*zP1opsi; //this is always 0
    const double P1z=sinalpha*yP1opsi+ cosalpha*zP1opsi; //this is always 0
// % 4- 
// % What is the associated theta (elevation in rotated ref) that minimizes 
// % the optical path length? 
// % It's equal to half the angle between the vectors OP1 and OP2.
// %theta =(1/2)* atan2d(norm(cross([P1x, P1y, P1z],[P2x, P2y, P2z])), dot([P1x, P1y, P1z],[P2x, P2y, P2z]));
// % xprod = [ P1y*P2z - P1z*P2y     ...
// %         , P1z*P2x - P1x*P2z     ...
// %         , P1x*P2y - P1y*P2x     ...
// %         ];
// % theta =(1/2)* atan2d(sqrt((P1y*P2z - P1z*P2y)^2+(P1z*P2x - P1x*P2z)^2+(P1x*P2y - P1y*P2x)^2), P1x*P2x + P1y*P2y + P1z*P2z);
// %  sintheta=sind(theta);
// %  costheta=cosd(theta); 
    const double P1norm=std::sqrt(P1x*P1x+P1y*P1y+P1z*P1z);
    const double P2norm=std::sqrt(P2x*P2x+P2y*P2y+P2z*P2z);
    const double P3x=P1x/P1norm+P2x/P2norm;
    const double P3y=P1y/P1norm+P2y/P2norm;  //this is always 0
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

//  4bis-
// % what is the associated angle of the ray leaving the projector?
// %phi=atand((r*sintheta)/(P1x-r*costheta));
    const double sinphi=r*sintheta/std::sqrt(std::pow(r*sintheta,2)+std::pow(P1x-r*costheta,2));

//  5- 
// % Finally what are the {xm,ym} coordinates of the point on the monitor 
// % screen associated with the ray leaving the projector with the angles 
// % alpha and phi ?
// % phi defines a circle in the projector image plane, and alpha a line. 
// % The intersection of the line and the circle defines two points, one that
// % is imaged on the spherical screen, one that is located outside the region
// % being projected. (For now, we place the pixel(0,0) at the center of the 
// % projector)
    
    

  //coord3new[3*index]=   1.1*5.5122*(sinphi*sinalpha-0.019);
  //coord3new[3*index+1]= 5.5122*(sinphi*cosalpha-0.0931); 

    //0.0931*5.5122=0.513186
    
    //For the calibration, the fabricated tool( 2axis galvanometer mounted
    //laser pointer is used, making sure the microscope is vertical and 
    //placed above the animal location, as fixed by the ball and head plate
    //mount positions.
    
    //Projector position, orientation, and others factors(???) impose a 
    //shift and dilatation of the image. Dilatation along the horizontal 
    //and vertical may be different.
    
    //The vertical shift in the coordinates(-0.513186) was determined 
    //empirically to place the horizon at the level of the animal eyes.
    //Changing the projector angle is another way (difficult) to correct
    //for that.
    //It is easy on the other hand to translate sideway the projector, 
    //hence the close to 0 horizontal shift applied here.
    
    //The horizontal magnification was determined by increasing the value
    //until an object that should be located at 90 of the animal reaches
    //that position.
    //The vertical magnification was determiend in the same way with a 
    //a wall or object of known elevation angle.
    

//   //horizontal coordinate shift and rescaling. 
//     coord3new[3*index]= A*sinphi*sinalpha + B;
//   //vertical coordinate shift and rescaling. 
//     coord3new[3*index+1]= C*sinphi*cosalpha + D; 
    
//  //horizontal coordinate shift and rescaling. 
//    const double X= 5.85*sinphi*sinalpha - 0.00000; //0.008564;
//  //vertical coordinate shift and rescaling. 
 //   const double Z= 5.85*sinphi*cosalpha -1.0361; //-1.0331   -1.041 ****
    
 //   const double theta=pi*0.8/180;
 //   coord3new[3*index]=X*std::cos(theta)-Z*std::sin(theta);
//    coord3new[3*index+1]=X*std::sin(theta)+Z*std::cos(theta);
    
      //horizontal coordinate shift and rescaling. 
    const double theta=pi*0.8/180;
    //const double X= 5.85*sinphi*sinalpha;  //0.008564;
  //vertical coordinate shift and rescaling. 
    //const double Z= 5.85*sinphi*cosalpha; //-1.0331   -1.041 ****
    
    coord3new[3*index]  =hrescaling*sinphi*sinalpha + hshift;
    coord3new[3*index+1]=vrescaling*sinphi*cosalpha + vshift;
    
  // check if point should be visible 
    coord3new[3*index+2]=1;
    if( std::sqrt ( std::pow(coord3[3*index+2],2)
                  / ( std::pow(coord3[3*index],2)
                    + std::pow(coord3[3*index+1],2)
                    ) ) > tanElevMax 
       || ( coord3[3*index+2] < 0
         && std::sqrt ( std::pow(coord3[3*index+2],2)
                / ( std::pow(coord3[3*index],2)
               + std::pow(coord3[3*index+1],2)
                 ) ) > tanElevMin )

       || ( coord3[3*index+1] < 0
            && std::abs(coord3[3*index]/coord3[3*index+1])<tanAzimMax)
      )
    {
      coord3new[3*index+2]=0;
    }
    
//     if( coord3[3*index+1] < 0 && coord3[3*index+2] < 0 )
// //           //coord3new[3*index+1]=-1;
//     {      if (coord3new[3*index]<0){coord3new[3*index]=-1;}
//            if (coord3new[3*index]>0){coord3new[3*index]=1;}
//     }
      

    

}
}
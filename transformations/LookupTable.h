#ifndef LOOKUPTABLE_H
#define LOOKUPTABLE_H

#include <vector>


class LookupTable
{
protected:
  std::vector<double>         sampleX;
  std::vector<double>         sampleY;
  const int                   last;
  const double                dx;
  double (*functor)(double);

public:
  LookupTable(double xMin, double xMax, int nBins, double (*functor)(double))
    : sampleX(nBins)
    , sampleY(nBins)
    , last   (nBins - 1)
    , dx     ((xMax - xMin) / nBins)
    , functor(functor)
  {
    sampleX[0]                = xMin;
    sampleY[0]                = functor(xMin);
    for (int iBin = 1; iBin < nBins; ++iBin) {
      sampleX[iBin]           = sampleX[iBin-1] + dx;
      sampleY[iBin]           = functor(sampleX[iBin]);
    }
  }

  double operator()(double x) const {
    if (x <= sampleX[0])      return sampleY[0];
    if (x >= sampleX[last])   return sampleY[last];
    
    const double              xBin    = (x - sampleX[0]) / dx;
    const int                 iBin    = std::floor(xBin);
    return    sampleY[iBin] 
            + (sampleY[iBin+1] - sampleY[iBin])
            * (xBin - iBin)
            ;
  }
};

#endif //LOOKUPTABLE_H

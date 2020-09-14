#ifndef CPOINTER_H
#define CPOINTER_H

#include <cstdint>
#include <mex.h>

template<typename T>
T* matToCPointer(const mxArray* mat)
{
  const uint64_t*   raw       = (uint64_t*) mxGetData(mat);
  std::uintptr_t    pointer   = raw[0];
  return reinterpret_cast<T*>(pointer);
}

template<typename T>
uint64_t cPointerToUint64(T* pointer)
{
  std::uintptr_t    address   = reinterpret_cast<std::uintptr_t>(pointer);
  return address;
}

#endif //CPOINTER_H

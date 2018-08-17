#ifndef _G711_H_
#define _G711_H_

long g711a_decode(char *pSrc, long nSrcSize, char *pDst);
long g711a_encode(char *pSrc, long nSrcSize, char *pDst);

long g711u_decode(char *pSrc, long nSrcSize, char *pDst);
long g711u_encode(char *pSrc, long nSrcSize, char *pDst);

#endif//_G711_H_
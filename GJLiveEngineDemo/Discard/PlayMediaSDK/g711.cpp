#include "g711.h"
#include <stdio.h>
#include <string.h>

short g711a_decode_unit(unsigned char alaw)
{
    alaw ^= 0xD5;
    int sign = alaw & 0x80;
    int exponent = (alaw & 0x70) >> 4;
    int data = alaw & 0x0f;
    data <<= 4;
    data += 8;
    if (exponent != 0)
        data += 0x100;
    if (exponent > 1)
        data <<= (exponent - 1);

    return (short)(sign == 0 ? data : -data);
}
long g711a_decode(char *pSrc, long nSrcSize, char *pDst)
{
    short *out_data = (short*)pDst;
    for(int i = 0; i < nSrcSize ; ++i)
    {
        out_data[i] = g711a_decode_unit(pSrc[i]);
    }
    return nSrcSize * 2;
}

unsigned char g711a_encode_unit(short pcm)
{
    int sign = (pcm & 0x8000) >> 8;
    if (sign != 0)
        pcm = -pcm;
    #define MAX (32635)
    if (pcm > MAX) pcm = MAX;
    int exponent = 7;
    int expMask;
    for (expMask = 0x4000; (pcm & expMask) == 0 
        && exponent>0; exponent--, expMask >>= 1) { }
    int mantissa = (pcm >> ((exponent == 0) ? 4 : (exponent + 3))) & 0x0f;
    unsigned char alaw = (unsigned char)(sign | exponent << 4 | mantissa);
    return (unsigned char)(alaw^0xD5);
}

long g711a_encode(char *pSrc, long nSrcSize, char *pDst)
{
    short *buffer = (short*)pSrc;
    for(int i = 0; i < nSrcSize / 2; ++i)
    {
        pDst[i] = g711a_encode_unit(buffer[i]);
    }
    return nSrcSize / 2;
} 

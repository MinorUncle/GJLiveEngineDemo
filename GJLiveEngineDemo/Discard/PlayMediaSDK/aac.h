#ifndef _AAC_H_
#define _AAC_H_

long aac_decode_create();
long aac_decode(long handle, char *pSrc, long nSrcSize, char *pDst, long *sample_per_sec, long *bits_per_sample, long *channels);
long aac_decode_destroy(long handle);

long aac_encode_create(long sample_per_sec, long bits_per_sample, long channels);
long aac_encode(long handle, char *pSrc, long nSrcSize, char *pDst);
long aac_encode_destroy(long handle);

#endif//_AAC_H_
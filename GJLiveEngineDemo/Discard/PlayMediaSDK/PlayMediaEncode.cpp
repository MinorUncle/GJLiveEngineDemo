#include "PlayMediaSDK.h"
#include "aac.h"
#include "g711.h"
#include <stdio.h>
#include <string.h>

struct ENCODE_INFO_S
{
    long handle;
    long type;

    ENCODE_INFO_S()
    {
        memset(this, 0, sizeof(ENCODE_INFO_S));
    }
};

PLAY_MEDIA_API long PlayMedia_CreateAudioEncode(long nSamplesPerSec, long nBitsPerSample, long nChannels, long nCodecId)
{
    ENCODE_INFO_S *p = new ENCODE_INFO_S;
    p->type = nCodecId;
    switch (p->type)
    {
    case DECODEC_TYPE_AAC:
        p->handle = aac_encode_create(nSamplesPerSec, nBitsPerSample, nChannels);
        break;
    case DECODEC_TYPE_G711A:
        break;
    case DECODEC_TYPE_G711U:
        break;
    case DECODEC_TYPE_G711EX:
        break;
    }
    return (long)p;
}

PLAY_MEDIA_API long PlayMedia_EncodeAudio(long handle, unsigned char *pSrc, long nSrcSize, unsigned char *pDst, long *nDstSize)
{
    ENCODE_INFO_S *p = (ENCODE_INFO_S*)handle;
    switch (p->type)
    {
    case DECODEC_TYPE_AAC:
        *nDstSize = aac_encode(p->handle, (char *)pSrc, nSrcSize, (char *)pDst);
        break;
    case DECODEC_TYPE_G711A:
        break;
    case DECODEC_TYPE_G711U:
        break;
    case DECODEC_TYPE_G711EX:
        *nDstSize = g711a_encode((char *)pSrc, nSrcSize, (char *)pDst);
        break;
    }
    return 0;
}

PLAY_MEDIA_API long PlayMedia_DestroyAudioEncode(long handle)
{
    ENCODE_INFO_S *p = (ENCODE_INFO_S*)handle;
    switch (p->type)
    {
    case DECODEC_TYPE_AAC:
        aac_encode_destroy(p->handle);
        break;
    case DECODEC_TYPE_G711A:
        break;
    case DECODEC_TYPE_G711U:
        break;
    }
    delete p;
    return 0;
}

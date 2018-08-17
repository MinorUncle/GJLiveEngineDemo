#ifndef _PLAY_MEDIA_SDK_H_
#define _PLAY_MEDIA_SDK_H_

#ifdef WIN32
#ifdef PLAYMEDIASDK_EXPORTS
#define PLAY_MEDIA_API extern "C"  __declspec(dllexport) 
#else 
#define PLAY_MEDIA_API extern "C"  __declspec(dllimport) 
#endif
#else
#define PLAY_MEDIA_API
#endif


#define ERR_SUCCESS             0
#define ERR_UNKNOWN             -1

enum DECODEC_TYPE_ENUM
{
    // ”∆µ
    DECODEC_TYPE_H264               = 0x11,

    //“Ù∆µ
    DECODEC_TYPE_AAC                = 0x41,
    DECODEC_TYPE_G711A              = 0x42,
    DECODEC_TYPE_G711U              = 0x43,
    DECODEC_TYPE_PCM                = 0x44,
    DECODEC_TYPE_G711EX             = 0x45,

    DECODEC_TYPE_UNKNOWN            = 0xFF,
};

enum DRAW_ASPECT_RATIO{
    RATIO_DEFAULT  = 0,
    RATIO_FULL     = 1,
    RATIO_4_3      = 2,
    RATIO_16_9     = 3,
    RATIO_NULL,
};

// ”∆µΩ‚¬Î
PLAY_MEDIA_API long PlayMedia_CreateVideoDecodec(long nCodecId);
PLAY_MEDIA_API long PlayMedia_DestroyVideoDecodec(long hCodec);
PLAY_MEDIA_API long PlayMedia_DecodecVideo(long hCodec, unsigned char *pSrc, long nSrcSize, unsigned char *pDst, long *nDstSize, long *type);
PLAY_MEDIA_API long PlayMedia_GetPictureSize(long hCodec, long *nWidth, long *nHeight);

// ”∆µ≤•∑≈
#ifdef WIN32

PLAY_MEDIA_API long  PlayMedia_OpenFile(long hCodec,char pFileName);
PLAY_MEDIA_API long  PlayMedia_CloseFile(long hCodec);

PLAY_MEDIA_API long PlayMedia_InitDDraw(long hWnd, long nWidth, long nHeight);
PLAY_MEDIA_API long PlayMedia_DestroyDDraw(long hDraw);
PLAY_MEDIA_API long PlayMedia_DDraw(long hDraw, unsigned char *pYuv420, long nWidth, long nHeight);
PLAY_MEDIA_API long PlayMedia_SetAspectRatio(long hDraw, long ratio);
#endif

//“Ù∆µ≤…ºØ
#ifdef WIN32
PLAY_MEDIA_API long PlayMedia_StartCaptureAudio(long nSamplesPerSec, long nBitsPerSample, long nChannels, void(*DataCallback)(long context, char *buf, long size), long context);
PLAY_MEDIA_API long PlayMedia_StopCaptureAudio(long handle);
#endif

//“Ù∆µ±‡¬Î
PLAY_MEDIA_API long PlayMedia_CreateAudioEncode(long nSamplesPerSec, long nBitsPerSample, long nChannels, long nCodecId);
PLAY_MEDIA_API long PlayMedia_EncodeAudio(long handle, unsigned char *pSrc, long nSrcSize, unsigned char *pDst, long *nDstSize);
PLAY_MEDIA_API long PlayMedia_DestroyAudioEncode(long handle);

//“Ù∆µΩ‚¬Î
PLAY_MEDIA_API long PlayMedia_CreateAudioDecodec(long nCodecId);
PLAY_MEDIA_API long PlayMedia_DestroyAudioDecodec(long hCodec);
PLAY_MEDIA_API long PlayMedia_DecodecAudio(long hCodec, unsigned char *pSrc, long nSrcSize, unsigned char *pDst, long *nDstSize, long *nSamplesPerSec, long *nBitsPerSample, long *nChannels);

//“Ù∆µ≤•∑≈
PLAY_MEDIA_API long PlayMedia_InitAudioPlay(long hwnd, long nSamplesPerSec, long nChannel, long nBitsPerSample);
PLAY_MEDIA_API long PlayMedia_DestroyAudioPlay(long hAudio);
PLAY_MEDIA_API long PlayMedia_SetAudioVolume(long hAudio, long nVolume);
PLAY_MEDIA_API long PlayMedia_GetAudioVolume(long hAudio);
PLAY_MEDIA_API long PlayMedia_AudioPlay(long hAudio, unsigned char *pSrc, long nSrcSize);

//¬ºœÒ
PLAY_MEDIA_API long PlayMedia_OpenOutputFile(char *pFileName, long nWidth, long nHeight, long nBitRate, long nFrameRate);
PLAY_MEDIA_API long PlayMedia_CloseFile(long hFile);
PLAY_MEDIA_API long PlayMedia_WriteFile(long hFile, char *pData, long nSize, long nFrameType);//nFrameType,0:I,1,P,2:B,3:AUDIO
PLAY_MEDIA_API long PlayMedia_WriteFileWithPts(long hFile, char *pData, long nSize, long nFrameType, unsigned long long nPts);

//±£¥ÊÕº∆¨
PLAY_MEDIA_API long PlayMedia_SaveYUV2File(char *pFileName, char *pData, long nSize, long nWidth, long nHeight);
PLAY_MEDIA_API long PlayMedia_SaveRGB2File(char *pFileName, char *pData, long nSize, long nWidth, long nHeight, long nBitDepth);

//—’…´ø’º‰◊™ªª
PLAY_MEDIA_API long PlayMedia_YUV2RGB24(char *pSrc, long nSrcSize, char *pDst, long *nDstSize, long nWidth, long nHeight);
PLAY_MEDIA_API long PlayMedia_YUV2RGB32(char *pSrc, long nSrcSize, char *pDst, long *nDstSize, long nWidth, long nHeight);


#endif//_PLAY_MEDIA_SDK_H_

#include "PlayMediaSDK.h"
extern "C"
{
#ifndef PASDK
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavutil/avutil.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/opt.h"
#endif
}
#include "g711.h"
#include "aac.h"
#include <stdio.h>
#include <string.h>
#include "audio_ffmpeg.h"

struct AUDIO_DECODEC_INFO_S
{
    long handle;
    long type;
    AUDIO_DECODEC_INFO_S()
    {
        memset(this, 0, sizeof(AUDIO_DECODEC_INFO_S));
    }
};

#ifndef PASDK
struct DECODEC_INFO_S
{
    AVCodecContext *pCodecCtx;
    AVCodec *pCodec;
    AVFrame *pFrame;
    AVFrame *pFrameOut;

    DECODEC_INFO_S()
    {
        memset(this, 0, sizeof(DECODEC_INFO_S));
    }
};

PLAY_MEDIA_API long PlayMedia_CreateVideoDecodec(long nCodecId)
{
    avcodec_register_all();

    AVCodec *pCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!pCodec)
    {
        //printf("find decoder failed\n");
        return ERR_UNKNOWN;
    }

    AVCodecContext *pCodecCtx = avcodec_alloc_context3(pCodec);
    if (!pCodecCtx)
    {
        av_free(pCodec);
        //printf("alloc decoder context failed\n");
        return ERR_UNKNOWN;
    }

    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        av_free(pCodec);
        av_free(pCodecCtx);
        //printf("open codec failed\n");
        return ERR_UNKNOWN;
    }

    AVFrame *pFrame = av_frame_alloc();
    if (!pFrame)
    {
        av_free(pCodec);
        av_free(pCodecCtx);
        //printf("alloc avframe failed\n");
        return ERR_UNKNOWN;
    }

    AVFrame *pFrameOut = av_frame_alloc();
    if (!pFrameOut)
    {
        av_free(pCodec);
        av_free(pCodecCtx);
        av_free(pFrame);
        //printf("alloc avframe failed\n");
        return ERR_UNKNOWN;
    }

    DECODEC_INFO_S *pInfo = new DECODEC_INFO_S;
    pInfo->pCodecCtx = pCodecCtx;
    pInfo->pCodec = pCodec;
    pInfo->pFrame = pFrame;
    pInfo->pFrameOut = pFrameOut;
    return (long)pInfo;
}

PLAY_MEDIA_API long PlayMedia_DestroyVideoDecodec(long hCodec)
{
    DECODEC_INFO_S *pInfo = (DECODEC_INFO_S *)hCodec;
    if (!pInfo)
    {
        return ERR_UNKNOWN;
    }

    if (pInfo->pCodecCtx)
    {
        avcodec_close(pInfo->pCodecCtx);
        av_free(pInfo->pCodecCtx);
        pInfo->pCodecCtx = 0;
    }

    if (pInfo->pCodec)
    {
        pInfo->pCodec = 0;
    }

    if (pInfo->pFrame)
    {
        av_free(pInfo->pFrame);
        pInfo->pFrame = 0;
    }

    if (pInfo->pFrameOut)
    {
        av_free(pInfo->pFrameOut);
        pInfo->pFrame = 0;
    }

    delete pInfo;
    return ERR_SUCCESS;
}

PLAY_MEDIA_API long PlayMedia_DecodecVideo(long hCodec, unsigned char *pSrc, long nSrcSize, unsigned char *pDst, long *nDstSize, long *type)
{
    DECODEC_INFO_S *pInfo = (DECODEC_INFO_S *)hCodec;
    if (!pInfo)
    {
        return ERR_UNKNOWN;
    }

    int bPicture = 0;
    AVPacket packet = {0};
    packet.data = pSrc; 
    packet.size = nSrcSize;
    if (avcodec_decode_video2(pInfo->pCodecCtx, pInfo->pFrame, &bPicture, &packet) < 0)
    {
        return ERR_UNKNOWN;
    }

    if (bPicture)
    {
        AVPixelFormat outFormat = AV_PIX_FMT_YUV420P;
        *nDstSize = pInfo->pFrame->width * pInfo->pFrame->height * 3 / 2;
        avpicture_fill((AVPicture*)pInfo->pFrameOut, (uint8_t*)pDst, outFormat, pInfo->pCodecCtx->width, pInfo->pCodecCtx->height);
        SwsContext *img_convert_ctx = sws_getContext(
            pInfo->pCodecCtx->width, 
            pInfo->pCodecCtx->height, 
            pInfo->pCodecCtx->pix_fmt, 
            pInfo->pCodecCtx->width,
            pInfo->pCodecCtx->height, 
            outFormat, 
            SWS_FAST_BILINEAR, NULL, NULL,NULL);
        if (img_convert_ctx == NULL) 
        {
            return -1;
        }
        int ret = sws_scale(img_convert_ctx, pInfo->pFrame->data, pInfo->pFrame->linesize, 
            0, pInfo->pCodecCtx->height, pInfo->pFrameOut->data, pInfo->pFrameOut->linesize);

        if(img_convert_ctx != NULL)
        {
            sws_freeContext(img_convert_ctx);
            img_convert_ctx = NULL;
        }

        *type = pInfo->pFrame->pict_type;
        return ERR_SUCCESS;
    }
    return ERR_UNKNOWN;
}

PLAY_MEDIA_API long PlayMedia_GetPictureSize(long hCodec, long *nWidth, long *nHeight)
{
    DECODEC_INFO_S *pInfo = (DECODEC_INFO_S *)hCodec;
    if (!pInfo)
    {
        return ERR_UNKNOWN;
    }

    if (pInfo->pFrame->width > 0 && pInfo->pFrame->height > 0)
    {
        *nWidth = pInfo->pFrame->width;
        *nHeight = pInfo->pFrame->height;
        return ERR_SUCCESS;
    }
    return ERR_UNKNOWN;
}
#endif

PLAY_MEDIA_API long PlayMedia_CreateAudioDecodec(long nCodecId)
{
    AUDIO_DECODEC_INFO_S *p = new AUDIO_DECODEC_INFO_S;
    p->type = nCodecId;
    switch (nCodecId)
    {
    case DECODEC_TYPE_AAC:
        {
            p->handle = aac_decode_create();
        }
        break;
    case DECODEC_TYPE_G711A:
        {
            p->handle = ffmpeg_audio_decode_create(nCodecId);
        }
        break;
    case DECODEC_TYPE_G711U:
        break;
    case DECODEC_TYPE_G711EX:
        break;
    }
    return (long)p;
}

PLAY_MEDIA_API long PlayMedia_DestroyAudioDecodec(long hCodec)
{
    AUDIO_DECODEC_INFO_S *p = (AUDIO_DECODEC_INFO_S *)hCodec;
    switch (p->type)
    {
    case DECODEC_TYPE_AAC:
        {
            aac_decode_destroy(p->handle);
        }
        break;
    case DECODEC_TYPE_G711A:
        {
            ffmpeg_audio_decode_destroy(p->handle);
        }
        break;
    case DECODEC_TYPE_G711U:
        break;
    case DECODEC_TYPE_G711EX:
        break;
    }
    delete p;
    return ERR_SUCCESS;
}

PLAY_MEDIA_API long PlayMedia_DecodecAudio(long hCodec, unsigned char *pSrc, long nSrcSize, unsigned char *pDst, long *nDstSize, long *nSamplesPerSec, long *nBitsPerSample, long *nChannels)
{
    AUDIO_DECODEC_INFO_S *p = (AUDIO_DECODEC_INFO_S *)hCodec;
    switch (p->type)
    {
    case DECODEC_TYPE_AAC:
        {
            *nDstSize = aac_decode(p->handle, (char *)pSrc, nSrcSize, (char *)pDst, nSamplesPerSec, nBitsPerSample, nChannels);
        }
        break;
    case DECODEC_TYPE_G711A:
        *nDstSize = ffmpeg_audio_decode(p->handle, (char*)pSrc, nSrcSize, (char*)pDst, nSamplesPerSec, nBitsPerSample, nChannels);
        *nSamplesPerSec = 8000;
        *nBitsPerSample = 16;
        *nChannels = 1;
        break;
    case DECODEC_TYPE_G711U:
        break;
    case DECODEC_TYPE_G711EX:
        *nDstSize = g711a_decode((char*)pSrc, nSrcSize, (char*)pDst);
        *nSamplesPerSec = 8000;
        *nBitsPerSample = 16;
        *nChannels = 1;
        break;
    }

    if (*nDstSize <= 0)
    {
        return ERR_UNKNOWN;
    }
    return ERR_SUCCESS;
}

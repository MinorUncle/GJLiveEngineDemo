#include "aac.h"
#include <stdio.h>
#include <string.h>
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
#include "libavutil/error.h"
#endif
#include "faad/faad.h"
#include "faac/faac.h"
}

#ifndef __WIN64__
#define AUDIO_FAAD  1
#define AUDIO_FAAC  1
#else
#define AUDIO_FAAD  0
#define AUDIO_FAAC  0
#endif


struct AAC_DECODE_INFO
{
#if AUDIO_FAAD
    NeAACDecHandle handle;
    bool b_init;
#else
    AVCodecContext *pCodecCtx;
    AVCodec *pCodec;
    AVFrame *pFrame;
#endif

    AAC_DECODE_INFO()
    {
        memset(this, 0, sizeof(AAC_DECODE_INFO));
    }
};

struct AAC_ENCODE_INFO
{
#if !AUDIO_FAAC
    AVCodecContext *pCodecCtx;
    AVCodec *pCodec;
    AVFrame *pFrame;
#else
    faacEncHandle handle;
    char *buf;
    unsigned long remain_length;
    unsigned long input_size;
#endif

    AAC_ENCODE_INFO()
    {
        memset(this, 0, sizeof(AAC_ENCODE_INFO));
    }
};

long aac_decode_create()
{
#if AUDIO_FAAD
    AAC_DECODE_INFO *p = new AAC_DECODE_INFO;
    p->handle = NeAACDecOpen();
    return (long)p;
#else
    avcodec_register_all();
    AVCodec *pCodec = avcodec_find_decoder(CODEC_ID_AAC);
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

    pCodecCtx->channels = 2;
    pCodecCtx->sample_rate = 16000;
    pCodecCtx->sample_fmt = AV_SAMPLE_FMT_S16;

    pCodecCtx->bits_per_coded_sample = 64000/16;
    pCodecCtx->block_align  = 16*2/8;

    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        av_free(pCodec);
        av_free(pCodecCtx);
        //printf("open codec failed\n");
        return ERR_UNKNOWN;
    }

    AAC_DECODE_INFO *pInfo = new AAC_DECODE_INFO;
    pInfo->pCodecCtx = pCodecCtx;
    pInfo->pCodec = pCodec;
    pInfo->pFrame = avcodec_alloc_frame();
    return (long)pInfo;
#endif
}

#define FRAME_MAX_LEN 1024*5 
#define BUFFER_MAX_LEN 1024*1024

int get_one_ADTS_frame(unsigned char* buffer, size_t buf_size, unsigned char* data ,size_t* data_size)
{
    size_t size = 0;

    if(!buffer || !data || !data_size )
    {
        return -1;
    }

    while(1)
    {
        if(buf_size  < 7 )
        {
            return -1;
        }

        if((buffer[0] == 0xff) && ((buffer[1] & 0xf0) == 0xf0) )
        {
            size |= ((buffer[3] & 0x03) <<11);     //high 2 bit
            size |= buffer[4]<<3;                //middle 8 bit
            size |= ((buffer[5] & 0xe0)>>5);        //low 3bit
            break;
        }
        --buf_size;
        ++buffer;
    }

    if(buf_size < size)
    {
        return -1;
    }

    memcpy(data, buffer, size);
    *data_size = size;

    return 0;
}

long aac_decode(long handle, char *pSrc, long nSrcSize, char *pDst, long *sample_per_sec, long *bits_per_sample, long *channels)
{
    AAC_DECODE_INFO *p = (AAC_DECODE_INFO *)handle;
    long nDstSize = 0;
#if AUDIO_FAAD
    if (!p->b_init)
    {
        unsigned long samples = 0;
        unsigned char channels = 0;
        if (NeAACDecInit((NeAACDecHandle)p->handle, (unsigned char *)pSrc, nSrcSize, &samples, &channels) < 0)
        {
            return -1;
        }
        p->b_init = true;
    }

    static unsigned char frame[FRAME_MAX_LEN];
    size_t size = 0;
    if (get_one_ADTS_frame((unsigned char *)pSrc, nSrcSize, frame, &size))
    {
        return -1;
    }

    NeAACDecFrameInfo frameInfo;
    NeAACDecDecode2((NeAACDecHandle)p->handle, &frameInfo, frame, size, (void **)&pDst, 1024*32);
    if (frameInfo.samples > 0)
    {
        nDstSize = frameInfo.samples * frameInfo.channels;
        *sample_per_sec = frameInfo.samplerate;
        *channels = frameInfo.channels;
        *bits_per_sample = 16;
    }
    else
    {
        return -1;
    }
#else
#endif
    return nDstSize;
}

long aac_decode_destroy(long handle)
{
#if AUDIO_FAAD
    AAC_DECODE_INFO *p = (AAC_DECODE_INFO *)handle;
    NeAACDecClose(p->handle);
    delete p;
#else
    AAC_DECODE_INFO *pInfo = (AAC_DECODE_INFO *)handle;
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

    delete pInfo;
    return ERR_SUCCESS;
#endif
    return 0;
}


long aac_encode_create(long sample_per_sec, long bits_per_sample, long channels)
{
#if AUDIO_FAAC
    unsigned long inputSamples = 0, maxOutputBytes = 0;
    faacEncHandle handle = faacEncOpen(sample_per_sec, channels, &inputSamples, &maxOutputBytes);
    faacEncConfigurationPtr enc_cfg = faacEncGetCurrentConfiguration(handle);
    enc_cfg->inputFormat=FAAC_INPUT_16BIT;
    enc_cfg->mpegVersion = MPEG4;
    enc_cfg->aacObjectType = LOW;
    enc_cfg->allowMidside = 1;
    enc_cfg->useLfe = 0;
    enc_cfg->useTns = 0;
    enc_cfg->bitRate = 8000;
    enc_cfg->quantqual = 100;
    enc_cfg->bandWidth = 0;
    enc_cfg->outputFormat = 1; //ADTS
    faacEncSetConfiguration(handle, enc_cfg);
    AAC_ENCODE_INFO *p = new AAC_ENCODE_INFO;
    p->handle = handle;
    p->input_size = inputSamples * 2;
    p->buf = new char [inputSamples * 2];
    return (long)p;
#else
    av_register_all();
    avcodec_register_all();

    AVCodec *pCodec = avcodec_find_encoder(CODEC_ID_AAC);
    if (!pCodec)
    {
        //printf("find encoder failed\n");
        return ERR_UNKNOWN;
    }

    AVCodecContext *pCodecCtx = avcodec_alloc_context3(pCodec);
    if (!pCodecCtx)
    {
        av_free(pCodec);
        //printf("alloc encoder context failed\n");
        return ERR_UNKNOWN;
    }

    pCodecCtx->bits_per_coded_sample = 2;
    pCodecCtx->bit_rate = sample_per_sec * channels * bits_per_sample;
    pCodecCtx->sample_rate = sample_per_sec;
    pCodecCtx->channels = channels;
    pCodecCtx->sample_fmt = AV_SAMPLE_FMT_S16;

    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        av_free(pCodec);
        av_free(pCodecCtx);
        //printf("open codec failed\n");
        return ERR_UNKNOWN;
    }

    AAC_ENCODE_INFO *pInfo = new AAC_ENCODE_INFO;
    pInfo->pCodecCtx = pCodecCtx;
    pInfo->pCodec = pCodec;
    pInfo->pFrame = avcodec_alloc_frame();

    pInfo->pFrame->nb_samples = pCodecCtx->frame_size;
    pInfo->pFrame->format = pCodecCtx->sample_fmt;
    pInfo->pFrame->channels = pCodecCtx->channels;
    pInfo->pFrame->channel_layout = pCodecCtx->channel_layout;

    return (long)pInfo;
#endif
    return 0;
}

long aac_encode(long handle, char *pSrc, long nSrcSize, char *pDst)
{
#if AUDIO_FAAC
    AAC_ENCODE_INFO *p = (AAC_ENCODE_INFO *)handle;
    long nDstSize = 0;
    if (p->remain_length + nSrcSize >= p->input_size)
    {
        long nPos = 0;
        do 
        {
            if (p->remain_length > 0)
            {
                memcpy(p->buf + p->remain_length, pSrc + nPos, p->input_size - p->remain_length);
                nPos += p->input_size - p->remain_length;
                nDstSize += faacEncEncode(p->handle, (int*)p->buf, p->input_size/2, (unsigned char *)(pDst + nDstSize), 1024*32);
                p->remain_length = 0;
            }
            else
            {
                nDstSize += faacEncEncode(p->handle, (int*)(pSrc + nPos), p->input_size/2, (unsigned char *)(pDst + nDstSize), 1024*32);
                nPos += p->input_size;
            }
        } while (nSrcSize - nPos >= p->input_size);

        if (nPos < nSrcSize)
        {
            memcpy(p->buf, pSrc + nPos, nSrcSize - nPos);
            p->remain_length = nSrcSize - nPos;
        }
    }
    else
    {
        memcpy(p->buf + p->remain_length, pSrc, nSrcSize);
        p->remain_length += nSrcSize;
    }
#else
    AAC_ENCODE_INFO *pInfo = (AAC_ENCODE_INFO *)handle;
    if (!pInfo)
    {
        return ERR_UNKNOWN;
    }

    pInfo->pFrame->linesize[0] = nSrcSize;
    pInfo->pFrame->data[0] = (uint8_t *)pSrc;

    AVPacket packet = {0};
    packet.data = (uint8_t *)pDst;
    packet.size = nSrcSize;

    int got_output = 0;
    int ret = avcodec_encode_audio2(pInfo->pCodecCtx, &packet, pInfo->pFrame, &got_output);
    if (ret < 0) 
    {
        printf("Error encoding audio frame: %d\n", ret);
        return ERR_UNKNOWN;
    }

    long nDstSize = 0;
    if(got_output > 0)
    {
        nDstSize = packet.size;
        av_free_packet(&packet);
    }
#endif
    return nDstSize;
}

long aac_encode_destroy(long handle)
{
#if AUDIO_FAAC
    AAC_ENCODE_INFO *p = (AAC_ENCODE_INFO *)handle;
    faacEncClose(p->handle);
    if (p->buf)
    {
        delete []p->buf;
    }
#else
    AAC_ENCODE_INFO *p = (AAC_ENCODE_INFO *)handle;
    if (!p)
    {
        return ERR_UNKNOWN;
    }

    if (p->pCodecCtx)
    {
        avcodec_close(p->pCodecCtx);
        av_free(p->pCodecCtx);
        p->pCodecCtx = 0;
    }

    if (p->pCodec)
    {
        av_free(p->pCodec);
        p->pCodec = 0;
    }

    if (p->pFrame)
    {
        av_free(p->pFrame);
        p->pFrame = 0;
    }
#endif
    delete p;
    return 0;
}

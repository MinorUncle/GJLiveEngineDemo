#include "aac.h"
#include <stdio.h>
#include <string.h>

extern "C"
{
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavutil/avutil.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/opt.h"
#include "libavutil/error.h"
}

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

long ffmpeg_audio_decode_create(long codecid)
{
    avcodec_register_all();
    AVCodec *pCodec = avcodec_find_decoder(AV_CODEC_ID_PCM_ALAW);
    if (!pCodec)
    {
        //printf("find decoder failed\n");
        return -1;
    }

    AVCodecContext *pCodecCtx = avcodec_alloc_context3(pCodec);
    if (!pCodecCtx)
    {
        av_free(pCodec);
        //printf("alloc decoder context failed\n");
        return -1;
    }

    pCodecCtx->channels = 1;
    pCodecCtx->sample_rate = 8000;
    pCodecCtx->sample_fmt = AV_SAMPLE_FMT_S16;

    pCodecCtx->bits_per_coded_sample = 64000/16;
    pCodecCtx->block_align  = 16*2/8;

    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        av_free(pCodec);
        av_free(pCodecCtx);
        //printf("open codec failed\n");
        return -1;
    }

    DECODEC_INFO_S *pInfo = new DECODEC_INFO_S;
    pInfo->pCodecCtx = pCodecCtx;
    pInfo->pCodec = pCodec;
    pInfo->pFrame = av_frame_alloc();
    return (long)pInfo;
}

int AudioResampling(AVCodecContext * audio_dec_ctx,
    AVFrame * pAudioDecodeFrame,
    int out_sample_fmt,
    int out_channels,
    int out_sample_rate,
    uint8_t* out_buf)
{
    SwrContext * swr_ctx = NULL;
    int data_size = 0;
    int ret = 0;
    int64_t src_ch_layout = audio_dec_ctx->channel_layout;
    int64_t dst_ch_layout = AV_CH_LAYOUT_STEREO;
    int dst_nb_channels = 0;
    int dst_linesize = 0;
    int src_nb_samples = 0;
    int dst_nb_samples = 0;
    int max_dst_nb_samples = 0;
    uint8_t **dst_data = NULL;
    int resampled_data_size = 0;

    swr_ctx = swr_alloc();
    if (!swr_ctx)
    {
        return -1;
    }

    src_ch_layout = (audio_dec_ctx->channels ==
        av_get_channel_layout_nb_channels(audio_dec_ctx->channel_layout)) ?
        audio_dec_ctx->channel_layout :
    av_get_default_channel_layout(audio_dec_ctx->channels);

    if (out_channels == 1)
    {
        //dst_ch_layout = AV_CH_LAYOUT_MONO;
        dst_ch_layout = AV_CH_FRONT_LEFT;
    }
    else if (out_channels == 2)
    {
        dst_ch_layout = AV_CH_LAYOUT_STEREO;
    }
    else
    {
        dst_ch_layout = AV_CH_LAYOUT_SURROUND;
    }

    if (src_ch_layout <= 0)
    {
        return -1;
    }

    src_nb_samples = pAudioDecodeFrame->nb_samples;
    if (src_nb_samples <= 0)
    {
        return -1;
    }

    av_opt_set_int(swr_ctx, "in_channel_layout", src_ch_layout, 0);
    av_opt_set_int(swr_ctx, "in_sample_rate", audio_dec_ctx->sample_rate, 0);
    av_opt_set_sample_fmt(swr_ctx, "in_sample_fmt", audio_dec_ctx->sample_fmt, 0);

    av_opt_set_int(swr_ctx, "out_channel_layout", dst_ch_layout, 0);
    av_opt_set_int(swr_ctx, "out_sample_rate", out_sample_rate, 0);
    av_opt_set_sample_fmt(swr_ctx, "out_sample_fmt", (AVSampleFormat)out_sample_fmt, 0);

    if ((ret = swr_init(swr_ctx)) < 0) {
        return -1;
    }

    max_dst_nb_samples = dst_nb_samples = av_rescale_rnd(src_nb_samples,
        out_sample_rate, audio_dec_ctx->sample_rate, AV_ROUND_UP);
    if (max_dst_nb_samples <= 0)
    {
        return -1;
    }

    dst_nb_channels = av_get_channel_layout_nb_channels(dst_ch_layout);
    ret = av_samples_alloc_array_and_samples(&dst_data, &dst_linesize, dst_nb_channels,
        dst_nb_samples, (AVSampleFormat)out_sample_fmt, 0);
    if (ret < 0)
    {
        return -1;
    }


    dst_nb_samples = av_rescale_rnd(swr_get_delay(swr_ctx, audio_dec_ctx->sample_rate) +
        src_nb_samples, out_sample_rate, audio_dec_ctx->sample_rate, AV_ROUND_UP);
    if (dst_nb_samples <= 0)
    {
        return -1;
    }
    if (dst_nb_samples > max_dst_nb_samples)
    {
        av_free(dst_data[0]);
        ret = av_samples_alloc(dst_data, &dst_linesize, dst_nb_channels,
            dst_nb_samples, (AVSampleFormat)out_sample_fmt, 1);
        max_dst_nb_samples = dst_nb_samples;
    }

    if (swr_ctx)
    {
        ret = swr_convert(swr_ctx, dst_data, dst_nb_samples,
            (const uint8_t **)pAudioDecodeFrame->data, pAudioDecodeFrame->nb_samples);
        if (ret < 0)
        {
            return -1;
        }

        resampled_data_size = av_samples_get_buffer_size(&dst_linesize, dst_nb_channels,
            ret, (AVSampleFormat)out_sample_fmt, 1);
        if (resampled_data_size < 0)
        {
            return -1;
        }
    }
    else
    {
        return -1;
    }

    memcpy(out_buf, dst_data[0], resampled_data_size);

    if (dst_data)
    {
        av_freep(&dst_data[0]);
    }
    av_freep(&dst_data);
    dst_data = NULL;

    if (swr_ctx)
    {
        swr_free(&swr_ctx);
    }
    return resampled_data_size;
}

long ffmpeg_audio_decode(long handle, char *pSrc, long nSrcSize, char *pDst, long *sample_per_sec, long *bits_per_sample, long *channels)
{
    DECODEC_INFO_S *pInfo = (DECODEC_INFO_S *)handle;
    if (!pInfo)
    {
        return -1;
    }

    long nRet = 0;
    AVPacket packet = {0};
    packet.data = (uint8_t *)pSrc;
    packet.size = nSrcSize;

    while(packet.size > 0)
    {
        int nOutSize = 1024*32;
        int frameFinished = 0;
        int nLen = avcodec_decode_audio4(pInfo->pCodecCtx, pInfo->pFrame, &frameFinished, &packet);
        if(nLen < 0)
        {
            printf("decodec audio failed\n");
            break;
        }

        if (nOutSize > 0)
        {
            int data_size = AudioResampling(pInfo->pCodecCtx, pInfo->pFrame, AV_SAMPLE_FMT_S16, 1, 8000, (uint8_t *)pDst);
            if (data_size <= 0)
            {
                continue;
            }
            nRet += data_size;
            pDst += data_size;
        }

        packet.data += nLen;
        packet.size -= nLen;
    }

    return nRet;
}

long ffmpeg_audio_decode_destroy(long handle)
{
    DECODEC_INFO_S *pInfo = (DECODEC_INFO_S *)handle;
    if (!pInfo)
    {
        return -1;
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
    return 0;
}

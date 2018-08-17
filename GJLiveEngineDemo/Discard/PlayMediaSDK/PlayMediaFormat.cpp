#include "PlayMediaSDK.h"
//#include "OS.h"
//#include "Log.h"
extern "C"
{
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavutil/avutil.h"
#include "libswscale/swscale.h"
}

#if (defined WIN32) || (defined __ANDROID__)
#ifndef __WIN64__
#include "mp4.h"
#endif
#endif

struct FORMAT_INFO_S
{
	AVFormatContext *pFmtCtx;  //oc
	AVStream *pStream;
	AVStream *paudioStream;
	long nFrameCount;

	bool bMp4File;
	long hMp4;

	FORMAT_INFO_S()
	{
		memset(this, 0, sizeof(FORMAT_INFO_S));
	}
};

long PlayMedia_RGB5652RGB24(char *pSrc, long nSrcSize, char *pDst, long *nDstSize, long nWidth, long nHeight);

PLAY_MEDIA_API long PlayMedia_OpenOutputFile(char *pFileName, long nWidth, long nHeight, long nBitRate, long nFrameRate)
{
    //创建目录
    char pPath[255];
    memset(pPath, 0, 255);
    for (long n = strlen(pFileName); n > 0; --n)
    {
        if (pFileName[n] == '\\' || pFileName[n] == '/')
        {
            strncpy(pPath, pFileName, n);
            break;
        }
    }
//    OS::RecursiveMakeDir(pPath);

    FORMAT_INFO_S *pInfo = new FORMAT_INFO_S;

#if (defined WIN32) || (defined __ANDROID__)
#ifndef __WIN64__
    char *pName = pFileName + strlen(pFileName) - 3;
    if (!strcmp(pName, "mp4") || !strcmp(pName, "MP4"))
    {
        pInfo->bMp4File = true;
        pInfo->hMp4 = MP4_OpenOutputFile(pFileName, nWidth, nHeight, nBitRate, nFrameRate);
        return (long)pInfo;
    }
#endif
#endif

    av_register_all();
    avcodec_register_all();

    avformat_alloc_output_context2(&pInfo->pFmtCtx, NULL, NULL, pFileName);
    if (!pInfo->pFmtCtx) 
    {
        printf( "Could not create output context\n");
        delete pInfo;
        return 0;
    }

    pInfo->pStream = avformat_new_stream(pInfo->pFmtCtx, 0);
    if (!pInfo->pStream)
    {
        printf( "Failed allocating output stream\n");
        avformat_free_context(pInfo->pFmtCtx);
        delete pInfo;
        return 0;
    }

    //编码参数
    AVCodecContext *c = pInfo->pStream->codec;
    AVCodec *codec = avcodec_find_encoder(AV_CODEC_ID_H264);
    avcodec_get_context_defaults3(c, codec);

    c->bit_rate = nBitRate;
    c->codec_id = AV_CODEC_ID_H264;
    c->codec_type = AVMEDIA_TYPE_VIDEO;
    c->time_base.num = 1;
    c->time_base.den = nFrameRate;
    //c->gop_size = nFrameRate;
    c->width = nWidth;
    c->height = nHeight;
    c->pix_fmt = AV_PIX_FMT_YUV420P;
    c->flags |= CODEC_FLAG_GLOBAL_HEADER;	

    if (avcodec_open2(c, codec, 0) < 0)
    {
        printf("could not open codec\n");
        avformat_free_context(pInfo->pFmtCtx);
        delete pInfo;
        return 0;
    }

    //初始化AVFrame
    c->coded_frame = av_frame_alloc();
    if (!c->coded_frame)
    {
        avformat_free_context(pInfo->pFmtCtx);
        delete pInfo;
        return 0;
    }
    int size = avpicture_get_size(AV_PIX_FMT_YUV420P, nWidth, nHeight);
    uint8_t *picture_buf = (uint8_t *)malloc(size);
    if (!picture_buf) 
    {
        av_frame_free(&c->coded_frame);
        return 0;
    }
    avpicture_fill((AVPicture *)c->coded_frame, picture_buf, AV_PIX_FMT_YUV420P, nWidth, nHeight);

	pInfo->paudioStream = avformat_new_stream(pInfo->pFmtCtx, 0);
	if (!pInfo->paudioStream)
	{
		printf( "Failed allocating output stream\n");
		avformat_free_context(pInfo->pFmtCtx);
		delete pInfo;
		return 0;
	}

	c = pInfo->paudioStream->codec;
	codec = avcodec_find_encoder(AV_CODEC_ID_AAC);
	avcodec_get_context_defaults3(c, codec);

	c->codec = codec;
	c->codec_id = AV_CODEC_ID_AAC;
	c->codec_type = AVMEDIA_TYPE_AUDIO;
	c->bits_per_coded_sample = 2;
	c->bit_rate = 128000;
	c->sample_rate = 8000;
	c->channels = 1;
	c->sample_fmt = AV_SAMPLE_FMT_S16;
	c->time_base.num = 1;
	c->time_base.den = 10;

	int ret = avcodec_open2(c, codec, 0);
	if (ret < 0)
	{
		printf("could not open codec\n");
		avformat_free_context(pInfo->pFmtCtx);
		delete pInfo;
		return 0;
	}

	c->coded_frame = av_frame_alloc();
	if (!c->coded_frame)
	{
		avformat_free_context(pInfo->pFmtCtx);
		delete pInfo;
		return 0;
	}

    //打开文件
    if (avio_open(&pInfo->pFmtCtx->pb, pFileName, AVIO_FLAG_WRITE) < 0)
    {
        printf( "Could not open output file '%s'", pFileName);
        av_frame_free(&pInfo->pStream->codec->coded_frame);
        avformat_free_context(pInfo->pFmtCtx);
        delete pInfo;
        return 0;
    }

    //写入文件头
    if (avformat_write_header(pInfo->pFmtCtx, NULL) < 0)
    {
        PlayMedia_CloseFile((long)pInfo);
        return 0;
    }

    return (long)pInfo;
}

PLAY_MEDIA_API long PlayMedia_CloseFile(long hFile)
{
    FORMAT_INFO_S *pInfo = (FORMAT_INFO_S *)hFile;
    if (!pInfo)
    {
        return -1;
    }

    if (pInfo->bMp4File)
    {
#if (defined WIN32) || (defined __ANDROID__)
#ifndef __WIN64__
        MP4_CloseFile(pInfo->hMp4);
#endif
#endif
    }
    else if (pInfo->pFmtCtx)
    {
        av_write_trailer(pInfo->pFmtCtx);
        avcodec_close(pInfo->pStream->codec);
		avcodec_close(pInfo->paudioStream->codec);
        avio_close(pInfo->pFmtCtx->pb);
        avformat_free_context(pInfo->pFmtCtx);
    }

    delete pInfo;
    return 0;
}

PLAY_MEDIA_API long PlayMedia_WriteFile(long hFile, char *pData, long nSize, long nFrameType/*=false*/)
{
	FORMAT_INFO_S *pInfo = (FORMAT_INFO_S *)hFile;
	if (!pInfo)
	{
		return -1;
	}

#if (defined WIN32) || (defined __ANDROID__)
#ifndef __WIN64__
	if (pInfo->bMp4File)
	{
		return MP4_WriteFile(pInfo->hMp4, pData, nSize, nFrameType);
	}
#endif
#endif

	//if (pInfo->nFrameCount <= 0)
	//{
	//    if (nFrameType)
	//    {
	//        return 0;
	//    }
	//}

	if (nSize > 0)
	{
		AVPacket pkt;
		av_init_packet(&pkt);

		if (!nFrameType)
		{
			pkt.pts = av_rescale_q(pInfo->nFrameCount+1, pInfo->pStream->codec->time_base, pInfo->pStream->time_base);
			pkt.stream_index = pInfo->pStream->index;
			pkt.flags = AV_PKT_FLAG_KEY;
			++pInfo->nFrameCount;
		}
		else if (nFrameType == 1)
		{
			pkt.pts = av_rescale_q(pInfo->nFrameCount+1, pInfo->pStream->codec->time_base, pInfo->pStream->time_base);
			pkt.stream_index = pInfo->pStream->index;
			pkt.flags = 0;
			++pInfo->nFrameCount;
		}
		else if (nFrameType == 3)
		{
			pkt.pts = av_rescale_q(pInfo->nFrameCount + 1, pInfo->paudioStream->codec->time_base, pInfo->paudioStream->time_base);
			pkt.stream_index = pInfo->paudioStream->index;
		}

		pkt.data = (uint8_t*)pData;
		pkt.size= nSize;

		if (av_write_frame(pInfo->pFmtCtx, &pkt) != 0)
		{
			printf("Error while writing video frame\n");
			return -1;
		}
	}
	return 0;
}

PLAY_MEDIA_API long PlayMedia_WriteFileWithPts(long hFile, char *pData, long nSize, long nFrameType, unsigned long long nPts)
{
    FORMAT_INFO_S *pInfo = (FORMAT_INFO_S *)hFile;
    if (!pInfo)
    {
        return -1;
    }

#if (defined WIN32) || (defined __ANDROID__)
#ifndef __WIN64__
    if (pInfo->bMp4File)
    {
        return MP4_WriteFileWithPts(pInfo->hMp4, pData, nSize, nFrameType, nPts);
    }
#endif
#endif

    //if (pInfo->nFrameCount <= 0)
    //{
    //    if (nFrameType)
    //    {
    //        return 0;
    //    }
    //}

    if (nSize > 0)
    {
        AVPacket pkt;
        av_init_packet(&pkt);

		if (!nFrameType)
		{
			pkt.pts = nPts * (pInfo->pStream->time_base.den / 1000);
			pkt.stream_index = pInfo->pStream->index;
			pkt.flags = AV_PKT_FLAG_KEY;
			++pInfo->nFrameCount;
		}
		else if (nFrameType == 1)
		{
			pkt.pts = nPts * (pInfo->pStream->time_base.den / 1000);
			pkt.stream_index = pInfo->pStream->index;
			pkt.flags = 0;
			++pInfo->nFrameCount;
		}
		else if (nFrameType == 3)
		{
			pkt.pts = nPts * (pInfo->paudioStream->time_base.den / 1000);
			pkt.stream_index = pInfo->paudioStream->index;
		}

        pkt.data = (uint8_t*)pData;
        pkt.size= nSize;
		 
        if (av_write_frame(pInfo->pFmtCtx, &pkt) != 0)
        {
            printf("Error while writing video frame\n");
            return -1;
        }
    }

    ++pInfo->nFrameCount;
    return 0;
}

PLAY_MEDIA_API long PlayMedia_SaveYUV2BMPFile(char *pFileName, char *pData, long nSize, long nWidth, long nHeight)
{
    long nRgbSize = nWidth * nHeight * 3;
    char *pRgbBuf = new char [nRgbSize];
    if (!pRgbBuf)
    {
        return -1;
    }
    PlayMedia_YUV2RGB24(pData, nSize, pRgbBuf, &nRgbSize, nWidth, nHeight);
    long nRet = PlayMedia_SaveRGB2File(pFileName, pRgbBuf, nRgbSize, nWidth, nHeight, 24);
    if (pRgbBuf)
    {
        delete pRgbBuf;
    }
    return nRet;
}

PLAY_MEDIA_API long PlayMedia_SaveYUV2JPGFile(char *pFileName, char *pData, long nSize, long nWidth, long nHeight)
{
    av_register_all();
    AVFormatContext *pFormatCtx = avformat_alloc_context();
    AVOutputFormat *fmt = av_guess_format("mjpeg", NULL, NULL);
    pFormatCtx->oformat = fmt;
    if (avio_open(&pFormatCtx->pb, pFileName, AVIO_FLAG_READ_WRITE) < 0)
    {
        return -1;
    }

    AVStream *video_st = avformat_new_stream(pFormatCtx, 0);
    if (!video_st)
    {
        return -1;
    }
    AVCodecContext *pCodecCtx = video_st->codec;
    pCodecCtx->codec_id = fmt->video_codec;
    pCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
    pCodecCtx->pix_fmt = AV_PIX_FMT_YUVJ420P;
    pCodecCtx->width = nWidth;
    pCodecCtx->height = nHeight;
    pCodecCtx->time_base.num = 1;
    pCodecCtx->time_base.den = 25;

    AVCodec *pCodec = avcodec_find_encoder(pCodecCtx->codec_id);
    if (!pCodec)
    {
        return -1;
    }
    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        return -1;
    }

    AVFrame *picture = av_frame_alloc();
    avpicture_get_size(pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
    avpicture_fill((AVPicture *)picture, (uint8_t *)pData, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);

    avformat_write_header(pFormatCtx, NULL);

    AVPacket pkt;
    av_new_packet(&pkt,nWidth * nHeight * 3);

    picture->data[0] = (uint8_t *)pData;
    picture->data[1] = (uint8_t *)(pData+ nWidth * nHeight);
    picture->data[2] = (uint8_t *)(pData+ nWidth * nHeight * 5 / 4);

    int got_picture = 0;
    if(avcodec_encode_video2(pCodecCtx, &pkt,picture, &got_picture) < 0)
    {
        return -1;
    }
    if (got_picture==1)
    {
        pkt.stream_index = video_st->index;
        av_write_frame(pFormatCtx, &pkt);
    }

    av_free_packet(&pkt);
    av_write_trailer(pFormatCtx);

    if (video_st)
    {
        avcodec_close(video_st->codec);
        av_frame_free(&picture);
    }
    avio_close(pFormatCtx->pb);
    avformat_free_context(pFormatCtx);
    return 0;
}

PLAY_MEDIA_API long PlayMedia_SaveYUV2File(char *pFileName, char *pData, long nSize, long nWidth, long nHeight)
{
    if (!strcmp(pFileName + strlen(pFileName) - 3, "jpg") || !strcmp(pFileName + strlen(pFileName) - 3, "JPG"))
    {
        return PlayMedia_SaveYUV2JPGFile(pFileName, pData, nSize, nWidth, nHeight);
    }
    else if (!strcmp(pFileName + strlen(pFileName) - 3, "bmp") || !strcmp(pFileName + strlen(pFileName) - 3, "BMP"))
    {
        return PlayMedia_SaveYUV2BMPFile(pFileName, pData, nSize, nWidth, nHeight);
    }
    else
    {
        return -1;
    }
}

PLAY_MEDIA_API long PlayMedia_SaveRGB2File(char *pFileName, char *pData, long nSize, long nWidth, long nHeight, long nBitDepth)
{
    char *pRgbBuf = 0;
    if (nBitDepth == 16)
    {
        long nRgbSize = nWidth * nHeight * 3;
        pRgbBuf = new char [nRgbSize];
        PlayMedia_RGB5652RGB24(pData, nSize, pRgbBuf, &nRgbSize, nWidth, nHeight);
        for (int i = 0; i < nWidth * nHeight * 3; i += 3)
        {
            unsigned char c = (unsigned char)pRgbBuf[i];
            pRgbBuf[i] =  pRgbBuf[i + 2];
            pRgbBuf[i + 2] =  c;
        }
        pData = pRgbBuf;
        nSize = nRgbSize;
        nBitDepth = 24;
    }
#pragma pack(push,2)
    typedef struct tagBITMAPFILEHEADER
    {
        unsigned short bfType;
        unsigned int bfSize;
        unsigned short bfReserved1;
        unsigned short bfReserved2;
        unsigned int bfOffBits;
    } BITMAPFILEHEADER;
#pragma pack(pop)

    typedef struct tagBITMAPINFOHEADER{    
        unsigned int biSize;
        int biWidth;
        int biHeight;
        unsigned short biPlanes;
        unsigned short biBitCount;
        unsigned int biCompression;
        unsigned int biSizeImage;
        int biXPelsPerMeter;
        int biYPelsPerMeter;
        unsigned int biClrUsed;
        unsigned int biClrImportant;
    } BITMAPINFOHEADER;

    BITMAPFILEHEADER bmpFileHeader;
    bmpFileHeader.bfType = ('M' << 8) | 'B'; //'BM';
    bmpFileHeader.bfOffBits = sizeof(BITMAPFILEHEADER)+sizeof(BITMAPINFOHEADER);
    bmpFileHeader.bfSize = bmpFileHeader.bfOffBits + nSize;

    BITMAPINFOHEADER header;
    header.biSize = sizeof(BITMAPINFOHEADER);
    header.biWidth = nWidth;
    header.biHeight = -nHeight;
    header.biBitCount = nBitDepth;
    header.biCompression = 0;
    header.biSizeImage = 0;   
    header.biClrImportant = 0;
    header.biClrUsed = 0;
    header.biXPelsPerMeter = 100;
    header.biYPelsPerMeter = 100;
    header.biPlanes = 1;

    //创建目录
    char pPath[255];
    memset(pPath, 0, 255);
    for (long n = strlen(pFileName); n > 0; --n)
    {
        if (pFileName[n] == '\\' || pFileName[n] == '/')
        {
            strncpy(pPath, pFileName, n);
            break;
        }
    }
//    OS::RecursiveMakeDir(pPath);

    FILE *file = fopen(pFileName, "wb");
    if (file)
    {
        fwrite(&bmpFileHeader, sizeof(BITMAPFILEHEADER), 1, file);
        fwrite(&header, sizeof(BITMAPINFOHEADER), 1, file);
        fwrite(pData, 1, nSize, file);
        fclose(file);
    }

    if (pRgbBuf)
    {
        delete pRgbBuf;
    }
    return 0;
}

PLAY_MEDIA_API long PlayMedia_YUV2RGB24(char *pSrc, long nSrcSize, char *pDst, long *nDstSize, long nWidth, long nHeight)
{
    AVFrame *pFrameRGB = av_frame_alloc();
    avpicture_fill((AVPicture *)pFrameRGB, (uint8_t *)pDst, AV_PIX_FMT_RGB24, nWidth, nHeight);

    SwsContext *img_convert_ctx = 0;
    img_convert_ctx = sws_getCachedContext(img_convert_ctx,
        nWidth, nHeight, AV_PIX_FMT_RGB24, nWidth, nHeight, AV_PIX_FMT_RGB24, SWS_BICUBIC, NULL, NULL, NULL);
    if (!img_convert_ctx)
    {
        return -1;
    }

    AVFrame *pFrameYUV = av_frame_alloc();
    avpicture_fill((AVPicture*)pFrameYUV, (uint8_t *)pSrc, AV_PIX_FMT_RGB24 , nWidth ,nHeight);
    uint8_t *ptmp = pFrameYUV->data[1];//U,V互换
    pFrameYUV->data [1] = pFrameYUV->data [2];
    pFrameYUV->data [2] = ptmp;
    sws_scale(img_convert_ctx, pFrameYUV->data, pFrameYUV->linesize,
        0, nHeight, pFrameRGB->data, pFrameRGB->linesize);

    if(img_convert_ctx)
    {
        sws_freeContext(img_convert_ctx);
        img_convert_ctx = NULL;
    }

    if (pFrameRGB)
    {
        av_frame_free(&pFrameRGB);
    }

    if (pFrameYUV)
    {
        av_frame_free(&pFrameYUV);
    }

    *nDstSize = nWidth * nHeight * 3;

    return 0;
}

PLAY_MEDIA_API long PlayMedia_YUV2RGB32(char *pSrc, long nSrcSize, char *pDst, long *nDstSize, long nWidth, long nHeight)
{
    AVFrame *pFrameRGB = av_frame_alloc();
    avpicture_fill((AVPicture *)pFrameRGB, (uint8_t *)pDst, AV_PIX_FMT_RGB32, nWidth, nHeight);

    SwsContext *img_convert_ctx = 0;
    img_convert_ctx = sws_getCachedContext(img_convert_ctx,
        nWidth, nHeight, AV_PIX_FMT_YUV420P, nWidth, nHeight, AV_PIX_FMT_RGB32, SWS_BICUBIC, NULL, NULL, NULL);
    if (!img_convert_ctx)
    {
        return -1;
    }

    AVFrame *pFrameYUV = av_frame_alloc();
    avpicture_fill((AVPicture*)pFrameYUV, (uint8_t *)pSrc, AV_PIX_FMT_YUV420P , nWidth ,nHeight);
    sws_scale(img_convert_ctx, pFrameYUV->data, pFrameYUV->linesize,
        0, nHeight, pFrameRGB->data, pFrameRGB->linesize);

    if(img_convert_ctx)
    {
        sws_freeContext(img_convert_ctx);
        img_convert_ctx = NULL;
    }

    if (pFrameRGB)
    {
        av_frame_free(&pFrameRGB);
    }

    if (pFrameYUV)
    {
        av_frame_free(&pFrameYUV);
    }

    *nDstSize = nWidth * nHeight * 4;

    return 0;
}

long PlayMedia_RGB5652RGB24(char *pSrc, long nSrcSize, char *pDst, long *nDstSize, long nWidth, long nHeight)
{
    AVFrame *pFrameRGB = av_frame_alloc();
    avpicture_fill((AVPicture *)pFrameRGB, (uint8_t *)pDst, AV_PIX_FMT_RGB24, nWidth, nHeight);

    SwsContext *img_convert_ctx = 0;
    img_convert_ctx = sws_getCachedContext(img_convert_ctx,
        nWidth, nHeight, AV_PIX_FMT_RGB565, nWidth, nHeight, AV_PIX_FMT_RGB24, SWS_BICUBIC, NULL, NULL, NULL);
    if (!img_convert_ctx)
    {
        return -1;
    }

    AVFrame *pFrameYUV = av_frame_alloc();
    avpicture_fill((AVPicture*)pFrameYUV, (uint8_t *)pSrc, AV_PIX_FMT_RGB565 , nWidth ,nHeight);
    sws_scale(img_convert_ctx, pFrameYUV->data, pFrameYUV->linesize,
        0, nHeight, pFrameRGB->data, pFrameRGB->linesize);

    if(img_convert_ctx)
    {
        sws_freeContext(img_convert_ctx);
        img_convert_ctx = NULL;
    }

    if (pFrameRGB)
    {
        av_frame_free(&pFrameRGB);
    }

    if (pFrameYUV)
    {
        av_frame_free(&pFrameYUV);
    }

    *nDstSize = nWidth * nHeight * 3;

    return 0;
}

#include "mp4.h"
#include "mp4v2.h"
#include <string.h>

#ifndef __WIN64__

struct MP4_INFO_S
{
    MP4FileHandle handle;
    MP4TrackId video;
    MP4TrackId audio;
    long width;
    long heigth;
    long framerate;
    long nFrameCount;
    long idr_head_length;
    unsigned long long start_pts;

    MP4_INFO_S()
    {
        memset(this, 0, sizeof(MP4_INFO_S));
    }
};

#define     MP4_TIMESCALE   90000

void make_dsi( unsigned int sampling_frequency_index, unsigned int channel_configuration, unsigned   char* dsi )
{
    unsigned int object_type = 2;
    dsi[0] = (object_type<<3) | (sampling_frequency_index>>1);
    dsi[1] = ((sampling_frequency_index&1)<<7) | (channel_configuration<<3);
}

int get_sr_index(unsigned int sampling_frequency)
{
    switch (sampling_frequency) 
    {
    case 96000: return 0;
    case 88200: return 1;
    case 64000: return 2;
    case 48000: return 3;
    case 44100: return 4;
    case 32000: return 5;
    case 24000: return 6;
    case 22050: return 7;
    case 16000: return 8;
    case 12000: return 9;
    case 11025: return 10;
    case 8000:  return 11;
    case 7350:  return 12;
    default:    return 0;
    }
}

long MP4_OpenOutputFile(char *pFileName, long nWidth, long nHeight, long nBitRate, long nFrameRate)
{
    MP4_INFO_S *pInfo = new MP4_INFO_S;

    pInfo->width = nWidth;
    pInfo->heigth = nHeight;
    pInfo->framerate = nFrameRate;

    pInfo->handle = MP4Create(pFileName);
    if (pInfo->handle == MP4_INVALID_FILE_HANDLE)
    {
        return -1;
    }
    MP4SetTimeScale(pInfo->handle, MP4_TIMESCALE);
    MP4SetVideoProfileLevel(pInfo->handle, 1);

    return (long)pInfo;
}

long MP4_CloseFile(long hFile)
{
    MP4_INFO_S *pInfo = (MP4_INFO_S *)hFile;
    if (!pInfo)
    {
        return -1;
    }
    MP4Close(pInfo->handle);
    delete pInfo;
    return 0;
}

long find_sps_pps(char *pData, long nSize, char *pSps, long &nSps, char *pPps, long &nPps)
{
    long nSpsPos = 0, nPpsPos = 0, nIdrPos = 0;
    for (int i = 0; i < nSize; ++i)
    {
        if (pData[i] == 0x00 &&
            pData[i + 1] == 0x00 &&
            pData[i + 2] == 0x00 &&
            pData[i + 3] == 0x01 &&
            (pData[i + 4]&0x3F) == 0x27)
        {
            nSpsPos = i + 4;
        }
        else if (pData[i] == 0x00 &&
            pData[i + 1] == 0x00 &&
            pData[i + 2] == 0x00 &&
            pData[i + 3] == 0x01 &&
            (pData[i + 4]&0x3F) == 0x28)
        {
            nPpsPos = i + 4;
            nSps = i - nSpsPos;
            memcpy(pSps, pData + nSpsPos, nSps);
        }
        else if (pData[i] == 0x00 &&
            pData[i + 1] == 0x00 &&
            pData[i + 2] == 0x00 &&
            pData[i + 3] == 0x01 &&
            (pData[i + 4]&0x3F) == 0x25)
        {
            nIdrPos = i + 4;
            nPps = i - nPpsPos;
            memcpy(pPps, pData + nPpsPos, nPps);
            break;
        }
    }
    return 0;
}

long MP4_WriteFile(long hFile, char *pData, long nSize, long nFrameType)
{
    MP4_INFO_S *pInfo = (MP4_INFO_S *)hFile;
    if (!pInfo)
    {
        return -1;
    }

    if (pInfo->nFrameCount <= 0)
    {
        if (nFrameType)
        {
            return 0;
        }
    }

    if (nSize > 0)
    {
        if (nFrameType == 0)
        {
            if (!pInfo->nFrameCount)
            {
                char sps[64];
                long sps_length = 0;
                char pps[64];
                long pps_length = 0;
                find_sps_pps(pData, nSize, sps, sps_length, pps, pps_length);

                pInfo->video = MP4AddH264VideoTrack(
                    pInfo->handle, MP4_TIMESCALE, 
                    MP4_TIMESCALE / pInfo->framerate, 
                    pInfo->width, pInfo->heigth, 
                    sps[1], sps[2],sps[3], 3);
                MP4AddH264SequenceParameterSet(pInfo->handle, pInfo->video, (uint8_t *)sps, sps_length);
                MP4AddH264PictureParameterSet(pInfo->handle, pInfo->video, (uint8_t *)pps, pps_length);
                pInfo->idr_head_length = sps_length + pps_length + 8;
            }

            pData += pInfo->idr_head_length;
            nSize -= pInfo->idr_head_length + 4;
            uint8_t *tmp = (uint8_t *)pData;
            tmp[0] = (nSize & 0xff000000) >> 24;
            tmp[1] = (nSize & 0x00ff0000) >> 16;
            tmp[2] = (nSize & 0x0000ff00) >> 8;
            tmp[3] =  nSize & 0x000000ff;
            MP4WriteSample(pInfo->handle, pInfo->video, (uint8_t *)pData, nSize + 4, MP4_INVALID_DURATION, 0, 1);
        }
        else if (nFrameType == 1)
        {
            nSize -= 4;
            uint8_t *tmp = (uint8_t *)pData;
            tmp[0] = (nSize & 0xff000000) >> 24;
            tmp[1] = (nSize & 0x00ff0000) >> 16;
            tmp[2] = (nSize & 0x0000ff00) >> 8;
            tmp[3] =  nSize & 0x000000ff;
            MP4WriteSample(pInfo->handle, pInfo->video, (uint8_t *)pData, nSize + 4, MP4_INVALID_DURATION, 0, 1);
        }
        else if (nFrameType == 2)
        {
            MP4WriteSample(pInfo->handle, pInfo->video, (uint8_t *)pData, nSize, MP4_INVALID_DURATION, 0, 1);
        }
        else if (nFrameType == 3)
        {
            if (!pInfo->audio)
            {
                pInfo->audio = MP4AddAudioTrack(pInfo->handle, 8000, 1024, MP4_MPEG4_AUDIO_TYPE);
                if (pInfo->audio == MP4_INVALID_TRACK_ID)
                {
                    return -1;
                }
                MP4SetAudioProfileLevel(pInfo->handle, 0x2);

                uint8_t p_config[2] = {0x14, 0x10};
                make_dsi(get_sr_index(8000), 1, p_config);
                MP4SetTrackESConfiguration(pInfo->handle, pInfo->audio, p_config, 2);
            }
            pData += 7;
            nSize -= 7;
            MP4WriteSample(pInfo->handle, pInfo->audio, (uint8_t *)pData, nSize, MP4_INVALID_DURATION, 0, 1);
            return 0;
        }
    }
    ++pInfo->nFrameCount;
    return 0;
}

long MP4_WriteFileWithPts(long hFile, char *pData, long nSize, long nFrameType, unsigned long long nPts)
{
    MP4_INFO_S *pInfo = (MP4_INFO_S *)hFile;
    if (!pInfo)
    {
        return -1;
    }

    if (pInfo->nFrameCount <= 0)
    {
        if (nFrameType)
        {
            return 0;
        }
    }

    if (nSize > 0)
    {
        if (nFrameType == 0)
        {
            if (!pInfo->nFrameCount)
            {
                char sps[64];
                long sps_length = 0;
                char pps[64];
                long pps_length = 0;
                find_sps_pps(pData, nSize, sps, sps_length, pps, pps_length);

                pInfo->video = MP4AddH264VideoTrack(
                    pInfo->handle, MP4_TIMESCALE, 
                    MP4_TIMESCALE / pInfo->framerate, 
                    pInfo->width, pInfo->heigth, 
                    sps[1], sps[2],sps[3], 3);
                MP4AddH264SequenceParameterSet(pInfo->handle, pInfo->video, (uint8_t *)sps, sps_length);
                MP4AddH264PictureParameterSet(pInfo->handle, pInfo->video, (uint8_t *)pps, pps_length);
                pInfo->idr_head_length = sps_length + pps_length + 8;
                pInfo->start_pts = nPts;
            }

            pData += pInfo->idr_head_length;
            nSize -= pInfo->idr_head_length + 4;
            uint8_t *tmp = (uint8_t *)pData;
            tmp[0] = (nSize & 0xff000000) >> 24;
            tmp[1] = (nSize & 0x00ff0000) >> 16;
            tmp[2] = (nSize & 0x0000ff00) >> 8;
            tmp[3] =  nSize & 0x000000ff;
            MP4Duration duration = nPts - pInfo->start_pts;
            MP4WriteSample(pInfo->handle, pInfo->video, (uint8_t *)pData, nSize + 4, duration, 0, 1);
        }
        else if (nFrameType == 1)
        {
            nSize -= 4;
            uint8_t *tmp = (uint8_t *)pData;
            tmp[0] = (nSize & 0xff000000) >> 24;
            tmp[1] = (nSize & 0x00ff0000) >> 16;
            tmp[2] = (nSize & 0x0000ff00) >> 8;
            tmp[3] =  nSize & 0x000000ff;
            MP4Duration duration = nPts - pInfo->start_pts;
            MP4WriteSample(pInfo->handle, pInfo->video, (uint8_t *)pData, nSize + 4, duration, 0, 1);
        }
        else if (nFrameType == 2)
        {
            MP4Duration duration = nPts * (MP4_TIMESCALE / 1000);
            MP4WriteSample(pInfo->handle, pInfo->video, (uint8_t *)pData, nSize, duration, 0, 1);
        }
        else if (nFrameType == 3)
        {
            if (!pInfo->audio)
            {
                pInfo->audio = MP4AddAudioTrack(pInfo->handle, 8000, 1024, MP4_MPEG4_AUDIO_TYPE);
                if (pInfo->audio == MP4_INVALID_TRACK_ID)
                {
                    printf("add audio track failed.\n");
                    return -1;
                }
                MP4SetAudioProfileLevel(pInfo->handle, 0x2);

                uint8_t p_config[2] = {0x14, 0x10};
                make_dsi(get_sr_index(8000), 1, p_config);
                MP4SetTrackESConfiguration(pInfo->handle, pInfo->audio, p_config, 2);
            }
            pData += 7;
            nSize -= 7;

            MP4Duration duration = nPts - pInfo->start_pts;
            MP4WriteSample(pInfo->handle, pInfo->audio, (uint8_t *)pData, nSize, duration, 0, 1);
            return 0;
        }
    }
    ++pInfo->nFrameCount;
    return 0;
}

#endif
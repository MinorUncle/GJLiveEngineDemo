#ifndef _MP4_H_
#define _MP4_H_

long MP4_OpenOutputFile(char *pFileName, long nWidth, long nHeight, long nBitRate, long nFrameRate);
long MP4_CloseFile(long hFile);
long MP4_WriteFile(long hFile, char *pData, long nSize, long nFrameType);
long MP4_WriteFileWithPts(long hFile, char *pData, long nSize, long nFrameType, unsigned long long nPts);

#endif
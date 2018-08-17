#ifndef _FFMPEG_AUDIO_H_
#define _FFMPEG_AUDIO_H_

long ffmpeg_audio_decode_create(long codecid);
long ffmpeg_audio_decode(long handle, char *pSrc, long nSrcSize, char *pDst, long *sample_per_sec, long *bits_per_sample, long *channels);
long ffmpeg_audio_decode_destroy(long handle);

long ffmpeg_audio_encode_create(long codecid, long sample_per_sec, long bits_per_sample, long channels);
long ffmpeg_audio_encode(long handle, char *pSrc, long nSrcSize, char *pDst);
long ffmpeg_audio_encode_destroy(long handle);

#endif//_FFMPEG_AUDIO_H_
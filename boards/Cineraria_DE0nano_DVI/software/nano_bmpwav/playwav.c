/* WAVファイル再生 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <system.h>
#include <io.h>
#include <alt_types.h>
#include <sys/alt_cache.h>

#include "gs_spu.h"


#define nd_WAVBUFF_SIZE		(64*1024)
#define nd_WAV_CH_SIZE		((nd_WAVBUFF_SIZE/2) - 256)
#define nd_WAV_L_START_OFFS	(0)
#define nd_WAV_L_STOP_OFFS	(nd_WAV_L_START_OFFS + nd_WAV_CH_SIZE - 2)
#define nd_WAV_R_START_OFFS	(nd_WAVBUFF_SIZE/2)
#define nd_WAV_R_STOP_OFFS	(nd_WAV_R_START_OFFS + nd_WAV_CH_SIZE - 2)

#define nd_SPU_STREAM_LCH		(1)
#define nd_SPU_STREAM_RCH		(63)
#define nd_SPU_STREAM_OPTION	(spu_datatype_liner16 | spu_loop_enable | spu_smooth_enable)


/***** SPU処理 *****/
static unsigned int g_spu_streamoffs = 0;	// リングバッファポインタ 
static unsigned int g_wavsize = 0;			// 再生WAVファイルのデータ長 
static unsigned int g_playsize = 0;			// 再生したデータ長 
static alt_u32 g_dev_spu = 0;
static alt_u16 *p_g_wavbuff = NULL;
static FILE *p_g_fwav;

int spu_init(alt_u32 dev_pcm)			// 初期化 
{
	int i;

	if (dev_pcm == 0) {
		IOWR(g_dev_spu, spu_reg_status, spu_mute_enable);
		IOWR(g_dev_spu, spu_reg_setup, 0);

		if (p_g_wavbuff != NULL) alt_uncached_free(p_g_wavbuff);
		g_dev_spu = 0;

		return 0;
	}

	p_g_wavbuff = (alt_u16 *)alt_uncached_malloc(nd_WAVBUFF_SIZE);
	if (p_g_wavbuff == NULL) return -1;

	g_dev_spu = dev_pcm;

//	IOWR(dev_pcm, spu_reg_status, spu_mute_enable);
	IOWR(dev_pcm, spu_reg_setup, 0);

	for(i=1 ; i<=spudef_slotmax ; i++) {
		IOWR(dev_pcm, spu_reg_slotstatus(i), spu_keyoff);
		IOWR(dev_pcm, spu_reg_volume_l(i), 0);
		IOWR(dev_pcm, spu_reg_volume_r(i), 0);
	}

	IOWR(dev_pcm, spu_reg_setup, spudef_slotmax);
	IOWR(dev_pcm, spu_reg_status, 0);
	IOWR(dev_pcm, spu_reg_aclink, 0x04000);
	IOWR(dev_pcm, spu_reg_aclink, 0x14000);

	IOWR(dev_pcm, spu_reg_sync, 1);
	while( (IORD(dev_pcm, spu_reg_sync) & spu_syncbusy_bitmask) ) {}

	return 0;
}

int spu_stream_play(const char *wavname,int volume)	// 再生開始 
{
	alt_u32 dev_pcm = g_dev_spu;
	alt_u32 startaddr,stopaddr;
	unsigned char wavbuff[44];
	int readsize,stmono,samplebit,err=1;
	unsigned int wavfreq,wavsize,speed;

	if (!dev_pcm) return -1;

	/* WAVファイルを開く */

	p_g_fwav = fopen(wavname, "rb");
	if (p_g_fwav == NULL) {
		printf("[!] %s not found.\n", wavname);
		return -1;
	}

	/* WAVヘッダの解析 */

	readsize = fread(wavbuff, 1, 44, p_g_fwav);
	if (readsize == 44) {
		if (wavbuff[8]=='W' && wavbuff[9]=='A' && wavbuff[10]=='V' && wavbuff[11]=='E' && 	// WAVチャンク 
				wavbuff[20] == 0x01) {	// リニアPCM 

			stmono    =  wavbuff[22];		// モノラル=1,ステレオ=2
			wavfreq   = (wavbuff[25]<< 8)| wavbuff[24];
			samplebit =  wavbuff[34];		// サンプルあたりのビット数 16/8
			wavsize   = (wavbuff[43]<<24)|(wavbuff[42]<<16)|(wavbuff[41]<< 8)| wavbuff[40];

			if (stmono == 2 && samplebit == 16) {
				speed = (wavfreq << 15) / spudef_samplefreq;
				err = 0;
			}
		}
	}
	if (err) {
		printf("[!] This file does not correspond.\n");
		fclose(p_g_fwav);
		return -1;
	}
	printf("file : %s\nfreq %dHz / time %dsec\n",wavname,wavfreq,wavsize/(wavfreq*4));

	/* SPUレジスタにセット */

	g_spu_streamoffs = 0;
	g_wavsize = wavsize;
	g_playsize = 0;

	if (volume > 255) volume = 255; else if (volume < 0) volume = 0;

	startaddr = ((alt_u32)p_g_wavbuff) + nd_WAV_L_START_OFFS;
	stopaddr = ((alt_u32)p_g_wavbuff) + nd_WAV_L_STOP_OFFS;

	IOWR(dev_pcm, spu_reg_slotstatus(nd_SPU_STREAM_LCH), spu_keyon | spu_synckeyon_enable | nd_SPU_STREAM_OPTION);
	IOWR(dev_pcm, spu_reg_envelope(nd_SPU_STREAM_LCH),	speed);
	IOWR(dev_pcm, spu_reg_volume_l(nd_SPU_STREAM_LCH),	volume);
	IOWR(dev_pcm, spu_reg_volume_r(nd_SPU_STREAM_LCH),	0);
	IOWR(dev_pcm, spu_reg_startaddr(nd_SPU_STREAM_LCH),	(startaddr & spu_startaddr_bitmask));
	IOWR(dev_pcm, spu_reg_stopaddr(nd_SPU_STREAM_LCH),	(stopaddr  & spu_stopaddr_bitmask));
	IOWR(dev_pcm, spu_reg_loopaddr(nd_SPU_STREAM_LCH),	(startaddr & spu_loopaddr_bitmask));

	startaddr = ((alt_u32)p_g_wavbuff) + nd_WAV_R_START_OFFS;
	stopaddr = ((alt_u32)p_g_wavbuff) + nd_WAV_R_STOP_OFFS;

	IOWR(dev_pcm, spu_reg_slotstatus(nd_SPU_STREAM_RCH), spu_keyon | spu_synckeyon_enable | nd_SPU_STREAM_OPTION);
	IOWR(dev_pcm, spu_reg_envelope(nd_SPU_STREAM_RCH),	speed);
	IOWR(dev_pcm, spu_reg_volume_l(nd_SPU_STREAM_RCH),	0);
	IOWR(dev_pcm, spu_reg_volume_r(nd_SPU_STREAM_RCH),	volume);
	IOWR(dev_pcm, spu_reg_startaddr(nd_SPU_STREAM_RCH),	(startaddr & spu_startaddr_bitmask));
	IOWR(dev_pcm, spu_reg_stopaddr(nd_SPU_STREAM_RCH),	(stopaddr  & spu_stopaddr_bitmask));
	IOWR(dev_pcm, spu_reg_loopaddr(nd_SPU_STREAM_RCH),	(startaddr & spu_loopaddr_bitmask));

	IOWR(dev_pcm, spu_reg_sync, 1);		// シンクロ再生 

	return 0;
}

int spu_bufferfill(void)				// リングバッファのフィル 
{
	alt_u32 dev_pcm = g_dev_spu;
	int i,eof=0;
	int bsize,playpoint,buffpoint;
	alt_u16 *pWavL,*pWavR;
	alt_u32 dat;

	if (!dev_pcm) return -1;
	if (p_g_fwav == NULL) return -1;

	/* 再生位置の確認（バッファが256バイト空くまで待つ） */

	// ↓PLAYADDRレジスタの値はサンプル数の値を返すため、メモリアドレスへの変換には２倍する 
	playpoint = (int)((IORD(dev_pcm, spu_reg_playaddr(nd_SPU_STREAM_LCH))<< 1) & spu_startaddr_bitmask);
	buffpoint = (int)(((unsigned int)p_g_wavbuff + g_spu_streamoffs) & spu_startaddr_bitmask);
	bsize = playpoint - buffpoint;

	if (bsize < 0) bsize += nd_WAV_CH_SIZE;
	if (bsize < 256) return 0;

	/* ファイルから読み込む（128サンプル分） */

	pWavL = p_g_wavbuff + (nd_WAV_L_START_OFFS + g_spu_streamoffs)/2; //(alt_u16 *)(nd_WAV_L_START + g_spu_streamoffs);
	pWavR = p_g_wavbuff + (nd_WAV_R_START_OFFS + g_spu_streamoffs)/2; //(alt_u16 *)(nd_WAV_R_START + g_spu_streamoffs);
	for (i=512/4 ; i>0 ; i--) {
		if (g_playsize >= g_wavsize) {
			eof = 1;
			break;
		}

		fread(&dat, 1, 4, p_g_fwav);
		*pWavL++ = (dat & 0xffff);
		*pWavR++ = (dat >> 16);

		g_playsize+=4;
	}
	for( ; i>0 ; i--) {
		*pWavL++ = 0;
		*pWavR++ = 0;
	}

	/* バッファの非連続部分の処理（１サンプル分をコピーする） */

	if (g_spu_streamoffs == 0) {
		*(p_g_wavbuff + (nd_WAV_L_START_OFFS + nd_WAV_CH_SIZE)/2) = *(p_g_wavbuff + nd_WAV_L_START_OFFS/2);
		*(p_g_wavbuff + (nd_WAV_R_START_OFFS + nd_WAV_CH_SIZE)/2) = *(p_g_wavbuff + nd_WAV_R_START_OFFS/2);
	}

	/* リングバッファポインタを更新 */

	g_spu_streamoffs += 256;
	if (g_spu_streamoffs >= nd_WAV_CH_SIZE) g_spu_streamoffs = 0;

	/* 再生終了フラグを返す */

	return eof;
}

int spu_stream_stop(void)		// 再生終了 
{
	alt_u32 dev_pcm = g_dev_spu;

	if (!dev_pcm) return -1;
	if (p_g_fwav == NULL) return -1;

	IOWR(dev_pcm, spu_reg_slotstatus(nd_SPU_STREAM_LCH), spu_keyoff);
	IOWR(dev_pcm, spu_reg_slotstatus(nd_SPU_STREAM_RCH), spu_keyoff);

	IOWR(dev_pcm, spu_reg_sync, 1);

	fclose(p_g_fwav);

	return 0;
}




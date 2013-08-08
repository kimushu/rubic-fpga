/* ファイルシステムテスト */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <system.h>
#include <io.h>
#include <alt_types.h>
#include <sys/alt_cache.h>

#include "mmcfs/mmcfs.h"
#include "nd_lib/nd_egl.h"

#include "gs_spu.h"


int loadbmp(const char *bmpname, alt_u16 *pFrameBuffer);


void nd_halt(void)
{
	while(1) {}
}


int main(void)
{
	int i,c;
	alt_u16 *pFrameBuffer;

	// システム初期化 

	nd_GsVgaInit();

	i = mmcfs_setup();
	printf("mmcfs_setup value = %d\n",i);

	if ( spu_init(SPU_BASE) ) {
		printf("[!] SPU not assignment.\n");
	}

	for(i=0,c=0 ; i<10 ; i++) {
		c = (c << 1) | 1;
		IOWR(LED_BASE, 0, c);
		usleep(200000);
	}


	// 画像を展開 

	pFrameBuffer = (alt_u16 *)alt_uncached_malloc(na_VRAM_size);
	if (pFrameBuffer != NULL) {
		printf("Framebuffer assignment = 0x%08X\r\n",(unsigned int)pFrameBuffer);

		nd_GsVgaSetBuffer((nd_u32)pFrameBuffer);
        nd_GsEglPage((nd_u32)pFrameBuffer,(nd_u32)pFrameBuffer,0);

		nd_GsVgaScanOn();

		nd_color(nd_COLORGRAY, 0, 256);
		nd_boxfill(0, 0, window_xmax, window_ymax);

        nd_color(nd_COLORWHITE, 0, 256);
		nd_line(0,0, 0,479);
        nd_color(nd_COLORRED, 0, 256);
		nd_line(639,0, 639,479);
        nd_color(nd_COLORLIGHTGREEN, 0, 256);
		nd_line(0,0, 639,0);
        nd_color(nd_COLORBLUE, 0, 256);
		nd_line(0,479, 639,479);

		loadbmp("mmcfs:/de0/pronama.bmp",pFrameBuffer);
		loadbmp("mmcfs:/de0/uzuko3-nano.bmp",pFrameBuffer);

//		nd_GsVgaScanOn();
	} else {
		printf("[!] Framebuffer not assignment.\r\n");
	}


	// WAVファイルを再生 

	if (spu_stream_play("mmcfs:/de0/test.wav", 200)== 0) {
		printf("play start.\n");

		while( spu_bufferfill() == 0 ) {}
	    spu_stream_stop();

		printf("play stop.\n");
	}


	// ワークエリアを開放する

	alt_uncached_free(pFrameBuffer);


	// 終了 

	printf("done.\n");
    nd_halt();

	return 0;
}

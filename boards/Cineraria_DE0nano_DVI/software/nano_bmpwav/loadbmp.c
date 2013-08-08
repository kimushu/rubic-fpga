/* BMP�t�@�C�����[�h */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <system.h>
#include <alt_types.h>

#include "nd_lib/nd_egl.h"


// �w���BMP�t�@�C�����t���[���o�b�t�@�ɓǂݍ��� 

int loadbmp(const char *bmpname, alt_u16 *pFrameBuffer)
{
	FILE *fbmp;
	unsigned char bmp_h[54];
	int xsize,ysize,bpp,line;
	int x,y,x_offs,y_offs,width,height;
	unsigned char bmp_pixel[4];
	alt_u16 *ppix,*pline;

	// BMP�t�@�C�����J�� 

	fbmp = fopen(bmpname, "rb");
	if (fbmp == NULL) {
		printf("[!] %s is not found.\n", bmpname);
		return -1;
	}

	// �t�@�C���w�b�_�̓ǂݏo�� 

	fread(bmp_h, 1, 54, fbmp);
	if ((bmp_h[0x00] == 'B') && (bmp_h[0x01] == 'M')) {

		bpp = bmp_h[0x1c];
		if ( !(bpp==32 || bpp==24 || bpp==16) ) {
			printf("[!] This color type cannot display.\n");
			fclose(fbmp);
			return -2;
		}

		xsize = (bmp_h[0x13] << 8) | bmp_h[0x12];
		ysize = (bmp_h[0x17] << 8) | bmp_h[0x16];

		line = (xsize * bpp) / 8;
		if ((line % 4) != 0) line = ((line / 4) + 1) * 4;

	} else {
		printf("[!] This file is not bmp.\n");
		fclose(fbmp);
		return -3;
	}

	// BMP�摜�f�[�^�����[�h 

	printf("bmpfile : %s\n   %d x %d pix, %dbpp, %dbyte/line\n",bmpname,xsize,ysize,bpp,line);

	x_offs = 0;
	y_offs = 0;
	if (xsize+x_offs > window_xsize) width  = window_xsize-x_offs; else width  = xsize;
	if (ysize+y_offs > window_ysize) height = window_ysize-y_offs; else height = ysize;

	pline = pFrameBuffer + (y_offs * window_xsize);

	for(y=0 ; y<height ; y++) {
		fseek(fbmp, 54 + line*(ysize-(y+1)), SEEK_SET);		// �t�@�C���|�C���^���s�̐擪�ֈړ� 
		ppix = pline;										// �s�N�Z���|�C���^�����C���̐擪�ֈړ� 

		if (bpp == 32) {
			for(x=0 ; x<width ; x++) {
				fread(bmp_pixel, 1, 4, fbmp);
				*ppix++ = set_pixel(bmp_pixel[2], bmp_pixel[1], bmp_pixel[0]);
			}
		} else if(bpp == 24) {
			for(x=0 ; x<width ; x++) {
				fread(bmp_pixel, 1, 3, fbmp);
				*ppix++ = set_pixel(bmp_pixel[2], bmp_pixel[1], bmp_pixel[0]);
			}
		} else if(bpp == 16) {
			for(x=0 ; x<width ; x++) {
				fread(bmp_pixel, 1, 2, fbmp);
				*ppix++ = (bmp_pixel[1]<<8) | bmp_pixel[0];
			}
		}

		pline += window_xsize;
	}

	fclose(fbmp);

	return 0;
}


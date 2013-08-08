/**************************************************************************
	PROCYON �R���\�[�����C�u�����und_Lib�v (cineraria DE0 Edition)

		�v���~�e�B�u���x���O���t�B�b�N�h���C�o

 **************************************************************************/
#ifndef __nd_egl_lib_
#define __nd_egl_lib_

#include <stdio.h>
#include <alt_types.h>
#include <system.h>
#include <io.h>

//#define PIXELCOLOR_RGB565
#define PIXELCOLOR_RGB555		// MORGEN,AMETHYST,TURQUOISE,DE0
//#define PIXELCOLOR_BGR555		// TOURMALINE,GREENBERYL
//#define PISELCOLOR_YUV422		// ���m�N��


/***** �萔�E�}�N����` ***************************************************/

typedef int				nd_s32;				// �����t��32bit���� 
typedef short			nd_s16;				// �����t��16bit���� 
typedef char			nd_s8;				// �����t��8bit���� 
typedef unsigned long	nd_u32;				// ��������32bit���� 
typedef unsigned short	nd_u16;				// ��������16bit���� 
typedef unsigned char	nd_u8;				// ��������8bit���� 

#ifndef na_null
#ifdef NULL
#define na_null		NULL
#else
#define na_null		((void *)0)
#endif
#endif

#define na_VRAM_base		nd_GsEglDrawBuffer
//#define na_VRAM_size		(1024*480*2)
#define na_VRAM_size		(1024*768*2)
#define na_VRAM_linewidth	(11)
#define na_VRAM_linesize	(1<<na_VRAM_linewidth)

#define draw_base			(0)
//#define window_xsize		(640)
//#define window_ysize		(480)
#define window_xsize		(1024)
#define window_ysize		(768)
#define window_xmin			(0)
#define window_ymin			(0)
#define window_xmax			(window_xsize-1)
#define window_ymax			(window_ysize-1)

#ifdef PIXELCOLOR_RGB555
#define get_red(_x)			(((_x) & 0x7c00)>> 7)
#define get_green(_x)		(((_x) & 0x03e0)>> 2)
#define get_blue(_x)		(((_x) & 0x001f)<< 3)
#define set_pixel(_r,_g,_b)	( (((_r) & 0xf8)<<7)|(((_g) & 0xf8)<<2)|(((_b) & 0xf8)>>3) )
#endif
#ifdef PIXELCOLOR_BGR555
#define get_red(_x)			(((_x) & 0x001f)<< 3)
#define get_green(_x)		(((_x) & 0x03e0)>> 2)
#define get_blue(_x)		(((_x) & 0x7c00)>> 7)
#define set_pixel(_r,_g,_b)	( (((_r) & 0xf8)>>3)|(((_g) & 0xf8)<<2)|(((_b) & 0xf8)<<7) )
#endif
#ifdef PIXELCOLOR_RGB565
#define get_red(_x)			(((_x) & 0xf100)>> 8)
#define get_green(_x)		(((_x) & 0x07e0)>> 3)
#define get_blue(_x)		(((_x) & 0x001f)<< 3)
#define set_pixel(_r,_g,_b)	( (((_r) & 0xf8)<<8)|(((_g) & 0xfc)<<3)|(((_b) & 0xf8)>>3) )
#endif
#ifdef PISELCOLOR_YUV422
#define get_red(_x)			(0)
#define get_green(_x)		(((_x) & 0xff00)>> 8)
#define get_blue(_x)		(0)
#define set_pixel(_r,_g,_b)	( 0x80 | (((_g) & 0xff)<<8) )
#endif

#define nd_COLORBLACK		set_pixel(  0,  0,  0)
#define nd_COLORBLUE		set_pixel(  0,  0,255)
#define nd_COLORNAVY		set_pixel(  0,  0,128)
#define nd_COLORRED			set_pixel(255,  0,  0)
#define nd_COLORPURPLE		set_pixel(255,  0,255)
#define nd_COLORGREEN		set_pixel(  0,128,  0)
#define nd_COLORLIGHTGREEN	set_pixel(  0,255,  0)
#define nd_COLORSKY			set_pixel(  0,255,255)
#define nd_COLORYELLOW		set_pixel(255,255,  0)
#define nd_COLORWHITE		set_pixel(255,255,255)
#define nd_COLORGRAY		set_pixel(128,128,128)

#define nd_wait_hsync()
#define nd_wait_vsync()					nd_GsVgaWaitVsync()
#define nd_pset(_x,_y)					nd_GsEglPset((_x),(_y))
#define nd_box(_x1,_y1,_x2,_y2)			nd_GsEglBox((_x1),(_y1),(_x2),(_y2))
#define nd_boxfill(_x1,_y1,_x2,_y2)		nd_GsEglBoxfill((_x1),(_y1),(_x2),(_y2))
#define nd_circle(_x,_y,_r)				nd_GsEglCircle((_x),(_y),(_r))
#define nd_line(_x1,_y1,_x2,_y2)		nd_GsEglLine((_x1),(_y1),(_x2),(_y2))
#define nd_symbol(_x1,_y1,_s)			nd_GsEglPutstrFont((_x1),(_y1),(_s))
#define nd_color(_cc,_cb,_p)			nd_GsEglColor((_cc),(_cb),(_p))


/***** �\���̒�` *********************************************************/

#define np_VGAIO				(VGA_BASE)
#define vga_vsyncirq_enable		(1<<15)
#define vga_vsyncirq_disable	(0<<15)
#define vga_vsync_bitmask		(1<<14)
#define vga_vsyncirq_clear		(~(1<<14))
#define vga_vsyncflag_bitmask	(1<<13)
#define vga_ovrerr_bitmask		(1<<12)
#define vga_dither_enable		(1<<1)
#define vga_dither_disable		(0<<1)
#define vga_scan_enable			(1<<0)
#define vga_scan_disable		(0<<0)


/***** �v���g�^�C�v�錾 ***************************************************/

extern nd_u32 nd_GsEglDrawBuffer;

extern void nd_GsVgaVsync_isr(void);
extern void nd_GsVgaVsync_isrenable(void);
extern void nd_GsVgaVsync_isrdisable(void);
extern void nd_GsVgaScanOn(void);
extern void nd_GsVgaScanOff(void);
extern void nd_GsVgaSetBuffer(nd_u32);
extern void nd_GsVgaInit(void);
extern void nd_GsVgaWaitVsync(void);
extern nd_u32 nd_GsVgaVsync_getcount(void);
extern void nd_GsVgaVsync_setcount(nd_u32);

extern void nd_GsEglPage(nd_u32,nd_u32,nd_u32);
extern void nd_GsEglColor(nd_u32,nd_u32,nd_u32);
extern void nd_GsEglPset(nd_s32,nd_s32);
extern void nd_GsEglBoxfill(nd_s32,nd_s32,nd_s32,nd_s32);
extern void nd_GsEglBox(nd_s32,nd_s32,nd_s32,nd_s32);
extern void nd_GsEglCircle(nd_s32,nd_s32,nd_s32);
extern void nd_GsEglLine(nd_s32,nd_s32,nd_s32,nd_s32);
extern nd_s32 nd_GsEglPutcharFont(nd_s32,nd_s32,nd_u16);
extern void nd_GsEglPutstrFont(nd_s32,nd_s32,char *);
extern void nd_GsEglSetFont(void *,void *);
extern void nd_GsEglPutchar(nd_s32,nd_s32,char);
extern void nd_GsEglPutstr(nd_s32,nd_s32,char *);
extern void nd_GsEglPutdec(nd_s32,nd_s32,nd_s32);
extern void nd_GsEglPuthex2(nd_s32,nd_s32,nd_u32);
extern void nd_GsEglPuthex8(nd_s32,nd_s32,nd_u32);


#endif
/**************************************************************************/

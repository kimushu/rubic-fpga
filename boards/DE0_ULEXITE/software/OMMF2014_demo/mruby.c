#include "system.h"
#include <sys/alt_stdio.h>
#include <alt_types.h>
#include "UsbHLib/usbh_env.h"
#include <stdio.h>
#include <io.h>
#define ENABLE_RUBIC
#ifdef ENABLE_RUBIC
#include "../../../../mruby/include/mruby/rubic.h"
#endif

__attribute__((section(".image"))) const //alt_u16 bitmap[] = {
#include "rubicle_480x272.h"
#include "rubicle_ckw_bg_pale_480x272.h"
//#include "../freerun/akari.h"
//#include "rubic.h"
//#include "rubic2.h"
//};

extern int mirb_main(int argc, char *argv[]);

#ifdef ENABLE_RUBIC
static void open_rubic(rubic_state *state)
{
	state->enabled = 1;
	state->inst_base = (void *)RUBIC_R2N_NIOS2_BASE;
	state->ctl_base = (void **)RUBIC_R2N_CTRL_BASE;
	state->ctl_base[0] = SDRAM_BASE;
	puts("rubic: enabled");
}
#endif

void mruby_main(void *pdata)
{
	char argv0[] = "mirb";
	char argv1[] = "-v";
	char *argv[] = {
		argv0,
		//argv1,
	};
#ifdef ENABLE_RUBIC
	mrb_open_rubic = open_rubic;
#endif
	mirb_main(sizeof(argv) / sizeof(*argv), argv);
	mrbtest_main(sizeof(argv) / sizeof(*argv), argv);
/*
	IOWR(FRAME_READER_BASE, 3, 0);
	IOWR(FRAME_READER_BASE, 4, 0x7c0000);
	IOWR(FRAME_READER_BASE, 5, 480 * 272);
	IOWR(FRAME_READER_BASE, 6, 480 * 272);
	IOWR(FRAME_READER_BASE, 8, 480);
	IOWR(FRAME_READER_BASE, 9, 272);
	IOWR(FRAME_READER_BASE, 0, 1);
*/
	while(1) usleep(1000);
}

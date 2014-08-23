#include <stdio.h>
#include "includes.h"
#include <system.h>
#include <unistd.h>
#include "sys/alt_dev.h"
#include "priv/alt_file.h"
#include "console_writer.h"
#include <io.h>
#include <string.h>

#define DEFINE_TASK(name, id, prio, stk_size) \
	static OS_STK stk_##name[stk_size]; \
	static const INT16U id_##name = (id); \
	static const INT8U prio_##name = (prio);

#define CREATE_TASK(name, pdata) do { \
	extern void name##_main(void *); \
	OSTaskCreateExt( \
		/* task  */ name##_main, \
		/* p_arg */ (pdata), \
		/* ptos  */ (&stk_##name[sizeof(stk_##name)/sizeof(*stk_##name)-1]), \
		/* prio  */ (prio_##name), \
		/* id    */ (id_##name), \
		/* pbos  */ (&stk_##name[0]), \
		/* stk_size */ sizeof(stk_##name)/sizeof(*stk_##name), \
		/* pext  */ NULL, \
		/* opt   */ 0); \
	} while(0)

DEFINE_TASK(usbdrv, 1, 1, 1024);
DEFINE_TASK(mruby, 2, 2, 2048);

extern const console_writer_font font_table;

static console_writer_dev console_writer =
{
  {
    {0, 0},
    "/dev/console_writer",
    ((void *)0), /* open */
    ((void *)0), /* close */
    ((void *)0), /* read */
    console_writer_write_fd,
    ((void *)0), /* lseek */
    ((void *)0), /* fstat */
    ((void *)0), /* ioctl */
  },
  {
    0x007c0000,
    0x00700000 + (480 * 272 * 2) * 2,
    480 * 2,
    &font_table,
    { {480}, {272} },
  }
};

const char *to_hex(unsigned v)
{
	static char buf[9];
	static const char hex[] = "0123456789abcdef";
	buf[7] = hex[v & 15]; v >>= 4;
	buf[6] = hex[v & 15]; v >>= 4;
	buf[5] = hex[v & 15]; v >>= 4;
	buf[4] = hex[v & 15]; v >>= 4;
	buf[3] = hex[v & 15]; v >>= 4;
	buf[2] = hex[v & 15]; v >>= 4;
	buf[1] = hex[v & 15]; v >>= 4;
	buf[0] = hex[v & 15];
	return buf;
}

int main(void)
{/*
	volatile alt_u32 *reg = (volatile alt_u32 *)ULEXITE_LCD_BASE;
	*reg = 0xf800007b;
	while(1); //-*/
	if(1) {
		int sel = (IORD(PIO_SW_BASE, 0) >> 8) & 3;
		memset((void *)console_writer.state.back_base, 0xff, 480 * 272 * 2);
		if(sel > 2) sel = 2;
		console_writer.state.back_base = 0x700000 + (480 * 272 * 2) * sel;
	}
	IOWR(ULEXITE_LCD_BASE, 0, 0xf800007b);
	console_writer_init(&console_writer.state);
	alt_fd_list[STDOUT_FILENO].dev = &console_writer.dev;
	alt_fd_list[STDERR_FILENO].dev = &console_writer.dev;
	CREATE_TASK(mruby, NULL);
	CREATE_TASK(usbdrv, NULL);
	OSStart();//-*/
	//mruby_main(NULL);
	return 0;
}

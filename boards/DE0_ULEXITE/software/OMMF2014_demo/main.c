#include <stdio.h>
#include "includes.h"
#include <system.h>

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

int main(void)
{/*
	volatile alt_u32 *reg = (volatile alt_u32 *)ULEXITE_LCD_BASE;
	*reg = 0xf800007b;
	while(1); //-*/
	CREATE_TASK(mruby, NULL);
	CREATE_TASK(usbdrv, NULL);
	OSStart();//-*/
	//mruby_main(NULL);
	return 0;
}

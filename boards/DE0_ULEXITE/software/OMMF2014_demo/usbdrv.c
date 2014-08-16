#include <stdio.h>
#include "UsbHLib/usbh_env.h"
#include <io.h>
#include <system.h>
#include "sys/alt_dev.h"

static void on_keyboard(int key, int modifier)
{
	if(key != 0) IOWR(PIO_HEXLED_BASE, 0, ~key);
	if(key != 0) printf("key: %c\n", key);
}

void usbdrv_main(void *pdata)
{
	uh_init();
	uh_keyboard_attach_func(on_keyboard);
	while(1)
	{
		uh_update();
		ul_timer(1);
	}
}

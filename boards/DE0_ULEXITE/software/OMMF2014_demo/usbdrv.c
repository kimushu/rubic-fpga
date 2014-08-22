#include <stdio.h>
#include "UsbHLib/usbh_env.h"
#include <io.h>
#include <system.h>
#include <fcntl.h>
#include "sys/alt_dev.h"
#include "priv/alt_file.h"
#include "os/alt_sem.h"
#include "os/alt_flag.h"

#define USB_KEYBOARD_RX_RDY 0x01

static int usb_keyboard_read_fd(alt_fd* fd, char* ptr, int len);

typedef struct usb_keyboard_state_s
{
	int read;
	int write;
	ALT_SEM (lock)
	ALT_FLAG_GRP (events)
	char data[1024];
} usb_keyboard_state;

typedef struct usb_keyboard_dev_s
{
    alt_dev dev;
    usb_keyboard_state state;
} usb_keyboard_dev;

static usb_keyboard_dev usb_keyboard =
{
  {
    {0, 0},
    "/dev/usb_keyboard",
    ((void *)0), /* open */
    ((void *)0), /* close */
    usb_keyboard_read_fd,
    ((void *)0), /* write */
    ((void *)0), /* lseek */
    ((void *)0), /* fstat */
    ((void *)0), /* ioctl */
  },
  {
  }
};

static void on_keyboard(int key, int modifier, int down)
{/*
	static char buf[] = "key=XX,mod=XX";
	const static char hex[] = "0123456789abcdef";
	IOWR_32DIRECT(PIO_HEXLED_BASE, 0, ~key);
	buf[4] = hex[(key >> 4) & 15];
	buf[5] = hex[(key >> 0) & 15];
	buf[11] = hex[(modifier >> 4) & 15];
	buf[12] = hex[(modifier >> 0) & 15];
	puts(buf);//-*/
//	return;
	if(key && down)
	{
		int newwrite;
		//if(key == '\n') on_keyboard('\r', modifier, 1);
		ALT_SEM_PEND(usb_keyboard.state.lock, 0);
		newwrite = (usb_keyboard.state.write + 1) % sizeof(usb_keyboard.state.data);
		if(newwrite != usb_keyboard.state.read)
		{
			usb_keyboard.state.data[usb_keyboard.state.write] = key;
			usb_keyboard.state.write = newwrite;
		}
		putchar(key);
		ALT_SEM_POST(usb_keyboard.state.lock);
		ALT_FLAG_POST(usb_keyboard.state.events, USB_KEYBOARD_RX_RDY, OS_FLAG_SET);
	}
}

static int usb_keyboard_read(usb_keyboard_state *sp, char *ptr, int count, int flags)
{
	char *buffer = ptr;
	ALT_SEM_PEND(sp->lock, 0);
	while(count > 0)
	{
		if(sp->read != sp->write)
		{
			*ptr++ = sp->data[sp->read];
			sp->read = (sp->read + 1) % sizeof(sp->data);
			--count;
		}
		else if(flags & O_NONBLOCK)
		{
			break;
		}
		else if(ptr != buffer)
		{
			break;
		}
		else
		{
			// block
			ALT_SEM_POST(sp->lock);
			ALT_FLAG_PEND(sp->events, USB_KEYBOARD_RX_RDY, OS_FLAG_WAIT_SET_ANY + OS_FLAG_CONSUME, 0);
			ALT_SEM_PEND(sp->lock, 0);
		}
	}
	ALT_SEM_POST(sp->lock);

	if(buffer != ptr)
	{
		return ptr - buffer;
	}
	else if(flags & O_NONBLOCK)
	{
		return -EWOULDBLOCK;
	}
	else
	{
		return -EIO;
	}
}

static int usb_keyboard_read_fd(alt_fd* fd, char* ptr, int len)
{
	usb_keyboard_dev* dev = (usb_keyboard_dev *) fd->dev;

	return usb_keyboard_read(&dev->state, ptr, len, fd->fd_flags);
}

void usbdrv_main(void *pdata)
{
	ALT_FLAG_CREATE(&usb_keyboard.state.events, 0);
	ALT_SEM_CREATE(&usb_keyboard.state.lock, 1);
	alt_fd_list[STDIN_FILENO].dev = &usb_keyboard.dev;

	uh_init();
	uh_keyboard_attach_func(on_keyboard);
	while(1)
	{
		uh_update();
		ul_timer(1);
	}
}

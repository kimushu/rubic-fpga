/*
 * console_writer.c
 *
 *  Created on: 2014/08/15
 *      Author: kimu_shu
 */

#include <errno.h>
#include "console_writer.h"

int console_writer_write(console_writer_state *sp, const char * ptr, int count, int flags)
{
	return ENOTSUP;
}

int console_writer_write_fd(alt_fd* fd, const char* buffer, int space)
{
    console_writer_dev* dev = (console_writer_dev*) fd->dev;

    return console_writer_write(&dev->state, buffer, space, fd->fd_flags);
}

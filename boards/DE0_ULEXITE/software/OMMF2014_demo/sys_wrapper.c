/*
 * sys_wrapper.c
 *
 *  Created on: 2014/08/21
 *      Author: kimu_shu
 */

#include <stdint.h>
#include <unistd.h>
#include <system.h>
#include <io.h>

alt_u16 readw(void *address)
{
	if(((uintptr_t)address) & 1)
	{
		// Misaligned access
		return IORD_8DIRECT(address, 0) | (IORD_8DIRECT(address, 1) << 8);
	}
	else
	{
		// Aligned access
		return IORD_16DIRECT(address, 0);
	}
}

alt_u32 readl(void *address)
{
	if(((uintptr_t)address) & 3)
	{
		// Misaligned access
		register alt_u16 *ptr = (alt_u16 *)address;
		return readw(ptr) | (readw(ptr + 1) << 16);
	}
	else
	{
		// Aligned access
		return IORD_32DIRECT(address, 0);
	}
}

void writew(alt_u16 value, void *address)
{
	if(((uintptr_t)address) & 1)
	{
		// Misaligned access
		IOWR_8DIRECT(address, 0, value & 0xff);
		IOWR_8DIRECT(address, 1, value >> 8);
	}
	else
	{
		// Aligend access
		IOWR_16DIRECT(address, 0, value);
	}
}

void writel(alt_u32 value, void *address)
{
	if(((uintptr_t)address) & 3)
	{
		// Misaligned access
		register alt_u16 *ptr = (alt_u16 *)address;
		writew(value & 0xffff, ptr);
		writew(value >> 16, ptr + 1);
	}
	else
	{
		IOWR_32DIRECT(address, 0, value);
	}
}

void msleep(alt_u32 msecs)
{
	for(; msecs > 0; --msecs)
	{
		usleep(1000);
	}
}

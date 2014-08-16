/*
 * console_writer.h
 *
 *  Created on: 2014/08/15
 *      Author: kimu_shu
 */

#ifndef CONSOLE_WRITER_H_
#define CONSOLE_WRITER_H_

#include "sys/alt_dev.h"

#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */

extern int console_writer_write_fd (alt_fd* fd, const char* ptr, int len);

typedef struct console_writer_font_s
{
  unsigned int width;
  unsigned int height;
  unsigned char min_code;
  unsigned char max_code;
  const unsigned short *data[];
} console_writer_font;

typedef struct console_writer_state_s
{
  unsigned char *base;				// Memory base
  unsigned int line_bytes;			// Bytes per line
  unsigned int px_width;				// Width in pixels
  unsigned int px_height;			// Height in pixels
  unsigned int px_margin_left;		// Left margin in pixels
  unsigned int px_margin_top;		// Top margin in pixels
  unsigned int char_width;			// Width in characters
  unsigned int char_height;			// Lines (Height in characters)
  unsigned int start_line;			// Start line offset
  char *buffer;						// Character buffer
  const console_writer_font *font;	// Font table
} console_writer_state;

typedef struct console_writer_dev_s
{
    alt_dev dev;
    console_writer_state state;
} console_writer_dev;

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* CONSOLE_WRITER_H_ */

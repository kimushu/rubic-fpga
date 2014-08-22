/*
 * console_writer.h
 *
 *  Created on: 2014/08/15
 *      Author: kimu_shu
 */

#ifndef CONSOLE_WRITER_H_
#define CONSOLE_WRITER_H_

#include "sys/alt_dev.h"
#include "os/alt_sem.h"

#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */

extern int console_writer_write_fd(alt_fd *fd, const char *ptr, int len);

typedef struct console_writer_font_s
{
  unsigned int width;
  unsigned int height;
  unsigned char min_code;
  unsigned char max_code;
  const unsigned short *glyphs[];
} console_writer_font;

typedef struct console_writer_coord_s
{
  union {
    short x;
    short col;
  };
  union {
    short y;
    short row;
  };
} console_writer_coord;

typedef struct console_writer_size_s
{
  union {
    short width;
    short cols;
  };
  union {
    short height;
    short rows;
  };
} console_writer_size;

typedef struct console_writer_state_s
{
  unsigned int dest_base;			// Destination base address
  unsigned int back_base;			// Background base address
  unsigned int line_bytes;			// Bytes per pixel line
  const console_writer_font *font;	// Font table

  console_writer_size screen;		// Screen size
  console_writer_coord margin;		// Screen margin (left/top)

  console_writer_size size;			// Number of characters
  console_writer_coord next;		// Next position
  console_writer_coord cursor;		// Cursor position
  short start_row;					// Start line offset
  unsigned short color;				// Current color

  const unsigned short **buffer_glyph;	// Glyph pointer buffer
  unsigned short *buffer_color;		// Color buffer
  ALT_SEM (lock)
} console_writer_state;

typedef struct console_writer_dev_s
{
    alt_dev dev;
    console_writer_state state;
} console_writer_dev;

extern int console_writer_init(console_writer_state *sp);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* CONSOLE_WRITER_H_ */

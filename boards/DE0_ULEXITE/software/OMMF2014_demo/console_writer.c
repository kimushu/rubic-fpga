/*
 * console_writer.c
 *
 *  Created on: 2014/08/15
 *      Author: kimu_shu
 */

#include <errno.h>
#include "console_writer.h"

#define CURSOR_HEIGHT 3
#define RING_INC(val, period) (((val) == ((period) - 1)) ? 0 : ((val) + 1)
#define RING_DEC(val, period) (((val) == 0) ? ((period) - 1) : ((val) - 1))

void console_writer_clear(console_writer_state *sp)
{
	memcpy(sp->base, sp->background_base, sp->line_bytes * sp->screen.height);
	memset(sp->buffer_glyph, 0, sizeof(*sp->buffer_glyph) * sp->size.cols * sp->size.rows);
	sp->start_row = 0;
	sp->current.col = 0;
	sp->current.row = 0;
	sp->cursor.col = -1;
	sp->cursor.row = -1;
}

static console_writer_coord console_writer_c2s(console_writer_state *sp, console_writer_coord cpos)
{
	cpos.row -= sp->start_row;
	while(cpos.row < 0) cpos.row += sp->size.rows;
	cpos.y = cpos.row * sp->font->height + sp->margin.y;
	cpos.x = cpos.col * sp->font->width + sp->margin.x;
	return cpos;
}

static void console_writer_draw_glyph(console_writer_state *sp, console_writer_coord cpos)
{
	static const unsigned short null_glyph[16] = {0};
	int cx;
	int cy;
	unsigned short *dest;
	unsigned short *back;
	unsigned short *glyph;
	unsigned short line;
	console_writer_coord spos;

	if(cpos.col < 0 || cpos.row < 0) {
		return;
	}

	if(cpos == sp->cursor) {
		// Cursor will be invalidated
		sp->cursor.col = -1;
		sp->cursor.row = -1;
	}

	glyph = sp->buffer_glyph[cpos.row * sp->size.cols + cpos.col];
	if(!glyph) {
		glyph = null_glyph;
	}

	spos = console_writer_c2s(sp, cpos);

	for(cy = sp->font->height; cy > 0; --cy, ++spos.y, ++glyph) {
		dest = (unsigned short *)(sp->dest_base + sp->line_bytes * spos.y);
		dest += spos.x;
		back = (unsigned short *)(sp->back_base + sp->line_bytes * spos.y);
		back += spos.x;
		line = *glyph;
		for(cx = sp->font->width; cx > 0; --cx, ++dest, ++back, line <<= 1) {
			*dest = (line & 0x8000) ? sp->color : *back;
		}
	}
}

static void console_writer_draw_cursor(console_writer_state *sp)
{
	int cx;
	int cy;
	unsigned short *dest;
	console_writer_coord spos;

	if(sp->cursor.col < 0 || sp->cursor.row < 0) {
		return;
	}

	spos = console_writer_c2s(sp, cpos);
	spos.y += sp->font->height - CURSOR_HEIGHT;

	for(cy = CURSOR_HEIGHT; cy > 0; --cy, ++spos.y) {
		dest = (unsigned short *)(sp->dest_base + sp->line_bytes * spos.y);
		dest += spos.x;
		for(cx = sp->font->width; cx > 0; --cx, ++dest) {
			*dest ^= 0xffff;
		}
	}
}

static void console_writer_refresh(console_writer_state *sp)
{
	unsigned int row, col;
	for(row = 0; row < sp->rows; ++row)
	{
		for(col = 0; col < sp->cols; ++col)
		{
			console_writer_draw_glyph(sp, row, col);
		}
	}
}

static int console_writer_write_char(console_writer_state *sp, unsigned char ch)
{
	unsigned int offset;

	switch(ch)
	{
	case '\b':
		if(sp->next.col == 0) {
			if(sp->next.row == sp->start_row) {
				// Cannot back -> Do nothing
				return 0;
			}
			sp->next.row = RING_DEC(sp->next.row, sp->size.rows);
		}
		sp->next.col = RING_DEC(sp->next.col, sp->size.cols);
		return 0;
	case '\r':
		sp->next.col = 0;
		return 0;
	case '\n':
	linefield:
		sp->next.row = RING_INC(sp->next.row, sp->size.rows);
		if(sp->next.row == sp->start_row) {
			sp->start_row = RING_INC(sp->start_row, sp->size.rows);
			console_writer_refresh(sp);
		}
		return 0;
	}
	if(ch < sp->font->min_code || ch > sp->font->max_code) {
		// Not defined in current font table
		return ENOENT;
	}

	offset = sp->next.col + sp->next.row * sp->size.cols;
	sp->buffer_glyph[offset] = sp->font->data[ch - sp->font->min_code];
	sp->buffer_color[offset] = sp->color;
	console_writer_draw_glyph(sp, sp->next);
	sp->next.col = RING_INC(sp->next.col, sp->size.cols);
	if(sp->next.col == 0) {
		goto linefield;
	}
}

int console_writer_write(console_writer_state *sp, const char *ptr, int count, int flags)
{
	int result;

	for(; count > 0; --count)
	{
		result = console_writer_write_char(sp, *ptr++);
		if(result != 0) return result;
	}

	console_writer_draw_cursor(sp);
	sp->cursor = sp->next;
	console_writer_draw_cursor(sp);

	return 0;
}

int console_writer_write_fd(alt_fd *fd, const char *buffer, int space)
{
    console_writer_dev* dev = (console_writer_dev *) fd->dev;

    return console_writer_write(&dev->state, buffer, space, fd->fd_flags);
}

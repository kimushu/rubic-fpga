#ifndef _TERMIOS_H
#define _TERMIOS_H

// Patch for <sys/termios.h>
#include <sys/termios.h>
int tcgetattr(int fd, struct termios *termios_p);

int tcsetattr(int fd, int optional_actions,
              const struct termios *termios_p);

// Patch for <sys/ioctl.h>
#include <sys/ioctl.h>
struct winsize
{
	unsigned short ws_row;
	unsigned short ws_col;
	unsigned short ws_xpixel;
	unsigned short ws_ypixel;
};
#define TCGETS 0x5401
#define TCSETS 0x5402
#define TCSETSW 0x5403
#define TCSETSF 0x5404
#define TIOCGWINSZ 0x5413

#endif	/* !__TERMIOS_H */

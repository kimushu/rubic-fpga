#include <termios.h>
#include <sys/alt_dev.h>
#include <errno.h>

// termios patch
int tcgetattr(int fd, struct termios *termios_p)
{
  if(fd < 0 || fd >= ALT_MAX_FD)
  {
    return -ENOTTY;
  }
  return TCGETS;
}

int tcsetattr(int fd, int optional_actions,
              const struct termios *termios_p)
{
}


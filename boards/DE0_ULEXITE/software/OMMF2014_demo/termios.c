#include <termios.h>
#include <sys/alt_dev.h>
#include <priv/alt_file.h>
#include <errno.h>
#include <sys/alt_errno.h>

// termios patch
int tcgetattr(int fd, struct termios *termios_p)
{
  alt_dev *dev;
  int result = ENOTTY;
  if(0 <= fd && fd < ALT_MAX_FD)
  {
    dev = alt_fd_list[fd].dev;
    if(dev && dev->ioctl)
    {
      result = (*dev->ioctl)(&alt_fd_list[fd], TCGETS, termios_p);
    }
  }
  if(result == 0) return 0;
  ALT_ERRNO = result;
  return -1;
}

int tcsetattr(int fd, int optional_actions,
              const struct termios *termios_p)
{
  alt_dev *dev;
  int request;
  int result = ENOTTY;
  if(0 <= fd && fd < ALT_MAX_FD)
  {
    dev = alt_fd_list[fd].dev;
    if(dev && dev->ioctl)
    {
      switch(optional_actions)
      {
      case TCSADRAIN:
        request = TCSETSW;
        break;
      case TCSAFLUSH:
        request = TCSETSF;
        break;
      default:
        request = TCSETS;
        break;
      }
      result = (*dev->ioctl)(&alt_fd_list[fd], request, (void *)termios_p);
    }
  }
  if(result == 0) return 0;
  ALT_ERRNO = result;
  return -1;
}


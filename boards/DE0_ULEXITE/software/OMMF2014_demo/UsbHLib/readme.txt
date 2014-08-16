USB Host C Library
 release 2013/10/31 version 0.659
  - PS3 Game Controller tested
  - PS/PS2 Game Converter tested

USB Host C Library
 release 2013/11/08 version 0.667
  - Error handling during hub port device enumeration.
    After the port reset, "CurrentConnectStatus" changes
    from "A device is present on this port" to "No device is present"
    even though the device is still attached.

USB Host C Library
 release 2014/03/07 version 0.670
  - GetDescriptor(STRING) bugfix
    initialize wLength=4 before getting iProduct string.

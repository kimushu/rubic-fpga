#include "console_writer.h"
static const unsigned short glyph_21[] = {0x0000,0x0018,0x0018,0x0018,0x0018,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0000,0x0000,0x0010,0x0010,0x0000};
static const unsigned short glyph_22[] = {0x006c,0x0024,0x0024,0x0048,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000};
static const unsigned short glyph_23[] = {0x0000,0x0012,0x0012,0x0012,0x007f,0x0024,0x0024,0x0024,0x0024,0x0024,0x00fe,0x0048,0x0048,0x0048,0x0048,0x0000};
static const unsigned short glyph_24[] = {0x0010,0x0038,0x0054,0x0092,0x0092,0x0090,0x0050,0x0038,0x0014,0x0012,0x0092,0x0092,0x0054,0x0038,0x0010,0x0010};
static const unsigned short glyph_25[] = {0x0001,0x0061,0x0092,0x0092,0x0094,0x0094,0x0068,0x0008,0x0010,0x0016,0x0029,0x0029,0x0049,0x0049,0x0086,0x0080};
static const unsigned short glyph_26[] = {0x0000,0x0038,0x0044,0x0044,0x0044,0x0028,0x0010,0x0030,0x004a,0x008a,0x0084,0x0084,0x004a,0x0031,0x0000,0x0000};
static const unsigned short glyph_27[] = {0x0060,0x0020,0x0020,0x0040,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000};
static const unsigned short glyph_28[] = {0x0000,0x0002,0x0004,0x0008,0x0008,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0008,0x0008,0x0004,0x0002};
static const unsigned short glyph_29[] = {0x0000,0x0040,0x0020,0x0010,0x0010,0x0008,0x0008,0x0008,0x0008,0x0008,0x0008,0x0008,0x0010,0x0010,0x0020,0x0040};
static const unsigned short glyph_2a[] = {0x0000,0x0000,0x0000,0x0000,0x0010,0x0092,0x0054,0x0038,0x0054,0x0092,0x0010,0x0000,0x0000,0x0000,0x0000,0x0000};
static const unsigned short glyph_2b[] = {0x0000,0x0000,0x0000,0x0010,0x0010,0x0010,0x0010,0x00fe,0x0010,0x0010,0x0010,0x0010,0x0000,0x0000,0x0000,0x0000};
static const unsigned short glyph_2c[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0060,0x0020,0x0020,0x0040};
static const unsigned short glyph_2d[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x00fe,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000};
static const unsigned short glyph_2e[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0060,0x0060,0x0000,0x0000};
static const unsigned short glyph_2f[] = {0x0000,0x0002,0x0002,0x0004,0x0004,0x0008,0x0008,0x0010,0x0010,0x0020,0x0020,0x0040,0x0040,0x0080,0x0080,0x0000};
static const unsigned short glyph_30[] = {0x0000,0x0018,0x0024,0x0024,0x0042,0x0042,0x0042,0x0042,0x0042,0x0042,0x0042,0x0024,0x0024,0x0018,0x0000,0x0000};
static const unsigned short glyph_31[] = {0x0000,0x0010,0x0010,0x0030,0x0050,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0000,0x0000};
static const unsigned short glyph_32[] = {0x0000,0x0018,0x0024,0x0042,0x0042,0x0002,0x0004,0x0008,0x0010,0x0020,0x0020,0x0040,0x0040,0x007e,0x0000,0x0000};
static const unsigned short glyph_33[] = {0x0000,0x0038,0x0044,0x0082,0x0082,0x0002,0x0004,0x0038,0x0004,0x0002,0x0082,0x0082,0x0044,0x0038,0x0000,0x0000};
static const unsigned short glyph_34[] = {0x0000,0x0008,0x0018,0x0018,0x0028,0x0028,0x0048,0x0048,0x0088,0x00fe,0x0008,0x0008,0x0008,0x0008,0x0000,0x0000};
static const unsigned short glyph_35[] = {0x0000,0x007c,0x0040,0x0040,0x0040,0x00b8,0x00c4,0x0082,0x0002,0x0002,0x0082,0x0082,0x0044,0x0038,0x0000,0x0000};
static const unsigned short glyph_36[] = {0x0000,0x0038,0x0044,0x0040,0x0080,0x0080,0x00b8,0x00c4,0x0082,0x0082,0x0082,0x0082,0x0044,0x0038,0x0000,0x0000};
static const unsigned short glyph_37[] = {0x0000,0x00fe,0x0002,0x0004,0x0004,0x0008,0x0008,0x0008,0x0008,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0000};
static const unsigned short glyph_38[] = {0x0000,0x0038,0x0044,0x0082,0x0082,0x0082,0x0044,0x0038,0x0044,0x0082,0x0082,0x0082,0x0044,0x0038,0x0000,0x0000};
static const unsigned short glyph_39[] = {0x0000,0x0038,0x0044,0x0082,0x0082,0x0082,0x0082,0x0046,0x003a,0x0002,0x0002,0x0082,0x0044,0x0038,0x0000,0x0000};
static const unsigned short glyph_3a[] = {0x0000,0x0000,0x0000,0x0000,0x0018,0x0018,0x0000,0x0000,0x0000,0x0000,0x0000,0x0018,0x0018,0x0000,0x0000,0x0000};
static const unsigned short glyph_3b[] = {0x0000,0x0000,0x0000,0x0000,0x0018,0x0018,0x0000,0x0000,0x0000,0x0000,0x0018,0x0008,0x0008,0x0010,0x0000,0x0000};
static const unsigned short glyph_3c[] = {0x0000,0x0000,0x0000,0x0002,0x0004,0x0008,0x0010,0x0020,0x0020,0x0010,0x0008,0x0004,0x0002,0x0000,0x0000,0x0000};
static const unsigned short glyph_3d[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x00fe,0x0000,0x0000,0x0000,0x00fe,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000};
static const unsigned short glyph_3e[] = {0x0000,0x0000,0x0000,0x0040,0x0020,0x0010,0x0008,0x0004,0x0004,0x0008,0x0010,0x0020,0x0040,0x0000,0x0000,0x0000};
static const unsigned short glyph_3f[] = {0x0000,0x0038,0x0044,0x0082,0x0082,0x0082,0x0004,0x0008,0x0008,0x0010,0x0010,0x0000,0x0000,0x0010,0x0010,0x0000};
static const unsigned short glyph_40[] = {0x0000,0x0018,0x0024,0x0042,0x005a,0x00b5,0x00a5,0x00a5,0x00a5,0x009a,0x0040,0x0040,0x0022,0x001c,0x0000,0x0000};
static const unsigned short glyph_41[] = {0x0000,0x0010,0x0010,0x0028,0x0028,0x0028,0x0044,0x0044,0x0044,0x007c,0x0082,0x0082,0x0082,0x0082,0x0000,0x0000};
static const unsigned short glyph_42[] = {0x0000,0x00f0,0x0088,0x0084,0x0084,0x0084,0x0088,0x00f8,0x0084,0x0082,0x0082,0x0082,0x0084,0x00f8,0x0000,0x0000};
static const unsigned short glyph_43[] = {0x0000,0x0038,0x0044,0x0042,0x0080,0x0080,0x0080,0x0080,0x0080,0x0080,0x0080,0x0042,0x0044,0x0038,0x0000,0x0000};
static const unsigned short glyph_44[] = {0x0000,0x00f0,0x0088,0x0084,0x0084,0x0082,0x0082,0x0082,0x0082,0x0082,0x0084,0x0084,0x0088,0x00f0,0x0000,0x0000};
static const unsigned short glyph_45[] = {0x0000,0x00fe,0x0080,0x0080,0x0080,0x0080,0x0080,0x00fc,0x0080,0x0080,0x0080,0x0080,0x0080,0x00fe,0x0000,0x0000};
static const unsigned short glyph_46[] = {0x0000,0x00fe,0x0080,0x0080,0x0080,0x0080,0x0080,0x00fc,0x0080,0x0080,0x0080,0x0080,0x0080,0x0080,0x0000,0x0000};
static const unsigned short glyph_47[] = {0x0000,0x0018,0x0024,0x0042,0x0040,0x0080,0x0080,0x008e,0x0082,0x0082,0x0082,0x0042,0x0066,0x001a,0x0000,0x0000};
static const unsigned short glyph_48[] = {0x0000,0x0082,0x0082,0x0082,0x0082,0x0082,0x0082,0x00fe,0x0082,0x0082,0x0082,0x0082,0x0082,0x0082,0x0000,0x0000};
static const unsigned short glyph_49[] = {0x0000,0x0038,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0038,0x0000,0x0000};
static const unsigned short glyph_4a[] = {0x0000,0x0002,0x0002,0x0002,0x0002,0x0002,0x0002,0x0002,0x0002,0x0002,0x0002,0x0042,0x0024,0x0018,0x0000,0x0000};
static const unsigned short glyph_4b[] = {0x0000,0x0042,0x0042,0x0044,0x0044,0x0048,0x0058,0x0068,0x0064,0x0044,0x0042,0x0042,0x0041,0x0041,0x0000,0x0000};
static const unsigned short glyph_4c[] = {0x0000,0x0040,0x0040,0x0040,0x0040,0x0040,0x0040,0x0040,0x0040,0x0040,0x0040,0x0040,0x0040,0x007e,0x0000,0x0000};
static const unsigned short glyph_4d[] = {0x0000,0x0082,0x0082,0x00c6,0x00c6,0x00c6,0x00aa,0x00aa,0x00aa,0x0092,0x0092,0x0092,0x0092,0x0082,0x0000,0x0000};
static const unsigned short glyph_4e[] = {0x0000,0x0082,0x00c2,0x00c2,0x00a2,0x00a2,0x0092,0x0092,0x0092,0x008a,0x008a,0x0086,0x0086,0x0082,0x0000,0x0000};
static const unsigned short glyph_4f[] = {0x0000,0x0038,0x0044,0x0044,0x0082,0x0082,0x0082,0x0082,0x0082,0x0082,0x0082,0x0044,0x0044,0x0038,0x0000,0x0000};
static const unsigned short glyph_50[] = {0x0000,0x00f8,0x0084,0x0082,0x0082,0x0082,0x0084,0x00f8,0x0080,0x0080,0x0080,0x0080,0x0080,0x0080,0x0000,0x0000};
static const unsigned short glyph_51[] = {0x0000,0x0038,0x0044,0x0044,0x0082,0x0082,0x0082,0x0082,0x0082,0x0082,0x00ba,0x0044,0x0044,0x0038,0x0008,0x0006};
static const unsigned short glyph_52[] = {0x0000,0x00f8,0x0084,0x0082,0x0082,0x0082,0x0084,0x00f8,0x0088,0x0084,0x0084,0x0084,0x0082,0x0082,0x0000,0x0000};
static const unsigned short glyph_53[] = {0x0000,0x0038,0x0044,0x0082,0x0082,0x0080,0x0060,0x0018,0x0004,0x0002,0x0082,0x0082,0x0044,0x0038,0x0000,0x0000};
static const unsigned short glyph_54[] = {0x0000,0x00fe,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0000,0x0000};
static const unsigned short glyph_55[] = {0x0000,0x0082,0x0082,0x0082,0x0082,0x0082,0x0082,0x0082,0x0082,0x0082,0x0082,0x0082,0x0044,0x0038,0x0000,0x0000};
static const unsigned short glyph_56[] = {0x0000,0x0082,0x0082,0x0082,0x0082,0x0044,0x0044,0x0044,0x0028,0x0028,0x0028,0x0010,0x0010,0x0010,0x0000,0x0000};
static const unsigned short glyph_57[] = {0x0000,0x0092,0x0092,0x0092,0x0092,0x0092,0x0092,0x00aa,0x00aa,0x006c,0x0044,0x0044,0x0044,0x0044,0x0000,0x0000};
static const unsigned short glyph_58[] = {0x0000,0x0082,0x0044,0x0044,0x0028,0x0028,0x0010,0x0028,0x0028,0x0028,0x0044,0x0044,0x0082,0x0082,0x0000,0x0000};
static const unsigned short glyph_59[] = {0x0000,0x0082,0x0082,0x0044,0x0044,0x0044,0x0028,0x0028,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0000,0x0000};
static const unsigned short glyph_5a[] = {0x0000,0x00fe,0x0004,0x0004,0x0008,0x0008,0x0010,0x0010,0x0020,0x0020,0x0040,0x0040,0x0080,0x00fe,0x0000,0x0000};
static const unsigned short glyph_5b[] = {0x001e,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x001e};
static const unsigned short glyph_5c[] = {0x0000,0x0080,0x0080,0x0040,0x0040,0x0020,0x0020,0x0010,0x0010,0x0008,0x0008,0x0004,0x0004,0x0002,0x0002,0x0000};
static const unsigned short glyph_5d[] = {0x00f0,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x00f0};
static const unsigned short glyph_5e[] = {0x0010,0x0028,0x0044,0x0082,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000};
static const unsigned short glyph_5f[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x00fe,0x0000};
static const unsigned short glyph_60[] = {0x0030,0x0020,0x0020,0x0010,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000};
static const unsigned short glyph_61[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x003c,0x0042,0x0002,0x003e,0x0042,0x0082,0x0082,0x0086,0x007a,0x0000,0x0000};
static const unsigned short glyph_62[] = {0x0000,0x0080,0x0080,0x0080,0x0080,0x00b8,0x00c4,0x0082,0x0082,0x0082,0x0082,0x0082,0x00c4,0x00b8,0x0000,0x0000};
static const unsigned short glyph_63[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x0038,0x0044,0x0082,0x0080,0x0080,0x0080,0x0082,0x0044,0x0038,0x0000,0x0000};
static const unsigned short glyph_64[] = {0x0000,0x0002,0x0002,0x0002,0x0002,0x003a,0x0046,0x0082,0x0082,0x0082,0x0082,0x0082,0x0046,0x003a,0x0000,0x0000};
static const unsigned short glyph_65[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x0038,0x0044,0x0082,0x0082,0x00fe,0x0080,0x0082,0x0044,0x0038,0x0000,0x0000};
static const unsigned short glyph_66[] = {0x0000,0x000c,0x0010,0x0010,0x0010,0x007c,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0000,0x0000};
static const unsigned short glyph_67[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x003b,0x0044,0x0044,0x0044,0x0038,0x0040,0x0078,0x0084,0x0082,0x0082,0x007c};
static const unsigned short glyph_68[] = {0x0000,0x0040,0x0040,0x0040,0x0040,0x005c,0x0062,0x0042,0x0042,0x0042,0x0042,0x0042,0x0042,0x0042,0x0000,0x0000};
static const unsigned short glyph_69[] = {0x0000,0x0010,0x0010,0x0000,0x0000,0x0030,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0000,0x0000};
static const unsigned short glyph_6a[] = {0x0000,0x0008,0x0008,0x0000,0x0000,0x0018,0x0008,0x0008,0x0008,0x0008,0x0008,0x0008,0x0008,0x0008,0x0010,0x0060};
static const unsigned short glyph_6b[] = {0x0000,0x0040,0x0040,0x0040,0x0040,0x0042,0x0044,0x0048,0x0050,0x0068,0x0044,0x0044,0x0042,0x0042,0x0000,0x0000};
static const unsigned short glyph_6c[] = {0x0000,0x0030,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0000,0x0000};
static const unsigned short glyph_6d[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x00ec,0x0092,0x0092,0x0092,0x0092,0x0092,0x0092,0x0092,0x0092,0x0000,0x0000};
static const unsigned short glyph_6e[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x005c,0x0062,0x0042,0x0042,0x0042,0x0042,0x0042,0x0042,0x0042,0x0000,0x0000};
static const unsigned short glyph_6f[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x0038,0x0044,0x0082,0x0082,0x0082,0x0082,0x0082,0x0044,0x0038,0x0000,0x0000};
static const unsigned short glyph_70[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x00b8,0x00c4,0x0082,0x0082,0x0082,0x0082,0x00c4,0x00b8,0x0080,0x0080,0x0080};
static const unsigned short glyph_71[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x003a,0x0046,0x0082,0x0082,0x0082,0x0082,0x0046,0x003a,0x0002,0x0002,0x0002};
static const unsigned short glyph_72[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x002c,0x0030,0x0020,0x0020,0x0020,0x0020,0x0020,0x0020,0x0020,0x0000,0x0000};
static const unsigned short glyph_73[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x003c,0x0042,0x0040,0x0060,0x0018,0x0006,0x0002,0x0042,0x003c,0x0000,0x0000};
static const unsigned short glyph_74[] = {0x0000,0x0000,0x0010,0x0010,0x0010,0x007c,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x000c,0x0000,0x0000};
static const unsigned short glyph_75[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x0042,0x0042,0x0042,0x0042,0x0042,0x0042,0x0042,0x0046,0x003a,0x0000,0x0000};
static const unsigned short glyph_76[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x0082,0x0082,0x0082,0x0044,0x0044,0x0028,0x0028,0x0010,0x0010,0x0000,0x0000};
static const unsigned short glyph_77[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x0092,0x0092,0x0092,0x0092,0x00aa,0x00aa,0x0044,0x0044,0x0044,0x0000,0x0000};
static const unsigned short glyph_78[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x0082,0x0044,0x0028,0x0028,0x0010,0x0028,0x0028,0x0044,0x0082,0x0000,0x0000};
static const unsigned short glyph_79[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x0082,0x0082,0x0044,0x0044,0x0028,0x0028,0x0018,0x0010,0x0010,0x0020,0x00c0};
static const unsigned short glyph_7a[] = {0x0000,0x0000,0x0000,0x0000,0x0000,0x007e,0x0004,0x0008,0x0008,0x0010,0x0010,0x0020,0x0040,0x00fe,0x0000,0x0000};
static const unsigned short glyph_7b[] = {0x0004,0x0008,0x0008,0x0008,0x0008,0x0008,0x0008,0x0010,0x0008,0x0008,0x0008,0x0008,0x0008,0x0008,0x0008,0x0004};
static const unsigned short glyph_7c[] = {0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010,0x0010};
static const unsigned short glyph_7d[] = {0x0040,0x0020,0x0020,0x0020,0x0020,0x0020,0x0020,0x0010,0x0020,0x0020,0x0020,0x0020,0x0020,0x0020,0x0020,0x0040};
static const unsigned short glyph_7e[] = {0x0000,0x0000,0x0000,0x0060,0x0092,0x000c,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000};
const console_writer_font font_table = {
  .width = 8,
  .height = 16,
  .min_code = 0x20,
  .max_code = 0x7e,
  .data = {
    0, // 20
    glyph_21,
    glyph_22,
    glyph_23,
    glyph_24,
    glyph_25,
    glyph_26,
    glyph_27,
    glyph_28,
    glyph_29,
    glyph_2a,
    glyph_2b,
    glyph_2c,
    glyph_2d,
    glyph_2e,
    glyph_2f,
    glyph_30,
    glyph_31,
    glyph_32,
    glyph_33,
    glyph_34,
    glyph_35,
    glyph_36,
    glyph_37,
    glyph_38,
    glyph_39,
    glyph_3a,
    glyph_3b,
    glyph_3c,
    glyph_3d,
    glyph_3e,
    glyph_3f,
    glyph_40,
    glyph_41,
    glyph_42,
    glyph_43,
    glyph_44,
    glyph_45,
    glyph_46,
    glyph_47,
    glyph_48,
    glyph_49,
    glyph_4a,
    glyph_4b,
    glyph_4c,
    glyph_4d,
    glyph_4e,
    glyph_4f,
    glyph_50,
    glyph_51,
    glyph_52,
    glyph_53,
    glyph_54,
    glyph_55,
    glyph_56,
    glyph_57,
    glyph_58,
    glyph_59,
    glyph_5a,
    glyph_5b,
    glyph_5c,
    glyph_5d,
    glyph_5e,
    glyph_5f,
    glyph_60,
    glyph_61,
    glyph_62,
    glyph_63,
    glyph_64,
    glyph_65,
    glyph_66,
    glyph_67,
    glyph_68,
    glyph_69,
    glyph_6a,
    glyph_6b,
    glyph_6c,
    glyph_6d,
    glyph_6e,
    glyph_6f,
    glyph_70,
    glyph_71,
    glyph_72,
    glyph_73,
    glyph_74,
    glyph_75,
    glyph_76,
    glyph_77,
    glyph_78,
    glyph_79,
    glyph_7a,
    glyph_7b,
    glyph_7c,
    glyph_7d,
    glyph_7e,
  },
};
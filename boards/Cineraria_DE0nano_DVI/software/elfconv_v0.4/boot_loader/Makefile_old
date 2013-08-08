# +----------------------------------------
# | ユーザー設定部分
# |

SOPC_BULDER_V11 = 1					# SoPC Builder v11.0以降の場合にはこの宣言を有効にする 

PROGRAM_BASE_ADDRESS = 0x60000		# ロードプログラム格納アドレス(EPCS ROM内のアドレス)

EPCS_REGISTER_OFFSET = 0x400		# CycloneIIIでは0x400、CycloneI/IIでは0x200
EPCS_BASE_ADDRESS    = 0x0f000000	# EPCSペリフェラル先頭アドレス 
EPCS_END_ADDRESS     = 0x0f0003ff   # CycloneIIIでは1024バイト、CycloneI/IIでは512バイトのエリア 

SYSLED_7SEG_ADDRESS  = 0x10000220	# メッセージ表示7セグメントLEDのレジスタ(Cireraria)
#SYSLED_ADDRESS       = 0x01000060	# ステータス表示用LEDのレジスタ(Sardonyx) 

# +----------------------------------------


# +----------------------------------------
# | Project Files
# |

PROGRAM_NAME = boot_loader
ifdef SOPC_BULDER_V11
BOOTROM_NAME = epcs_controller_boot_rom_synth.hex		# SoPC builder v11.0以降 
else
BOOTROM_NAME = epcs_controller_boot_rom.hex				# SoPC Builder v9.1 
endif

GNU_TOOLS_PREFIX = nios2-elf
AS = $(GNU_TOOLS_PREFIX)-as
LD = $(GNU_TOOLS_PREFIX)-ld
OC = $(GNU_TOOLS_PREFIX)-objcopy
NM = $(GNU_TOOLS_PREFIX)-nm
OD = $(GNU_TOOLS_PREFIX)-objdump
E = echo \\\# `date +%Y.%m.%d.%H:%M:%S` ---

ifdef SYSLED_7SEG_ADDRESS
LED_DEFSYM = --defsym REG_7SEG_BASE=$(SYSLED_7SEG_ADDRESS)
else
ifdef SYSLED_ADDRESS
LED_DEFSYM = --defsym REG_LED_BASE=$(SYSLED_ADDRESS)
else
LED_DEFSYM = 
endif
endif


ASFLAGS = \
		--defsym EPCS_PROGRAM_BASE=$(PROGRAM_BASE_ADDRESS) \
		--defsym EPCS_CONTROLLER_BASE=$(EPCS_BASE_ADDRESS) \
		--defsym EPCS_REG_OFFSET=$(EPCS_REGISTER_OFFSET) \
		$(LED_DEFSYM) \

LFLAGS = \
		-e _start \
		-Ttext=$(EPCS_BASE_ADDRESS) \

CONVFLAGS = \
		--base=$(EPCS_BASE_ADDRESS) \
		--end=$(EPCS_END_ADDRESS) \
		--record=4 \
		--width=32 \

OBJECTS = \
		$(PROGRAM_NAME).o \



# +----------------------------------------
# | Rules
# |

$(BOOTROM_NAME) : $(PROGRAM_NAME).elf
	@$(E) Converting $(PROGRAM_NAME) to BootROM-Hex
	@elf2hex --input=$< --output=$@ $(CONVFLAGS)

$(PROGRAM_NAME).elf : $(OBJECTS)
	@$(E) Linking $@
	@$(LD) $(OBJECTS) $(LFLAGS) -o $(PROGRAM_NAME).elf 

$(PROGRAM_NAME).o : $(PROGRAM_NAME).s
	@$(AS) $(ASFLAGS) $< -o $@



hex :
	@$(E) Converting $(PROGRAM_NAME) to IntelHex
	@$(OC) -O ihex $(PROGRAM_NAME).elf $(PROGRAM_NAME).hex

srec :
	@$(E) Converting $(PROGRAM_NAME) to S-Record
	@$(OC) -O srec $(PROGRAM_NAME).elf $(PROGRAM_NAME).srec

bin :
	@$(E) Converting $(PROGRAM_NAME) to Binary
	@$(OC) -O binary $(PROGRAM_NAME).elf $(PROGRAM_NAME).bin 

dump :
	@$(E) Making $(PROGRAM_NAME).nm
	@$(NM) $(PROGRAM_NAME).elf | sort > $(PROGRAM_NAME).nm
	@$(E) Making $(PROGRAM_NAME).objdump
	@$(OD) $(PROGRAM_NAME).elf -d --source > $(PROGRAM_NAME).objdump

clean :
	@$(E) Removing objects
	@rm -f $(PROGRAM_NAME).o
	@rm -f $(PROGRAM_NAME).elf
	@rm -f $(PROGRAM_NAME).srec
	@rm -f $(PROGRAM_NAME).hex
	@rm -f $(PROGRAM_NAME).bin
	@rm -f $(PROGRAM_NAME).nm
	@rm -f $(PROGRAM_NAME).objdump
	@rm -f $(BOOTROM_NAME)

# end of file

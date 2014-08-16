/*
 * system.h - SOPC Builder system and BSP software package information
 *
 * Machine generated for CPU 'nios2_main' in SOPC Builder design 'DE0_sys'
 * SOPC Builder design path: ../../DE0_sys.sopcinfo
 *
 * Generated: Fri Aug 15 17:47:26 JST 2014
 */

/*
 * DO NOT MODIFY THIS FILE
 *
 * Changing this file will have subtle consequences
 * which will almost certainly lead to a nonfunctioning
 * system. If you do modify this file, be aware that your
 * changes will be overwritten and lost when this file
 * is generated again.
 *
 * DO NOT MODIFY THIS FILE
 */

/*
 * License Agreement
 *
 * Copyright (c) 2008
 * Altera Corporation, San Jose, California, USA.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * This agreement shall be governed in all respects by the laws of the State
 * of California and by the laws of the United States of America.
 */

#ifndef __SYSTEM_H_
#define __SYSTEM_H_

/* Include definitions from linker script generator */
#include "linker.h"


/*
 * CPU configuration
 *
 */

#define ALT_CPU_ARCHITECTURE "altera_nios2_qsys"
#define ALT_CPU_BIG_ENDIAN 0
#define ALT_CPU_BREAK_ADDR 0x0fff0820
#define ALT_CPU_CPU_FREQ 100000000u
#define ALT_CPU_CPU_ID_SIZE 1
#define ALT_CPU_CPU_ID_VALUE 0x00000000
#define ALT_CPU_CPU_IMPLEMENTATION "small"
#define ALT_CPU_DATA_ADDR_WIDTH 0x1d
#define ALT_CPU_DCACHE_LINE_SIZE 0
#define ALT_CPU_DCACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_DCACHE_SIZE 0
#define ALT_CPU_EXCEPTION_ADDR 0x00000020
#define ALT_CPU_FLUSHDA_SUPPORTED
#define ALT_CPU_FREQ 100000000
#define ALT_CPU_HARDWARE_DIVIDE_PRESENT 0
#define ALT_CPU_HARDWARE_MULTIPLY_PRESENT 1
#define ALT_CPU_HARDWARE_MULX_PRESENT 0
#define ALT_CPU_HAS_DEBUG_CORE 1
#define ALT_CPU_HAS_DEBUG_STUB
#define ALT_CPU_HAS_JMPI_INSTRUCTION
#define ALT_CPU_ICACHE_LINE_SIZE 32
#define ALT_CPU_ICACHE_LINE_SIZE_LOG2 5
#define ALT_CPU_ICACHE_SIZE 4096
#define ALT_CPU_INST_ADDR_WIDTH 0x1c
#define ALT_CPU_NAME "nios2_main"
#define ALT_CPU_RESET_ADDR 0x0fff0000


/*
 * CPU configuration (with legacy prefix - don't use these anymore)
 *
 */

#define NIOS2_BIG_ENDIAN 0
#define NIOS2_BREAK_ADDR 0x0fff0820
#define NIOS2_CPU_FREQ 100000000u
#define NIOS2_CPU_ID_SIZE 1
#define NIOS2_CPU_ID_VALUE 0x00000000
#define NIOS2_CPU_IMPLEMENTATION "small"
#define NIOS2_DATA_ADDR_WIDTH 0x1d
#define NIOS2_DCACHE_LINE_SIZE 0
#define NIOS2_DCACHE_LINE_SIZE_LOG2 0
#define NIOS2_DCACHE_SIZE 0
#define NIOS2_EXCEPTION_ADDR 0x00000020
#define NIOS2_FLUSHDA_SUPPORTED
#define NIOS2_HARDWARE_DIVIDE_PRESENT 0
#define NIOS2_HARDWARE_MULTIPLY_PRESENT 1
#define NIOS2_HARDWARE_MULX_PRESENT 0
#define NIOS2_HAS_DEBUG_CORE 1
#define NIOS2_HAS_DEBUG_STUB
#define NIOS2_HAS_JMPI_INSTRUCTION
#define NIOS2_ICACHE_LINE_SIZE 32
#define NIOS2_ICACHE_LINE_SIZE_LOG2 5
#define NIOS2_ICACHE_SIZE 4096
#define NIOS2_INST_ADDR_WIDTH 0x1c
#define NIOS2_RESET_ADDR 0x0fff0000


/*
 * Define for each module class mastered by the CPU
 *
 */

#define __ALTERA_AVALON_EPCS_FLASH_CONTROLLER
#define __ALTERA_AVALON_JTAG_UART
#define __ALTERA_AVALON_NEW_SDRAM_CONTROLLER
#define __ALTERA_AVALON_PIO
#define __ALTERA_AVALON_SYSID_QSYS
#define __ALTERA_AVALON_TIMER
#define __ALTERA_NIOS2_QSYS
#define __MMCDMA
#define __RUBIC_R2N_CONVERTER
#define __ULEXITE_LCD
#define __USBHOST


/*
 * System configuration
 *
 */

#define ALT_DEVICE_FAMILY "Cyclone III"
#define ALT_ENHANCED_INTERRUPT_API_PRESENT
#define ALT_IRQ_BASE NULL
#define ALT_LOG_PORT "/dev/null"
#define ALT_LOG_PORT_BASE 0x0
#define ALT_LOG_PORT_DEV null
#define ALT_LOG_PORT_TYPE ""
#define ALT_NUM_EXTERNAL_INTERRUPT_CONTROLLERS 0
#define ALT_NUM_INTERNAL_INTERRUPT_CONTROLLERS 1
#define ALT_NUM_INTERRUPT_CONTROLLERS 1
#define ALT_STDERR "/dev/jtag_uart"
#define ALT_STDERR_BASE 0x10000010
#define ALT_STDERR_DEV jtag_uart
#define ALT_STDERR_IS_JTAG_UART
#define ALT_STDERR_PRESENT
#define ALT_STDERR_TYPE "altera_avalon_jtag_uart"
#define ALT_STDIN "/dev/jtag_uart"
#define ALT_STDIN_BASE 0x10000010
#define ALT_STDIN_DEV jtag_uart
#define ALT_STDIN_IS_JTAG_UART
#define ALT_STDIN_PRESENT
#define ALT_STDIN_TYPE "altera_avalon_jtag_uart"
#define ALT_STDOUT "/dev/jtag_uart"
#define ALT_STDOUT_BASE 0x10000010
#define ALT_STDOUT_DEV jtag_uart
#define ALT_STDOUT_IS_JTAG_UART
#define ALT_STDOUT_PRESENT
#define ALT_STDOUT_TYPE "altera_avalon_jtag_uart"
#define ALT_SYSTEM_NAME "DE0_sys"


/*
 * epcs configuration
 *
 */

#define ALT_MODULE_CLASS_epcs altera_avalon_epcs_flash_controller
#define EPCS_BASE 0xfff0000
#define EPCS_IRQ 0
#define EPCS_IRQ_INTERRUPT_CONTROLLER_ID 0
#define EPCS_NAME "/dev/epcs"
#define EPCS_REGISTER_OFFSET 1024
#define EPCS_SPAN 2048
#define EPCS_TYPE "altera_avalon_epcs_flash_controller"


/*
 * hal configuration
 *
 */

#define ALT_MAX_FD 4
#define ALT_SYS_CLK none
#define ALT_TIMESTAMP_CLK none


/*
 * jtag_uart configuration
 *
 */

#define ALT_MODULE_CLASS_jtag_uart altera_avalon_jtag_uart
#define JTAG_UART_BASE 0x10000010
#define JTAG_UART_IRQ 1
#define JTAG_UART_IRQ_INTERRUPT_CONTROLLER_ID 0
#define JTAG_UART_NAME "/dev/jtag_uart"
#define JTAG_UART_READ_DEPTH 64
#define JTAG_UART_READ_THRESHOLD 8
#define JTAG_UART_SPAN 8
#define JTAG_UART_TYPE "altera_avalon_jtag_uart"
#define JTAG_UART_WRITE_DEPTH 64
#define JTAG_UART_WRITE_THRESHOLD 8


/*
 * mmcdma configuration
 *
 */

#define ALT_MODULE_CLASS_mmcdma mmcdma
#define MMCDMA_BASE 0x10000400
#define MMCDMA_IRQ 4
#define MMCDMA_IRQ_INTERRUPT_CONTROLLER_ID 0
#define MMCDMA_NAME "/dev/mmcdma"
#define MMCDMA_SPAN 1024
#define MMCDMA_TYPE "mmcdma"


/*
 * pio_button configuration
 *
 */

#define ALT_MODULE_CLASS_pio_button altera_avalon_pio
#define PIO_BUTTON_BASE 0x10000230
#define PIO_BUTTON_BIT_CLEARING_EDGE_REGISTER 0
#define PIO_BUTTON_BIT_MODIFYING_OUTPUT_REGISTER 0
#define PIO_BUTTON_CAPTURE 0
#define PIO_BUTTON_DATA_WIDTH 2
#define PIO_BUTTON_DO_TEST_BENCH_WIRING 0
#define PIO_BUTTON_DRIVEN_SIM_VALUE 0
#define PIO_BUTTON_EDGE_TYPE "NONE"
#define PIO_BUTTON_FREQ 50000000
#define PIO_BUTTON_HAS_IN 1
#define PIO_BUTTON_HAS_OUT 0
#define PIO_BUTTON_HAS_TRI 0
#define PIO_BUTTON_IRQ -1
#define PIO_BUTTON_IRQ_INTERRUPT_CONTROLLER_ID -1
#define PIO_BUTTON_IRQ_TYPE "NONE"
#define PIO_BUTTON_NAME "/dev/pio_button"
#define PIO_BUTTON_RESET_VALUE 0
#define PIO_BUTTON_SPAN 16
#define PIO_BUTTON_TYPE "altera_avalon_pio"


/*
 * pio_hexled configuration
 *
 */

#define ALT_MODULE_CLASS_pio_hexled altera_avalon_pio
#define PIO_HEXLED_BASE 0x10000200
#define PIO_HEXLED_BIT_CLEARING_EDGE_REGISTER 0
#define PIO_HEXLED_BIT_MODIFYING_OUTPUT_REGISTER 0
#define PIO_HEXLED_CAPTURE 0
#define PIO_HEXLED_DATA_WIDTH 32
#define PIO_HEXLED_DO_TEST_BENCH_WIRING 0
#define PIO_HEXLED_DRIVEN_SIM_VALUE 0
#define PIO_HEXLED_EDGE_TYPE "NONE"
#define PIO_HEXLED_FREQ 50000000
#define PIO_HEXLED_HAS_IN 0
#define PIO_HEXLED_HAS_OUT 1
#define PIO_HEXLED_HAS_TRI 0
#define PIO_HEXLED_IRQ -1
#define PIO_HEXLED_IRQ_INTERRUPT_CONTROLLER_ID -1
#define PIO_HEXLED_IRQ_TYPE "NONE"
#define PIO_HEXLED_NAME "/dev/pio_hexled"
#define PIO_HEXLED_RESET_VALUE -1
#define PIO_HEXLED_SPAN 16
#define PIO_HEXLED_TYPE "altera_avalon_pio"


/*
 * pio_led configuration
 *
 */

#define ALT_MODULE_CLASS_pio_led altera_avalon_pio
#define PIO_LED_BASE 0x10000210
#define PIO_LED_BIT_CLEARING_EDGE_REGISTER 0
#define PIO_LED_BIT_MODIFYING_OUTPUT_REGISTER 0
#define PIO_LED_CAPTURE 0
#define PIO_LED_DATA_WIDTH 10
#define PIO_LED_DO_TEST_BENCH_WIRING 0
#define PIO_LED_DRIVEN_SIM_VALUE 0
#define PIO_LED_EDGE_TYPE "NONE"
#define PIO_LED_FREQ 50000000
#define PIO_LED_HAS_IN 0
#define PIO_LED_HAS_OUT 1
#define PIO_LED_HAS_TRI 0
#define PIO_LED_IRQ -1
#define PIO_LED_IRQ_INTERRUPT_CONTROLLER_ID -1
#define PIO_LED_IRQ_TYPE "NONE"
#define PIO_LED_NAME "/dev/pio_led"
#define PIO_LED_RESET_VALUE 0
#define PIO_LED_SPAN 16
#define PIO_LED_TYPE "altera_avalon_pio"


/*
 * pio_sw configuration
 *
 */

#define ALT_MODULE_CLASS_pio_sw altera_avalon_pio
#define PIO_SW_BASE 0x10000220
#define PIO_SW_BIT_CLEARING_EDGE_REGISTER 0
#define PIO_SW_BIT_MODIFYING_OUTPUT_REGISTER 0
#define PIO_SW_CAPTURE 0
#define PIO_SW_DATA_WIDTH 10
#define PIO_SW_DO_TEST_BENCH_WIRING 0
#define PIO_SW_DRIVEN_SIM_VALUE 0
#define PIO_SW_EDGE_TYPE "NONE"
#define PIO_SW_FREQ 50000000
#define PIO_SW_HAS_IN 1
#define PIO_SW_HAS_OUT 0
#define PIO_SW_HAS_TRI 0
#define PIO_SW_IRQ -1
#define PIO_SW_IRQ_INTERRUPT_CONTROLLER_ID -1
#define PIO_SW_IRQ_TYPE "NONE"
#define PIO_SW_NAME "/dev/pio_sw"
#define PIO_SW_RESET_VALUE 0
#define PIO_SW_SPAN 16
#define PIO_SW_TYPE "altera_avalon_pio"


/*
 * rubic_r2n_ctrl configuration
 *
 */

#define ALT_MODULE_CLASS_rubic_r2n_ctrl rubic_r2n_converter
#define RUBIC_R2N_CTRL_BASE 0x6000000
#define RUBIC_R2N_CTRL_IRQ -1
#define RUBIC_R2N_CTRL_IRQ_INTERRUPT_CONTROLLER_ID -1
#define RUBIC_R2N_CTRL_NAME "/dev/rubic_r2n_ctrl"
#define RUBIC_R2N_CTRL_SPAN 512
#define RUBIC_R2N_CTRL_TYPE "rubic_r2n_converter"


/*
 * rubic_r2n_nios2 configuration
 *
 */

#define ALT_MODULE_CLASS_rubic_r2n_nios2 rubic_r2n_converter
#define RUBIC_R2N_NIOS2_BASE 0x4000000
#define RUBIC_R2N_NIOS2_IRQ -1
#define RUBIC_R2N_NIOS2_IRQ_INTERRUPT_CONTROLLER_ID -1
#define RUBIC_R2N_NIOS2_NAME "/dev/rubic_r2n_nios2"
#define RUBIC_R2N_NIOS2_SPAN 33554432
#define RUBIC_R2N_NIOS2_TYPE "rubic_r2n_converter"


/*
 * sdram configuration
 *
 */

#define ALT_MODULE_CLASS_sdram altera_avalon_new_sdram_controller
#define SDRAM_BASE 0x0
#define SDRAM_CAS_LATENCY 3
#define SDRAM_CONTENTS_INFO
#define SDRAM_INIT_NOP_DELAY 0.0
#define SDRAM_INIT_REFRESH_COMMANDS 8
#define SDRAM_IRQ -1
#define SDRAM_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SDRAM_IS_INITIALIZED 1
#define SDRAM_NAME "/dev/sdram"
#define SDRAM_POWERUP_DELAY 200.0
#define SDRAM_REFRESH_PERIOD 15.625
#define SDRAM_REGISTER_DATA_IN 1
#define SDRAM_SDRAM_ADDR_WIDTH 0x16
#define SDRAM_SDRAM_BANK_WIDTH 2
#define SDRAM_SDRAM_COL_WIDTH 8
#define SDRAM_SDRAM_DATA_WIDTH 16
#define SDRAM_SDRAM_NUM_BANKS 4
#define SDRAM_SDRAM_NUM_CHIPSELECTS 1
#define SDRAM_SDRAM_ROW_WIDTH 12
#define SDRAM_SHARED_DATA 0
#define SDRAM_SIM_MODEL_BASE 0
#define SDRAM_SPAN 8388608
#define SDRAM_STARVATION_INDICATOR 0
#define SDRAM_TRISTATE_BRIDGE_SLAVE ""
#define SDRAM_TYPE "altera_avalon_new_sdram_controller"
#define SDRAM_T_AC 5.5
#define SDRAM_T_MRD 3
#define SDRAM_T_RCD 18.0
#define SDRAM_T_RFC 60.0
#define SDRAM_T_RP 18.0
#define SDRAM_T_WR 14.0


/*
 * sysid configuration
 *
 */

#define ALT_MODULE_CLASS_sysid altera_avalon_sysid_qsys
#define SYSID_BASE 0x10000000
#define SYSID_ID 0
#define SYSID_IRQ -1
#define SYSID_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SYSID_NAME "/dev/sysid"
#define SYSID_SPAN 8
#define SYSID_TIMESTAMP 1408092222
#define SYSID_TYPE "altera_avalon_sysid_qsys"


/*
 * timer_tick configuration
 *
 */

#define ALT_MODULE_CLASS_timer_tick altera_avalon_timer
#define TIMER_TICK_ALWAYS_RUN 1
#define TIMER_TICK_BASE 0x10000100
#define TIMER_TICK_COUNTER_SIZE 32
#define TIMER_TICK_FIXED_PERIOD 1
#define TIMER_TICK_FREQ 50000000
#define TIMER_TICK_IRQ 2
#define TIMER_TICK_IRQ_INTERRUPT_CONTROLLER_ID 0
#define TIMER_TICK_LOAD_VALUE 49999
#define TIMER_TICK_MULT 0.0010
#define TIMER_TICK_NAME "/dev/timer_tick"
#define TIMER_TICK_PERIOD 1
#define TIMER_TICK_PERIOD_UNITS "ms"
#define TIMER_TICK_RESET_OUTPUT 0
#define TIMER_TICK_SNAPSHOT 0
#define TIMER_TICK_SPAN 32
#define TIMER_TICK_TICKS_PER_SEC 1000.0
#define TIMER_TICK_TIMEOUT_PULSE_OUTPUT 0
#define TIMER_TICK_TYPE "altera_avalon_timer"


/*
 * ulexite_lcd configuration
 *
 */

#define ALT_MODULE_CLASS_ulexite_lcd ulexite_lcd
#define ULEXITE_LCD_BASE 0x2000000
#define ULEXITE_LCD_IRQ -1
#define ULEXITE_LCD_IRQ_INTERRUPT_CONTROLLER_ID -1
#define ULEXITE_LCD_NAME "/dev/ulexite_lcd"
#define ULEXITE_LCD_SPAN 16
#define ULEXITE_LCD_TYPE "ulexite_lcd"


/*
 * usbhost configuration
 *
 */

#define ALT_MODULE_CLASS_usbhost usbhost
#define USBHOST_BASE 0x10000300
#define USBHOST_IRQ 3
#define USBHOST_IRQ_INTERRUPT_CONTROLLER_ID 0
#define USBHOST_NAME "/dev/usbhost"
#define USBHOST_SPAN 256
#define USBHOST_TYPE "usbhost"

#endif /* __SYSTEM_H_ */

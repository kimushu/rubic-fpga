
#ifndef __elf32_h_
#define __elf32_h_


// ELFファイルの変数型宣言 

typedef void*			ELF32_Addr;
typedef unsigned short	ELF32_Half;
typedef unsigned long	ELF32_Off;
typedef long			ELF32_Sword;
typedef unsigned long	ELF32_Word;
typedef unsigned char	ELF32_Char;


#pragma pack(1)

// ELFファイルヘッダ構造体 
typedef struct {
	ELF32_Char		elf_id[16];		// ファイルID 
	ELF32_Half		elf_type;		// オブジェクトファイルタイプ 
	ELF32_Half		elf_machine;	// ターゲットアーキテクチャ 
	ELF32_Word		elf_version;	// ELFファイルバージョン(現在は1) 
	ELF32_Addr		elf_entry;		// エントリアドレス(エントリ無しなら0) 
	ELF32_Off		elf_phoff;		// Programヘッダテーブルのファイル先頭からのオフセット 
	ELF32_Off		elf_shoff;		// 実行時未使用
	ELF32_Word		elf_flags;		// プロセッサ固有のフラグ 
	ELF32_Half		elf_ehsize;		// ELFヘッダのサイズ 
	ELF32_Half		elf_phentsize;	// Programヘッダテーブルの1要素あたりのサイズ 
	ELF32_Half		elf_phnum;		// Programヘッダテーブルの要素数 
	ELF32_Half		elf_shentsize;	// 実行時未使用
	ELF32_Half		elf_shnum;		// 実行時未使用
	ELF32_Half		elf_shstrndx;	// 実行時未使用
} ELF32_HEADER;

// Programヘッダ構造体 
typedef struct {
	ELF32_Word		p_type;			// セグメントのエントリタイプ 
	ELF32_Off		p_offset;		// 対応するセグメントのファイル先頭からのオフセット 
	ELF32_Addr		p_vaddr;		// メモリ上でのセグメントの第一バイトの仮想アドレス 
	ELF32_Addr		p_paddr;		// 物理番地指定が適切なシステムの為に予約(p_vaddrと同値)
	ELF32_Word		p_filesz;		// 対応するセグメントのファイルでのサイズ(0も可)
	ELF32_Word		p_memsz;		// 対応するセグメントのメモリ上に展開された時のサイズ(0も可)
	ELF32_Word		p_flags;		// 対応するセグメントに適切なフラグ 
	ELF32_Word		p_align;		// アライメント(p_offsetとp_vaddrをこの値で割った余りは等しい)
} ELF32_PHEADER;

#pragma pack()


// elf_idの要素 
/*
	elf_id[0] = 0x7f
	elf_id[1] = 'E' (0x45)
	elf_id[2] = 'L' (0x4c)
	elf_id[3] = 'F' (0x46)
	elf_id[4] = ファイルのクラスを示す(0x00:invalid / 0x01:32bit / 0x02:64bit)
	elf_id[5] = エンディアンを示す(0x00:invalid / 0x01:Little / 0x02:Big)
	elf_id[6] = ELFヘッダのバージョン(現在は1)
	elf_id[7] = ファイルが対象とするOSとABIを示す 
	elf_id[8] = ファイルが対象とするABIのバージョン 
	elf_id[9～15] = 未使用(0x00でパディング) 
*/

// ELFオブジェクトファイルタイプ(elf_type)の定数宣言 
#define ELF_ET_NONE		(0)		// ファイルタイプ未定 
#define ELF_ET_REL		(1)		// 再配置可能なオブジェクトファイル 
#define ELF_ET_EXEC		(2)		// 実行可能なオブジェクトファイル 
#define ELF_ET_DYN		(3)		// 共有オブジェクトファイル 
#define ELF_ET_CORE		(4)		// コアファイル 
#define ELF_ET_LOOS		(0xfe00)	// OS固有のセマンティクスの為に予約された領域 
#define ELF_ET_HIOS		(0xfeff)
#define ELF_ET_LOPROC	(0xff00)	// プロセッサ固有のセマンティクスの為に予約された領域 
#define ELF_ET_HIPROC	(0xffff)

// ターゲットアーキテクチャタイプ(elf_machine)の定数宣言 
#define ELF_EM_NONE		(0)		// ターゲットマシン無し 
#define ELF_EM_M32		(1)		// AT&T WE 32100
#define ELF_EM_SPARC	(2)		// SPARC
#define ELF_EM_386		(3)		// Intel 80386
#define ELF_EM_68K		(4)		// Motorola 68000
#define ELF_EM_88K		(5)		// Motorola 88000
#define ELF_EM_860		(7)		// Intel 80860
#define ELF_EM_MIPS		(8)		// MIPS I
#define ELF_EM_S370		(9)		// IBM System/370 Processor
#define ELF_EM_RS3_LE	(10)	// MIPS RS3000(Little-endian)
#define ELF_EM_PARISC	(15)	// Hewlett-Packard PA-RISC
#define ELF_EM_VPP500	(17)	// Fujitsu VPP500 
#define ELF_EM_SPARC32P	(18)	// Enhanced instruction set SPARC 
#define ELF_EM_960		(19)	// Intel 80960
#define ELF_EM_PPC		(20)	// PowerPC
#define ELF_EM_PPC64	(21)	// 64-bit PowerPC
#define ELF_EM_V800		(36)	// NEC V800
#define ELF_EM_FR20		(37)	// Fujitsu FR20
#define ELF_EM_RH32		(38)	// TRW RH-32
#define ELF_EM_RCE		(39)	// Motorola RCE
#define ELF_EM_ARM		(40)	// ARM
#define ELF_EM_ALPHA	(41)	// Digital Alpha
#define ELF_EM_SH		(42)	// Hitachi SH
#define ELF_EM_SPARCV9	(43)	// SPARC Version 9
#define ELF_EM_TRICORE	(44)	// Siemens Tricore embedded processor
#define ELF_EM_ARC		(45)	// Argonaut RISC Core
#define ELF_EM_H8_300	(46)	// Hitachi H8/300
#define ELF_EM_H8_300H	(47)	// Hitachi H8/300H
#define ELF_EM_H8S		(48)	// Hitachi H8S
#define ELF_EM_H8_500	(49)	// Hitachi H8/500
#define ELF_EM_IA_64	(50)	// Intel IA-64 processor
#define ELF_EM_MIPS_X	(51)	// Stanford MIPS-X
#define ELF_EM_COLDFIRE	(52)	// Motorola ColdFire
#define ELF_EM_68HC12	(53)	// Motorola M68HC12
#define ELF_EM_MMA		(54)	// Fujitsu MMA Multimedia Accelerator
#define ELF_EM_PCP		(55)	// Siemens PCP
#define ELF_EM_NCPU		(56)	// Sony nCPU embedded RISC processor
#define ELF_EM_NDR1		(57)	// Denso NDR1 microprocessor
#define ELF_EM_STARCORE	(58)	// Motorola Star*Core processor
#define ELF_EM_ME16		(59)	// Toyota ME16 processor
#define ELF_EM_ST100	(60)	// STMicroelectronics ST100 processor
#define ELF_EM_TINYJ	(61)	// TinyJ embedded processor family
#define ELF_EM_FX66		(66)	// Siemens FX66 microcontroller
#define ELF_EM_ST9P		(67)	// STMicroelectronics ST9+ 8/16 bit microcontroller
#define ELF_EM_ST7		(68)	// STMicroelectronics ST7 8-bit microcontroller
#define ELF_EM_68HC16	(69)	// Motorola MC68HC16 Microcontroller
#define ELF_EM_68HC11	(70)	// Motorola MC68HC11 Microcontroller
#define ELF_EM_68HC08	(71)	// Motorola MC68HC08 Microcontroller
#define ELF_EM_68HC05	(72)	// Motorola MC68HC05 Microcontroller
#define ELF_EM_SVX		(73)	// Silicon Graphics SVx
#define ELF_EM_ST19		(74)	// STMicroelectronics ST19 8-bit microcontroller
#define ELF_EM_VAX		(75)	// Digital VAX
#define ELF_EM_CRIS		(76)	// Axis Communications 32-bit embedded processor
#define ELF_EM_JAVELIN	(77)	// Infineon Technologies 32-bit embedded processor
#define ELF_EM_FIREPATH	(78)	// Element 14 64-bit DSP Processor
#define ELF_EM_ZSP		(79)	// LSI Logic 16-bit DSP Processor
#define ELF_EM_NIOS		(0xfebb)	// Altera Nios Processor
#define ELF_EM_NIOS2	(0x0071)	// Altera NiosII Processor
#define ELF_EM_MBLAZE	(0xbaab)	// Xilinx MicroBlaze Processor

// Programタイプ(p_type)の定数宣言 
#define ELF_PT_NULL		(0)		// 使われないエントリで、他のメンバの値の意味は未定義 
#define ELF_PT_LOAD		(1)		// 実行時にロードされるセグメント 
#define ELF_PT_DYNAMIC	(2)		// 動的構造体配列を保持するセグメント 
#define ELF_PT_INTERP 	(3)		// ファイルの解釈に使われるインタプリタのパスを保持するセグメント 
#define ELF_PT_NOTE		(4)		// ファイルの解釈には使われない情報を保持するセグメント 
#define ELF_PT_SHLIB	(5)		// 予約 
#define ELF_PT_PHDR		(6)		// Programヘッダテーブル(メモリイメージの一部である場合のみ存在) 
#define ELF_PT_TLS		(7)		// スレッド局所記憶領域のテンプレート 
#define ELF_PT_LOOS		(0x60000000)	// OS固有のセマンティクスの為に予約された領域 
#define ELF_PT_HIOS		(0x6fffffff)
#define ELF_PT_LOPROC	(0x70000000)	// プロセッサ固有のセマンティクスの為に予約された領域 
#define ELF_PT_HIPROC	(0x7fffffff)

// Programフラグ(p_flag)の定数宣言 
#define ELF_PF_X		(1<<0)		// 実行可能属性 
#define ELF_PF_W		(1<<1)		// 書き込み可能属性 
#define ELF_PF_R		(1<<2)		// 読みとり可能属性 
#define ELF_PF_MASKPROC	(0xf0000000)	// 未指定 



#endif

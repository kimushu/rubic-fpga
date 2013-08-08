
#ifndef __elf32_h_
#define __elf32_h_


// ELF�t�@�C���̕ϐ��^�錾 

typedef void*			ELF32_Addr;
typedef unsigned short	ELF32_Half;
typedef unsigned long	ELF32_Off;
typedef long			ELF32_Sword;
typedef unsigned long	ELF32_Word;
typedef unsigned char	ELF32_Char;


#pragma pack(1)

// ELF�t�@�C���w�b�_�\���� 
typedef struct {
	ELF32_Char		elf_id[16];		// �t�@�C��ID 
	ELF32_Half		elf_type;		// �I�u�W�F�N�g�t�@�C���^�C�v 
	ELF32_Half		elf_machine;	// �^�[�Q�b�g�A�[�L�e�N�`�� 
	ELF32_Word		elf_version;	// ELF�t�@�C���o�[�W����(���݂�1) 
	ELF32_Addr		elf_entry;		// �G���g���A�h���X(�G���g�������Ȃ�0) 
	ELF32_Off		elf_phoff;		// Program�w�b�_�e�[�u���̃t�@�C���擪����̃I�t�Z�b�g 
	ELF32_Off		elf_shoff;		// ���s�����g�p
	ELF32_Word		elf_flags;		// �v���Z�b�T�ŗL�̃t���O 
	ELF32_Half		elf_ehsize;		// ELF�w�b�_�̃T�C�Y 
	ELF32_Half		elf_phentsize;	// Program�w�b�_�e�[�u����1�v�f������̃T�C�Y 
	ELF32_Half		elf_phnum;		// Program�w�b�_�e�[�u���̗v�f�� 
	ELF32_Half		elf_shentsize;	// ���s�����g�p
	ELF32_Half		elf_shnum;		// ���s�����g�p
	ELF32_Half		elf_shstrndx;	// ���s�����g�p
} ELF32_HEADER;

// Program�w�b�_�\���� 
typedef struct {
	ELF32_Word		p_type;			// �Z�O�����g�̃G���g���^�C�v 
	ELF32_Off		p_offset;		// �Ή�����Z�O�����g�̃t�@�C���擪����̃I�t�Z�b�g 
	ELF32_Addr		p_vaddr;		// ��������ł̃Z�O�����g�̑��o�C�g�̉��z�A�h���X 
	ELF32_Addr		p_paddr;		// �����Ԓn�w�肪�K�؂ȃV�X�e���ׂ̈ɗ\��(p_vaddr�Ɠ��l)
	ELF32_Word		p_filesz;		// �Ή�����Z�O�����g�̃t�@�C���ł̃T�C�Y(0����)
	ELF32_Word		p_memsz;		// �Ή�����Z�O�����g�̃�������ɓW�J���ꂽ���̃T�C�Y(0����)
	ELF32_Word		p_flags;		// �Ή�����Z�O�����g�ɓK�؂ȃt���O 
	ELF32_Word		p_align;		// �A���C�����g(p_offset��p_vaddr�����̒l�Ŋ������]��͓�����)
} ELF32_PHEADER;

#pragma pack()


// elf_id�̗v�f 
/*
	elf_id[0] = 0x7f
	elf_id[1] = 'E' (0x45)
	elf_id[2] = 'L' (0x4c)
	elf_id[3] = 'F' (0x46)
	elf_id[4] = �t�@�C���̃N���X������(0x00:invalid / 0x01:32bit / 0x02:64bit)
	elf_id[5] = �G���f�B�A��������(0x00:invalid / 0x01:Little / 0x02:Big)
	elf_id[6] = ELF�w�b�_�̃o�[�W����(���݂�1)
	elf_id[7] = �t�@�C�����ΏۂƂ���OS��ABI������ 
	elf_id[8] = �t�@�C�����ΏۂƂ���ABI�̃o�[�W���� 
	elf_id[9�`15] = ���g�p(0x00�Ńp�f�B���O) 
*/

// ELF�I�u�W�F�N�g�t�@�C���^�C�v(elf_type)�̒萔�錾 
#define ELF_ET_NONE		(0)		// �t�@�C���^�C�v���� 
#define ELF_ET_REL		(1)		// �Ĕz�u�\�ȃI�u�W�F�N�g�t�@�C�� 
#define ELF_ET_EXEC		(2)		// ���s�\�ȃI�u�W�F�N�g�t�@�C�� 
#define ELF_ET_DYN		(3)		// ���L�I�u�W�F�N�g�t�@�C�� 
#define ELF_ET_CORE		(4)		// �R�A�t�@�C�� 
#define ELF_ET_LOOS		(0xfe00)	// OS�ŗL�̃Z�}���e�B�N�X�ׂ̈ɗ\�񂳂ꂽ�̈� 
#define ELF_ET_HIOS		(0xfeff)
#define ELF_ET_LOPROC	(0xff00)	// �v���Z�b�T�ŗL�̃Z�}���e�B�N�X�ׂ̈ɗ\�񂳂ꂽ�̈� 
#define ELF_ET_HIPROC	(0xffff)

// �^�[�Q�b�g�A�[�L�e�N�`���^�C�v(elf_machine)�̒萔�錾 
#define ELF_EM_NONE		(0)		// �^�[�Q�b�g�}�V������ 
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

// Program�^�C�v(p_type)�̒萔�錾 
#define ELF_PT_NULL		(0)		// �g���Ȃ��G���g���ŁA���̃����o�̒l�̈Ӗ��͖���` 
#define ELF_PT_LOAD		(1)		// ���s���Ƀ��[�h�����Z�O�����g 
#define ELF_PT_DYNAMIC	(2)		// ���I�\���̔z���ێ�����Z�O�����g 
#define ELF_PT_INTERP 	(3)		// �t�@�C���̉��߂Ɏg����C���^�v���^�̃p�X��ێ�����Z�O�����g 
#define ELF_PT_NOTE		(4)		// �t�@�C���̉��߂ɂ͎g���Ȃ�����ێ�����Z�O�����g 
#define ELF_PT_SHLIB	(5)		// �\�� 
#define ELF_PT_PHDR		(6)		// Program�w�b�_�e�[�u��(�������C���[�W�̈ꕔ�ł���ꍇ�̂ݑ���) 
#define ELF_PT_TLS		(7)		// �X���b�h�Ǐ��L���̈�̃e���v���[�g 
#define ELF_PT_LOOS		(0x60000000)	// OS�ŗL�̃Z�}���e�B�N�X�ׂ̈ɗ\�񂳂ꂽ�̈� 
#define ELF_PT_HIOS		(0x6fffffff)
#define ELF_PT_LOPROC	(0x70000000)	// �v���Z�b�T�ŗL�̃Z�}���e�B�N�X�ׂ̈ɗ\�񂳂ꂽ�̈� 
#define ELF_PT_HIPROC	(0x7fffffff)

// Program�t���O(p_flag)�̒萔�錾 
#define ELF_PF_X		(1<<0)		// ���s�\���� 
#define ELF_PF_W		(1<<1)		// �������݉\���� 
#define ELF_PF_R		(1<<2)		// �ǂ݂Ƃ�\���� 
#define ELF_PF_MASKPROC	(0xf0000000)	// ���w�� 



#endif

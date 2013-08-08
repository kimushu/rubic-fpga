/*-------------------------------------------
  boot_loader.s  v0.3

  (C)S.OSAFUNE, (C)2007-2011 J-7SYSTEM WORKS
 --------------------------------------------*/
/*
  Cineraria LMi�R�A�����u�[�g���[�_

  0x00000020 - 0x007FDFFF : �v���O�����̈� (8380384�o�C�g)
  0x007FE000 - 0x007FFFFF : �u�[�g�v���O�����̈�(8192�o�C�g)

  0x00000020 : Exception�x�N�^����уR�[�h�̈�g�b�v 
  0x00800000 : �X�^�b�N�g�b�v 

  0x0F000000 : ���Z�b�g�x�N�^ 
  0x0F000010 : �V�X�e�����G���g���i��������EPCS���[�h�G���g�����w�肷��j
*/

.section ".text"
    .global reset
    .global _start
    .global main
	.global _system_entry


/*** �萔�錾 *****/

	.ifndef EPCS_PROGRAM_BASE
	.equ EPCS_PROGRAM_BASE,		0x40000			# �v���O�������i�[�ʒu 
	.endif

	.ifndef EPCS_CONTROLLER_BASE
	.equ EPCS_CONTROLLER_BASE,	0x00f00000		# epcs_controller�y���t�F�����A�h���X 
	.endif

	.ifndef EPCS_REG_OFFSET
	.equ EPCS_REG_OFFSET,		0x200			# epcs_controller���W�X�^�I�t�Z�b�g 
	.endif

#	.equ SYSTEM_ENV_BASE,		0x00000000		# �V�X�e���������������A�h���X 
#	.equ SYSTEM_ENV_SIZE,		(256)			# �V�X�e���������T�C�Y 
#	.equ REG_7SEG_BASE,			0x10000220		# �G���[�\���p7�Z�OLED���W�X�^�A�h���X 
#	.equ REG_LED_BASE,			0x01000060		# �G���[�\���pLED���W�X�^�A�h���X 


	.equ PROGRAM_ID,			0x434f5250		# �v���O����ID ('P''R''O''C')

	.equ ICACHE_MAX_SIZE,		(64*1024)		# NiosII���T�|�[�g����ő�̖��߃L���b�V���T�C�Y 
	.equ ICACHE_LINE_SIZE,		(32)

	.equ EPCS_RXDATA_OFFSET,	(EPCS_REG_OFFSET+0)		# ��M�f�[�^���W�X�^ 
	.equ EPCS_TXDATA_OFFSET,	(EPCS_REG_OFFSET+4)		# ���M�f�[�^���W�X�^ 
	.equ EPCS_STATUS_OFFSET,	(EPCS_REG_OFFSET+8)		# �X�e�[�^�X���W�X�^ 
	.equ EPCS_CONTROL_OFFSET,	(EPCS_REG_OFFSET+12)	# �R���g���[�����W�X�^ 
	.equ EPCS_STATUS_TMT_MASK,	(1 << 5)
	.equ EPCS_STATUS_TRDY_MASK,	(1 << 6)
	.equ EPCS_STATUS_RRDY_MASK,	(1 << 7)
	.equ EPCS_CONTROL_SSO_MASK,	(1 << 10)
	.equ EPCS_COMMAND_READ,		0x03

	.equ LZSS_REFADDR_BIT,		(12)
	.equ LZSS_COPYLENGTH_BIT,	(4)
	.equ LZSS_REFADDR_SHIFT,	LZSS_COPYLENGTH_BIT
	.equ LZSS_CLBIT_MASK,		(0x0f)
	.equ LZSS_CTRLBIT_MASK,		(0x80)



/*** �}�N�����ߐ錾 *****/

	.macro	CPU_HALT				# �i�v���[�v
	cpu_halt_loop_\@:
		br		cpu_halt_loop_\@
	.endm

	.macro	MOVI32 reg,imm32		# ���W�X�^��32bit���l���� 
	.if ((\imm32)& 0xffff0000)
		movhi	\reg, %hi(\imm32)
		.if ((\imm32)& 0x0000ffff)
			ori		\reg, \reg, %lo(\imm32)
		.endif
	.else
		movui	\reg, %lo(\imm32)
	.endif
	.endm

	.macro	INC reg					# �C���N�������g 
		addi	\reg,\reg,1
	.endm

	.macro	DEC reg					# �f�N�������g 
		subi	\reg,\reg,1
	.endm

	.macro	NOT reg					# �r�b�g���] 
		nor		\reg,\reg,zero
	.endm


/*** �X�e�[�^�X�\�� *****/

	.macro	LED_INIT_SET
	led_init_set_\@:
	.ifdef REG_7SEG_BASE
		MOVI32	r2, (~0x7c5c5c78)
		MOVI32	r3, REG_7SEG_BASE
		stwio	r2, 0(r3)			# "boot"�\�� 
	.else
	.ifdef REG_LED_BASE
		MOVI32	r3, REG_LED_BASE
		stwio	zero, 0(r3)			# LED���� 
	.endif
	.endif
	.endm

	.macro	LED_ERROR_HALT
	led_error_halt_\@:
	.ifdef REG_7SEG_BASE
		MOVI32	r2, (~0x7950d03f)
		MOVI32	r3, REG_7SEG_BASE
		stwio	r2, 0(r3)			# "Err.0"�\�� 
		CPU_HALT
	.else
	.ifdef REG_LED_BASE
		MOVI32	r3, REG_LED_BASE
		mov		r2, zero
	led_flash_loop_\@:
		MOVI32	r4, 0x100000
	led_wait_loop_\@:
		DEC		r4
		bne		r4, zero, led_wait_loop_\@
		stwio	r2, 0(r3)
		NOT		r2
		br		led_flash_loop_\@
	.else
		CPU_HALT
	.endif
	.endif
	.endm


/*-------------------------------------
  ���C�����[�`��
 -------------------------------------*/
reset:
_start:
main:

	/*** �b�o�t�̏����� *****/

	wrctl	status, zero				# �X�e�[�^�X���W�X�^�������� 
	mov		r4, zero					# ���Z�b�g�͑��������[���ɂ��� 

	nop
	nop

	/*** �V�X�e���G���g���ʒu�i�����`���[���A�ʒu�j *****/
_system_entry:

	/*** ���߃L���b�V���̏����� *****/

	MOVI32	r2, ICACHE_MAX_SIZE
 cache_loop:
	initi	r2							# ���߃L���b�V���������� 
	subi	r2, r2, ICACHE_LINE_SIZE
	bne		r2, zero, cache_loop

	flushp								# ���߃p�C�v���C�����N���A 


	/*** �V�X�e�����ϐ��̏����� *****/

	LED_INIT_SET						# LED�\�������� 

	bne		r4, zero, envclear_skip		# ���������[���łȂ��ꍇ�͍ăG���g���Ɣ��f���� 

  .ifdef SYSTEM_ENV_BASE
	MOVI32	r2, SYSTEM_ENV_BASE
	MOVI32	r3, SYSTEM_ENV_BASE + SYSTEM_ENV_SIZE
   envclear_loop:
	stbio	zero, 0(r2)					# �V�X�e�����ϐ��̈���N���A 
	INC		r2
	bne		r2, r3, envclear_loop
  .endif

	MOVI32	r4, EPCS_PROGRAM_BASE		# �u�[�g�v���O�����G���g���ʒu 
 envclear_skip:


	/*** �v���O�����w�b�_�̃`�F�b�N *****/

	MOVI32	gp, EPCS_CONTROLLER_BASE	# gp = epcs_reg_ptr
	mov		r15, r4						# r15 = epcs_data_ptr
	subi	r18, zero, 1				# r18 = 0xffffffff (�萔)

	call	sub_epcs_dev_open			# EPCS�f�o�C�X���I�[�v������ID�����[�h 
	call	sub_epcs_dev_close
	MOVI32	r2, PROGRAM_ID
	bne		r21, r2, program_not_found	# r21 = epcs_resv_int


	/*** �v���O�����f�[�^�̓]�� *****/

program_copy:
	addi	r15, r15, 8					# �w�b�_�T�C�Y�𒲐� 
	call	sub_epcs_dev_open			# EPCS�f�o�C�X���I�[�v�����ăf�[�^�T�C�Y���擾 

	beq		r21, r18, program_no_entry	# �f�[�^�T�C�Y��-1�Ȃ�G���g������ 
	mov		r16, r21					# r16 = data_size
	call	sub_epcs_read_int
	beq		r16, zero, program_entry	# �f�[�^�T�C�Y��0�Ȃ�v���O�����G���g�� 

	mov		r17, r21					# r17 = dest_ptr
	mov		r19, zero					# ���M�f�[�^��0�N���A 

	MOVI32	r2, 0x80000000				# ���k�t���O�̃`�F�b�N 
	and		r14, r16, r2				# r14 = ���k�t���O(=0�Ȃ���f�[�^�A!=0�Ȃ�LZSS)
	NOT		r2
	and		r16, r16, r2
	add		r15, r15, r16				# �f�[�^�|�C���^�X�V 

	add		r16, r16, r17				# r16 = end_dest_ptr


	/*** �o�C�g�f�[�^���������֓]�� *****/

	beq		r14, zero, lzss_data_byte	# �񈳏k�Ȃ���o�C�g������ 

	call	sub_epcs_read_int			# �I���W�i���f�[�^�T�C�Y��ǂݍ��� 
	add		r16, r21, r17				# r16 = end_dest_ptr

	mov		r5, zero					# r5 = lzss_riteral_count
lzss_decompress_loop:
										### ����f�[�^�̏��� #####
	beq		r5, zero, lzss_ctrl_byte_read
	slli	r6, r6, 1
	DEC		r5
	br		lzss_riteral_check

  lzss_ctrl_byte_read:					# CTRL�o�C�g��V���ɓǂݍ��� 
	call	sub_epcs_tx_rx_byte
	mov		r6, r20						# r6 = lzss_ctrl_byte
	movi	r5, 7

  lzss_riteral_check:
	andi	r2, r6, LZSS_CTRLBIT_MASK
	bne		r2, zero, lzss_ref_word		# CTRL�r�b�g��1�Ȃ�Q�ƃf�[�^ 


  lzss_data_byte:						### ���f�[�^�̏��� #####
	call	sub_epcs_tx_rx_byte			# ���f�[�^��ǂݍ���(1�o�C�g)

	mov		r4, zero					# �Q�ƃ��[�v�����Ȃ��悤�ݒ� 
	br		lzss_bytedata_store			# �������֏������� 

  lzss_ref_word:						### �Q�ƃf�[�^�̏��� #####
	call	sub_epcs_tx_rx_byte			# �Q�ƃf�[�^��ǂݍ���(2�o�C�g�r�b�O�G���f�B�A��)
 	slli	r4, r20, 8
	call	sub_epcs_tx_rx_byte
	or		r20, r20, r4
	beq		r20, zero, section_data_copy_exit
										# �Q�ƃf�[�^��0�̏ꍇ�̓G���h�R�[�h 

	srli	r3, r20, LZSS_REFADDR_SHIFT	# r3 = ref_data_addr_offs
	andi	r4, r20, LZSS_CLBIT_MASK
	addi	r4, r4, 2					# r4 = ref_data_count

  lzss_ref_copy_loop:					### �ߋ��f�[�^���R�s�[ #####
	sub		r2, r17, r3					# ref_addr = dest_ptr - ref_data_addr_offs
 	ldbuio	r20, 0(r2)
	DEC		r4


  lzss_bytedata_store:					### �������փf�[�^���������� #####
	stbio	r20, 0(r17)					# r20 = �������ރo�C�g�f�[�^ 
	INC		r17							# dest�|�C���^���X�V 
	beq		r17, r16, section_data_copy_exit
	bne		r4, zero, lzss_ref_copy_loop

	beq		r14, zero, lzss_data_byte	# �񈳏k�Ȃ���o�C�g�������֖߂� 
	br		lzss_decompress_loop


section_data_copy_exit:
	call	sub_epcs_dev_close
	br		program_copy


	/*** �v���O���������s *****/

program_entry:
	call	sub_epcs_dev_close
    callr	r21							# ���[�h�����v���O�����փW�����v 

#	CPU_HALT	# �����ɂ͖߂��Ă��Ȃ� 


	/*** �v���O�����G���g�������� *****/

program_no_entry:
	call	sub_epcs_dev_close

#	LED_ERROR_HALT


	/*** �v���O�����f�[�^��������Ȃ� *****/

program_not_found:

	LED_ERROR_HALT



/*-------------------------------------
  EPCS�f�o�C�X���J���čŏ���4�o�C�g���擾 

   ���� : r15(epcs_addr)
   �o�� : r21(epcs_resv_int)

   �Q�� : r15(epcs_addr), gp(epcs_base_address)
   �ύX : r19(epcs_send_data), r20(epcs_resv_data), r21(epcs_resv_int)
   			r2, r3
 -------------------------------------*/
sub_epcs_dev_open:
	mov		fp, ra

	movi	r2, EPCS_CONTROL_SSO_MASK
	stwio	r2, EPCS_CONTROL_OFFSET(gp)

	slli	r19, r15, 8
	ori		r19, r19, EPCS_COMMAND_READ
	movi	r3, 4
 sub_epcs_set_address_loop:
	call	sub_epcs_tx_rx_byte
	roli	r19, r19, 8
	DEC		r3
	bne		r3, zero, sub_epcs_set_address_loop

	br		sub_epcs_read_int_entry


/*-------------------------------------
  EPCS����S�o�C�g��M���� 

   ���� : �Ȃ�
   �o�� : r21(epcs_resv_int)

   �Q�� : gp(epcs_base_address)
   �ύX : r21(epcs_resv_int), r19(epcs_send_data), r20(epcs_resv_data)
   			r2, r3
 -------------------------------------*/
sub_epcs_read_int:
	mov		fp, ra

  sub_epcs_read_int_entry:
	mov		r21, zero					# �Ԃ�l���N���A 
	mov		r19, zero					# ���M�f�[�^��0 

	movi	r3, 4
  sub_epcs_read_int_loop:
	call	sub_epcs_tx_rx_byte			# �o�C�g�f�[�^����M 
	or		r21, r21, r20
	roli	r21, r21, 24				# 8�r�b�g�E���[�e�[�g
	DEC		r3
	bne		r3, zero, sub_epcs_read_int_loop

	mov		ra, fp
	ret


/*-------------------------------------
  EPCS����P�o�C�g����M���� 

   ���� : r19(epcs_send_data)
   �o�� : r20(epcs_resv_data)

   �Q�� : r19(epcs_send_data), gp(epcs_base_address)
   �ύX : r20(epcs_resv_data), r2
 -------------------------------------*/
sub_epcs_tx_rx_byte:

  sub_epcs_tx_ready_loop:
	ldwio	r2, EPCS_STATUS_OFFSET(gp)
	andi	r2, r2, EPCS_STATUS_TRDY_MASK
	beq		r2, zero, sub_epcs_tx_ready_loop

	andi	r2, r19, 0xff
	stwio	r2, EPCS_TXDATA_OFFSET(gp)

  sub_epcs_rx_ready_loop:
	ldwio	r2, EPCS_STATUS_OFFSET(gp)
	andi	r2, r2, EPCS_STATUS_RRDY_MASK
	beq		r2, zero, sub_epcs_rx_ready_loop

	ldbuio	r20, EPCS_RXDATA_OFFSET(gp)

	ret


/*-------------------------------------
  EPCS�f�o�C�X���N���[�Y����

   ���� : �Ȃ�
   �o�� : �Ȃ�

   �Q�� : gp(epcs_base_address)
   �ύX : r2
 -------------------------------------*/
sub_epcs_dev_close:

 sub_epcs_close_ready_loop:
	ldwio	r2, EPCS_STATUS_OFFSET(gp)
	andi	r2, r2, EPCS_STATUS_TMT_MASK
	beq		r2, zero, sub_epcs_close_ready_loop

	stwio   zero, EPCS_CONTROL_OFFSET(gp)

	ret



.end
// end of file

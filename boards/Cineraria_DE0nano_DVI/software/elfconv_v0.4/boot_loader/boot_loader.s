/*-------------------------------------------
  boot_loader.s  v0.3

  (C)S.OSAFUNE, (C)2007-2011 J-7SYSTEM WORKS
 --------------------------------------------*/
/*
  Cineraria LMiコア向けブートローダ

  0x00000020 - 0x007FDFFF : プログラム領域 (8380384バイト)
  0x007FE000 - 0x007FFFFF : ブートプログラム領域(8192バイト)

  0x00000020 : Exceptionベクタおよびコード領域トップ 
  0x00800000 : スタックトップ 

  0x0F000000 : リセットベクタ 
  0x0F000010 : システムリエントリ（第一引数にEPCSロードエントリを指定する）
*/

.section ".text"
    .global reset
    .global _start
    .global main
	.global _system_entry


/*** 定数宣言 *****/

	.ifndef EPCS_PROGRAM_BASE
	.equ EPCS_PROGRAM_BASE,		0x40000			# プログラム情報格納位置 
	.endif

	.ifndef EPCS_CONTROLLER_BASE
	.equ EPCS_CONTROLLER_BASE,	0x00f00000		# epcs_controllerペリフェラルアドレス 
	.endif

	.ifndef EPCS_REG_OFFSET
	.equ EPCS_REG_OFFSET,		0x200			# epcs_controllerレジスタオフセット 
	.endif

#	.equ SYSTEM_ENV_BASE,		0x00000000		# システム環境引数メモリアドレス 
#	.equ SYSTEM_ENV_SIZE,		(256)			# システム環境引数サイズ 
#	.equ REG_7SEG_BASE,			0x10000220		# エラー表示用7セグLEDレジスタアドレス 
#	.equ REG_LED_BASE,			0x01000060		# エラー表示用LEDレジスタアドレス 


	.equ PROGRAM_ID,			0x434f5250		# プログラムID ('P''R''O''C')

	.equ ICACHE_MAX_SIZE,		(64*1024)		# NiosIIがサポートする最大の命令キャッシュサイズ 
	.equ ICACHE_LINE_SIZE,		(32)

	.equ EPCS_RXDATA_OFFSET,	(EPCS_REG_OFFSET+0)		# 受信データレジスタ 
	.equ EPCS_TXDATA_OFFSET,	(EPCS_REG_OFFSET+4)		# 送信データレジスタ 
	.equ EPCS_STATUS_OFFSET,	(EPCS_REG_OFFSET+8)		# ステータスレジスタ 
	.equ EPCS_CONTROL_OFFSET,	(EPCS_REG_OFFSET+12)	# コントロールレジスタ 
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



/*** マクロ命令宣言 *****/

	.macro	CPU_HALT				# 永久ループ
	cpu_halt_loop_\@:
		br		cpu_halt_loop_\@
	.endm

	.macro	MOVI32 reg,imm32		# レジスタに32bit即値を代入 
	.if ((\imm32)& 0xffff0000)
		movhi	\reg, %hi(\imm32)
		.if ((\imm32)& 0x0000ffff)
			ori		\reg, \reg, %lo(\imm32)
		.endif
	.else
		movui	\reg, %lo(\imm32)
	.endif
	.endm

	.macro	INC reg					# インクリメント 
		addi	\reg,\reg,1
	.endm

	.macro	DEC reg					# デクリメント 
		subi	\reg,\reg,1
	.endm

	.macro	NOT reg					# ビット反転 
		nor		\reg,\reg,zero
	.endm


/*** ステータス表示 *****/

	.macro	LED_INIT_SET
	led_init_set_\@:
	.ifdef REG_7SEG_BASE
		MOVI32	r2, (~0x7c5c5c78)
		MOVI32	r3, REG_7SEG_BASE
		stwio	r2, 0(r3)			# "boot"表示 
	.else
	.ifdef REG_LED_BASE
		MOVI32	r3, REG_LED_BASE
		stwio	zero, 0(r3)			# LED消灯 
	.endif
	.endif
	.endm

	.macro	LED_ERROR_HALT
	led_error_halt_\@:
	.ifdef REG_7SEG_BASE
		MOVI32	r2, (~0x7950d03f)
		MOVI32	r3, REG_7SEG_BASE
		stwio	r2, 0(r3)			# "Err.0"表示 
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
  メインルーチン
 -------------------------------------*/
reset:
_start:
main:

	/*** ＣＰＵの初期化 *****/

	wrctl	status, zero				# ステータスレジスタを初期化 
	mov		r4, zero					# リセットは第一引数をゼロにする 

	nop
	nop

	/*** システムエントリ位置（ランチャー復帰位置） *****/
_system_entry:

	/*** 命令キャッシュの初期化 *****/

	MOVI32	r2, ICACHE_MAX_SIZE
 cache_loop:
	initi	r2							# 命令キャッシュを初期化 
	subi	r2, r2, ICACHE_LINE_SIZE
	bne		r2, zero, cache_loop

	flushp								# 命令パイプラインをクリア 


	/*** システム環境変数の初期化 *****/

	LED_INIT_SET						# LED表示初期化 

	bne		r4, zero, envclear_skip		# 第一引数がゼロでない場合は再エントリと判断する 

  .ifdef SYSTEM_ENV_BASE
	MOVI32	r2, SYSTEM_ENV_BASE
	MOVI32	r3, SYSTEM_ENV_BASE + SYSTEM_ENV_SIZE
   envclear_loop:
	stbio	zero, 0(r2)					# システム環境変数領域をクリア 
	INC		r2
	bne		r2, r3, envclear_loop
  .endif

	MOVI32	r4, EPCS_PROGRAM_BASE		# ブートプログラムエントリ位置 
 envclear_skip:


	/*** プログラムヘッダのチェック *****/

	MOVI32	gp, EPCS_CONTROLLER_BASE	# gp = epcs_reg_ptr
	mov		r15, r4						# r15 = epcs_data_ptr
	subi	r18, zero, 1				# r18 = 0xffffffff (定数)

	call	sub_epcs_dev_open			# EPCSデバイスをオープンしてIDをリード 
	call	sub_epcs_dev_close
	MOVI32	r2, PROGRAM_ID
	bne		r21, r2, program_not_found	# r21 = epcs_resv_int


	/*** プログラムデータの転送 *****/

program_copy:
	addi	r15, r15, 8					# ヘッダサイズを調整 
	call	sub_epcs_dev_open			# EPCSデバイスをオープンしてデータサイズを取得 

	beq		r21, r18, program_no_entry	# データサイズが-1ならエントリ無し 
	mov		r16, r21					# r16 = data_size
	call	sub_epcs_read_int
	beq		r16, zero, program_entry	# データサイズが0ならプログラムエントリ 

	mov		r17, r21					# r17 = dest_ptr
	mov		r19, zero					# 送信データを0クリア 

	MOVI32	r2, 0x80000000				# 圧縮フラグのチェック 
	and		r14, r16, r2				# r14 = 圧縮フラグ(=0なら実データ、!=0ならLZSS)
	NOT		r2
	and		r16, r16, r2
	add		r15, r15, r16				# データポインタ更新 

	add		r16, r16, r17				# r16 = end_dest_ptr


	/*** バイトデータをメモリへ転送 *****/

	beq		r14, zero, lzss_data_byte	# 非圧縮なら実バイト処理へ 

	call	sub_epcs_read_int			# オリジナルデータサイズを読み込む 
	add		r16, r21, r17				# r16 = end_dest_ptr

	mov		r5, zero					# r5 = lzss_riteral_count
lzss_decompress_loop:
										### 制御データの処理 #####
	beq		r5, zero, lzss_ctrl_byte_read
	slli	r6, r6, 1
	DEC		r5
	br		lzss_riteral_check

  lzss_ctrl_byte_read:					# CTRLバイトを新たに読み込む 
	call	sub_epcs_tx_rx_byte
	mov		r6, r20						# r6 = lzss_ctrl_byte
	movi	r5, 7

  lzss_riteral_check:
	andi	r2, r6, LZSS_CTRLBIT_MASK
	bne		r2, zero, lzss_ref_word		# CTRLビットが1なら参照データ 


  lzss_data_byte:						### 実データの処理 #####
	call	sub_epcs_tx_rx_byte			# 実データを読み込む(1バイト)

	mov		r4, zero					# 参照ループをしないよう設定 
	br		lzss_bytedata_store			# メモリへ書き込む 

  lzss_ref_word:						### 参照データの処理 #####
	call	sub_epcs_tx_rx_byte			# 参照データを読み込む(2バイトビッグエンディアン)
 	slli	r4, r20, 8
	call	sub_epcs_tx_rx_byte
	or		r20, r20, r4
	beq		r20, zero, section_data_copy_exit
										# 参照データが0の場合はエンドコード 

	srli	r3, r20, LZSS_REFADDR_SHIFT	# r3 = ref_data_addr_offs
	andi	r4, r20, LZSS_CLBIT_MASK
	addi	r4, r4, 2					# r4 = ref_data_count

  lzss_ref_copy_loop:					### 過去データをコピー #####
	sub		r2, r17, r3					# ref_addr = dest_ptr - ref_data_addr_offs
 	ldbuio	r20, 0(r2)
	DEC		r4


  lzss_bytedata_store:					### メモリへデータを書き込む #####
	stbio	r20, 0(r17)					# r20 = 書き込むバイトデータ 
	INC		r17							# destポインタを更新 
	beq		r17, r16, section_data_copy_exit
	bne		r4, zero, lzss_ref_copy_loop

	beq		r14, zero, lzss_data_byte	# 非圧縮なら実バイト処理部へ戻る 
	br		lzss_decompress_loop


section_data_copy_exit:
	call	sub_epcs_dev_close
	br		program_copy


	/*** プログラムを実行 *****/

program_entry:
	call	sub_epcs_dev_close
    callr	r21							# ロードしたプログラムへジャンプ 

#	CPU_HALT	# ここには戻ってこない 


	/*** プログラムエントリが無い *****/

program_no_entry:
	call	sub_epcs_dev_close

#	LED_ERROR_HALT


	/*** プログラムデータが見つからない *****/

program_not_found:

	LED_ERROR_HALT



/*-------------------------------------
  EPCSデバイスを開いて最初の4バイトを取得 

   入力 : r15(epcs_addr)
   出力 : r21(epcs_resv_int)

   参照 : r15(epcs_addr), gp(epcs_base_address)
   変更 : r19(epcs_send_data), r20(epcs_resv_data), r21(epcs_resv_int)
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
  EPCSから４バイト受信する 

   入力 : なし
   出力 : r21(epcs_resv_int)

   参照 : gp(epcs_base_address)
   変更 : r21(epcs_resv_int), r19(epcs_send_data), r20(epcs_resv_data)
   			r2, r3
 -------------------------------------*/
sub_epcs_read_int:
	mov		fp, ra

  sub_epcs_read_int_entry:
	mov		r21, zero					# 返り値をクリア 
	mov		r19, zero					# 送信データは0 

	movi	r3, 4
  sub_epcs_read_int_loop:
	call	sub_epcs_tx_rx_byte			# バイトデータを受信 
	or		r21, r21, r20
	roli	r21, r21, 24				# 8ビット右ローテート
	DEC		r3
	bne		r3, zero, sub_epcs_read_int_loop

	mov		ra, fp
	ret


/*-------------------------------------
  EPCSから１バイト送受信する 

   入力 : r19(epcs_send_data)
   出力 : r20(epcs_resv_data)

   参照 : r19(epcs_send_data), gp(epcs_base_address)
   変更 : r20(epcs_resv_data), r2
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
  EPCSデバイスをクローズする

   入力 : なし
   出力 : なし

   参照 : gp(epcs_base_address)
   変更 : r2
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

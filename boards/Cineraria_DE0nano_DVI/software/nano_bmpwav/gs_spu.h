/**************************************************************************
	PROCYON コンソールライブラリ「nd_Lib」 (Cineraria Edition)

		ＳＰＵサポート関数ヘッダ

 **************************************************************************/
#ifndef __gs_spu_h_
#define __gs_spu_h_


/***** 定数・マクロ定義 ***************************************************/

#ifndef spudef_samplefreq
#define spudef_samplefreq		(44100)		// サンプリング周波数 44.1kHz 
#endif

#ifndef spudef_slotmax
#define spudef_slotmax			(63)		// スロット数 
#endif

#define spu_drive_bitmask		(1<<15)
#define spu_mute_enable			(1<<12)
#define spu_overload_bitmask	(1<<11)
#define spu_sysirq_bitmask		(1<<10)
#define spu_sysirq_enable		(1<<9)
#define spu_irqnumber_bitmask	(0x007f)
#define spu_extwait_bitmask		(1<<15)
#define spu_romwait_bitmask		(0x7f<<8)
#define spu_fs_riseegde			(1<<7)
#define spu_fs_fallegde			(0<<7)
#define spu_slotnumber_bitmask	(0x007f)
#define spu_syncbusy_bitmask	(1<<0)
//#define spu_envirq_enable		(1<<15)
//#define spu_envirq_bitmask		(1<<14)
//#define spu_envirq_clear		(~(1<<14))
#define spu_envtimer_enable		(1<<13)
#define spu_envtimer_bitmask	(0x0fff)
#define spu_dectable_write		(1<<24)
#define spu_aclink_reset		(1<<31)
#define spu_aclink_sync			(1<<30)
#define spu_aclink_status		(1<<29)
#define spu_aclink_write		(1<<24)

#define spu_busy_bitmask		(1<<15)
#define spu_keyon				(1<<14)
#define spu_noteon				spu_keyon
#define spu_keyoff				(1<<13)
#define spu_noteoff				spu_keyoff
#define spu_keyon_invalid		(1<<12)
#define spu_loophist_bitmask	(1<<11)
#define spu_loophist_clear		(~(1<<11))
#define spu_slotirq_bitmask		(1<<10)
#define spu_slotirq_clear		(~(1<<10))
#define spu_slotirq_enable		(1<<9)
#define spu_phase_inverse		(1<<8)
#define spu_synckeyon_enable	(1<<7)
#define spu_synckeyoff_enable	(1<<6)
#define spu_envelope_enable		(1<<5)
#define spu_datatype_liner16	(2<<3)
#define spu_datatype_comp8		(1<<3)
#define spu_datatype_liner8		(0<<3)
#define spu_smooth_enable		(1<<2)
#define spu_loop_enable			(1<<1)
#define spu_noise_enable		(1<<0)

#define spu_envsd_bitmask		(0x0f<<27)
#define spu_envsr_bitmask		(0x3f<<22)
#define spu_envrr_bitmask		(0x3f<<16)
#define spu_freq_bitmask		(0xffff)
#define spu_envelop(sd,sr,rr,fq)	((nd_reg32)( (((sd)&0x0f)<<27) | (((sr)&0x3f)<<22) | (((rr)&0x3f)<<27) | ((fq)&0xffff) ))

#define spu_voltl_bitmask		(0xff<<24)
#define spu_volaux0_bitmask		(0xff<<16)
#define spu_volrl_bitmask		(0xff<<8)
#define spu_volfl_bitmask		(0xff<<0)
#define spu_volume_l(tl,a0,rl,fl)	((nd_reg32)( (((tl)&0xff)<<24) | (((a0)&0xff)<<16) | (((rl)&0xff)<<8) | ((fl)&0xff) ))

#define spu_volaux1_bitmask		(0xff<<16)
#define spu_volrr_bitmask		(0xff<<8)
#define spu_volfr_bitmask		(0xff<<0)
#define spu_volume_r(a1,rr,fr)		((nd_reg32)( (((a1)&0xff)<<16) | (((rr)&0xff)<<8) | ((fr)&0xff) ))

#define spu_wrombank_bitmask	(3<<30)
#define spu_startaddr_bitmask	(0x3fffffff)
#define spu_stopaddr_bitmask	(0x3fffffff)
#define spu_loopaddr_bitmask	(0x3fffffff)


/***** 構造体定義 *********************************************************/
#if 0
typedef volatile union {	/***** PROCYON_SPU レジスタマップ構造体 *****/

	volatile struct {		/* システムレジスタ (slot0)						*/
		nd_reg32 status;		/* SPUステータス							*/
		nd_reg32 setup;			/* SPUセットアップ							*/
		nd_reg32 sync;			/* SPU同期									*/
		nd_reg32 envtimer;		/* エンベロープタイマ						*/
		nd_reg32 system_id;		/* SPU-ID(リードのみ)						*/
		nd_reg32 dec_table;		/* 圧縮PCM展開テーブルアクセスレジスタ		*/
		nd_reg32 ac_link;		/* AC97-Codecアクセスレジスタ				*/
		nd_reg32 reserved0;
	} system;

	volatile struct {		/* スロットレジスタ (slot1～31)					*/
		nd_reg32 status;		/* スロットステータス						*/
		nd_reg32 envelope;		/* エンベロープ設定							*/
		nd_reg32 volume_l;		/* 左チャネルボリューム						*/
		nd_reg32 volume_r;		/* 右チャネルボリューム						*/
		nd_reg32 play_addr;		/* 再生アドレス(リードのみ)					*/
		nd_reg32 start_addr;	/* 再生開始アドレスポインタ					*/
		nd_reg32 end_addr;		/* 再生終了アドレスポインタ					*/
		nd_reg32 loop_addr;		/* ループアドレスポインタ					*/
	} slot[spudef_slotmax+1];
} np_spu;
#endif

// システムレジスタ(reg00～reg07) 
#define spu_reg_status			(0)				// reg00 : SPUステータスレジスタ 
#define spu_reg_setup			(1)				// reg01 : SPUセットアップレジスタ 
#define spu_reg_sync			(2)				// reg02 : SPU同期発行レジスタ 
#define spu_reg_envtimer		(3)				// reg03 : エンベロープタイマレジスタ 
#define spu_reg_systemid		(4)				// reg04 : SPU-ID(リードのみ) 
#define spu_reg_dectable		(5)				// reg05 : 圧縮PCM展開テーブルアクセスレジスタ 
#define spu_reg_aclink			(6)				// reg06 : AC97-Codecアクセスレジスタ 

// スロットレジスタ(reg08～regFF) 
#define spu_reg_slotstatus(_x)	(((_x)<<3)+0)	//   +00 : スロットステータスレジスタ 
#define spu_reg_envelope(_x)	(((_x)<<3)+1)	//   +01 : エンベロープ設定レジスタ 
#define spu_reg_volume_l(_x)	(((_x)<<3)+2)	//   +02 : 左チャネルボリュームレジスタ 
#define spu_reg_volume_r(_x)	(((_x)<<3)+3)	//   +03 : 右チャネルボリュームレジスタ 
#define spu_reg_playaddr(_x)	(((_x)<<3)+4)	//   +04 : 再生アドレス(リードのみ) 
#define spu_reg_startaddr(_x)	(((_x)<<3)+5)	//   +05 : 開始アドレスレジスタ	
#define spu_reg_stopaddr(_x)	(((_x)<<3)+6)	//   +06 : 終了アドレスレジスタ	
#define spu_reg_loopaddr(_x)	(((_x)<<3)+7)	//   +07 : ループアドレスレジスタ 


/***** プロトタイプ宣言 ***************************************************/

// ペリフェラル初期化 
int spu_init(alt_u32 dev_pcm);

// WAVファイル再生開始 
int spu_stream_play(const char *wavname,int volume);

// リングバッファのフィル 
int spu_bufferfill(void);

// 再生終了 
int spu_stream_stop(void);



#endif
/**************************************************************************/

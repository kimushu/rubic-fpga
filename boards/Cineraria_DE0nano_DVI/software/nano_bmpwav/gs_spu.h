/**************************************************************************
	PROCYON �R���\�[�����C�u�����und_Lib�v (Cineraria Edition)

		�r�o�t�T�|�[�g�֐��w�b�_

 **************************************************************************/
#ifndef __gs_spu_h_
#define __gs_spu_h_


/***** �萔�E�}�N����` ***************************************************/

#ifndef spudef_samplefreq
#define spudef_samplefreq		(44100)		// �T���v�����O���g�� 44.1kHz 
#endif

#ifndef spudef_slotmax
#define spudef_slotmax			(63)		// �X���b�g�� 
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


/***** �\���̒�` *********************************************************/
#if 0
typedef volatile union {	/***** PROCYON_SPU ���W�X�^�}�b�v�\���� *****/

	volatile struct {		/* �V�X�e�����W�X�^ (slot0)						*/
		nd_reg32 status;		/* SPU�X�e�[�^�X							*/
		nd_reg32 setup;			/* SPU�Z�b�g�A�b�v							*/
		nd_reg32 sync;			/* SPU����									*/
		nd_reg32 envtimer;		/* �G���x���[�v�^�C�}						*/
		nd_reg32 system_id;		/* SPU-ID(���[�h�̂�)						*/
		nd_reg32 dec_table;		/* ���kPCM�W�J�e�[�u���A�N�Z�X���W�X�^		*/
		nd_reg32 ac_link;		/* AC97-Codec�A�N�Z�X���W�X�^				*/
		nd_reg32 reserved0;
	} system;

	volatile struct {		/* �X���b�g���W�X�^ (slot1�`31)					*/
		nd_reg32 status;		/* �X���b�g�X�e�[�^�X						*/
		nd_reg32 envelope;		/* �G���x���[�v�ݒ�							*/
		nd_reg32 volume_l;		/* ���`���l���{�����[��						*/
		nd_reg32 volume_r;		/* �E�`���l���{�����[��						*/
		nd_reg32 play_addr;		/* �Đ��A�h���X(���[�h�̂�)					*/
		nd_reg32 start_addr;	/* �Đ��J�n�A�h���X�|�C���^					*/
		nd_reg32 end_addr;		/* �Đ��I���A�h���X�|�C���^					*/
		nd_reg32 loop_addr;		/* ���[�v�A�h���X�|�C���^					*/
	} slot[spudef_slotmax+1];
} np_spu;
#endif

// �V�X�e�����W�X�^(reg00�`reg07) 
#define spu_reg_status			(0)				// reg00 : SPU�X�e�[�^�X���W�X�^ 
#define spu_reg_setup			(1)				// reg01 : SPU�Z�b�g�A�b�v���W�X�^ 
#define spu_reg_sync			(2)				// reg02 : SPU�������s���W�X�^ 
#define spu_reg_envtimer		(3)				// reg03 : �G���x���[�v�^�C�}���W�X�^ 
#define spu_reg_systemid		(4)				// reg04 : SPU-ID(���[�h�̂�) 
#define spu_reg_dectable		(5)				// reg05 : ���kPCM�W�J�e�[�u���A�N�Z�X���W�X�^ 
#define spu_reg_aclink			(6)				// reg06 : AC97-Codec�A�N�Z�X���W�X�^ 

// �X���b�g���W�X�^(reg08�`regFF) 
#define spu_reg_slotstatus(_x)	(((_x)<<3)+0)	//   +00 : �X���b�g�X�e�[�^�X���W�X�^ 
#define spu_reg_envelope(_x)	(((_x)<<3)+1)	//   +01 : �G���x���[�v�ݒ背�W�X�^ 
#define spu_reg_volume_l(_x)	(((_x)<<3)+2)	//   +02 : ���`���l���{�����[�����W�X�^ 
#define spu_reg_volume_r(_x)	(((_x)<<3)+3)	//   +03 : �E�`���l���{�����[�����W�X�^ 
#define spu_reg_playaddr(_x)	(((_x)<<3)+4)	//   +04 : �Đ��A�h���X(���[�h�̂�) 
#define spu_reg_startaddr(_x)	(((_x)<<3)+5)	//   +05 : �J�n�A�h���X���W�X�^	
#define spu_reg_stopaddr(_x)	(((_x)<<3)+6)	//   +06 : �I���A�h���X���W�X�^	
#define spu_reg_loopaddr(_x)	(((_x)<<3)+7)	//   +07 : ���[�v�A�h���X���W�X�^ 


/***** �v���g�^�C�v�錾 ***************************************************/

// �y���t�F���������� 
int spu_init(alt_u32 dev_pcm);

// WAV�t�@�C���Đ��J�n 
int spu_stream_play(const char *wavname,int volume);

// �����O�o�b�t�@�̃t�B�� 
int spu_bufferfill(void);

// �Đ��I�� 
int spu_stream_stop(void);



#endif
/**************************************************************************/

----------------------------------------------------------------------
-- TITLE : Loreley-WSG Delta-Sigma DAC output module
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2007/02/18 -> 2007/02/18 (HERSTELLUNG)
--               : 2007/02/21 (FESTSTELLUNG)
--
--               : 2009/01/03 1bit�o�͉���
--               : 2009/01/14 �p�����[�^���C��
--               : 2011/08/22 �ړ����σt�B���^�i���C�� (NEUBEARBEITUNG)
----------------------------------------------------------------------

-- ���ړ����σt�B���^�X�e�[�W 
--   M=1�̈ړ����ςk�o�e���\������B 

-- �����`��ԃX�e�[�W 
--   ���`��Ԃ̂��߁A���M��f(t)�ɑ΂��āA1/(2n-1)^2 * f((2n-1)*t)�� 
--   �����m�C�Y���d�􂷂�B 
--
--    ���M��  �R��  �T��  �V��  �X��  11��  13��  �d�d 
--      0dB  -19dB -27dB -33dB -38dB -41dB -44dB 

-- ���o�͇����ϒ��X�e�[�W 
--   �t���X�s�[�h�œ��삷��P�r�b�g�P�������ϒ��u���b�N�B 

-- ���o�͂k�o�e
--   fo=19kHz(R=820��,C=0.01��F)��CR�P��LPF���o�̓s���ߖT�ɐڑ��B 
--   ���̏ꍇ�ANq=LSB�_�ł̃��W�F�N�V������-19dB�ŁASNR��-55dB�B�܂� 
--   �m�C�Y�s�[�N��4fs(192kHz)�_�ł�-38dB�A���T���v�����O���g����8fs 
--   (352kHz)�_�ł�-50dB�ƂȂ�B 
--   Nq=LSB�ƂȂ�8/6fs����m�C�Y�s�[�N��4fs�ɂ����āASNR���ቺ���邽�� 
--   LPF�Ƀq�X�e���V�X���������f�q���g�p����Ɖ����̈����������B 
--   ��R�͋��������A�R���f���T�̓}�C���R���f���T�𐄏��B 
--
--   �������d������ꍇ�́A�����OPAMP�ɂ��Q���A�N�e�B�u�t�B���^�� 
--   ��i�ɐڑ����ĂR���\���ɂ���Ƃ悢�B 

-- ���|�b�v�m�C�Y
--   �����ϒ��̍\����A�d���������̃|�b�v�m�C�Y�͉��s�i�ł��Ȃ��� 
--   �Ȃ����A���W�b�N���\�[�X�Ƃ̃g���[�h�I�t�j�B 
--   �|�b�v�m�C�Y���s�s���ɂȂ�ꍇ�AAC�J�b�v�����O�R���f���T�̌�i�� 
--   �~���[�g�g�����W�X�^��z�u���邱�Ƃŉ��P�\�B 


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity wsg_dsdac is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset
		MUTE_LEVEL		: std_logic := '1';
		PCMBITWIDTH		: integer := 12;
		MLFP_STAGE		: string := "ON"	-- �ړ�����LFP�X�e�[�W��ON/OFF
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		mute_in		: in  std_logic;
		fs_timing	: in  std_logic;
		fs8_timing	: in  std_logic;
		fs128_timing: in  std_logic;		-- ���g�p 

		pcmdata_in	: in  std_logic_vector(PCMBITWIDTH-1 downto 0);
		dac_out		: out std_logic
	);
end wsg_dsdac;

architecture RTL of wsg_dsdac is
	signal pcma_reg		: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal pcmb_reg		: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal pcmq_sig		: std_logic_vector(PCMBITWIDTH downto 0);

	signal pcmin_reg	: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal delta_reg	: std_logic_vector(PCMBITWIDTH downto 0);
	signal osvpcm_reg	: std_logic_vector(PCMBITWIDTH+2 downto 0);

	signal pcm_sig		: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal add_sig		: std_logic_vector(PCMBITWIDTH downto 0);
	signal dse_reg		: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal dacout_reg	: std_logic;

begin

-- �ړ����σt�B���^�X�e�[�W -----

	process(clk,reset)begin
		if (reset=RESET_LEVEL) then
			pcma_reg <= (others=>'0');
			pcmb_reg <= (others=>'0');

		elsif (clk'event and clk=CLOCK_EDGE) then
			if (mute_in = MUTE_LEVEL) then
				pcma_reg <= (others=>'0');
				pcmb_reg <= (others=>'0');

			elsif (fs_timing='1') then
				pcma_reg <= pcmdata_in;
				pcmb_reg <= pcma_reg;

			end if;

		end if;
	end process;

GEN_MLFPON : if (MLFP_STAGE = "ON") generate

	pcmq_sig <= (pcma_reg(pcma_reg'left) & pcma_reg) + (pcmb_reg(pcmb_reg'left) & pcmb_reg);

	end generate;
GEN_MLFPOFF : if (MLFP_STAGE /= "ON") generate

	pcmq_sig <= pcma_reg & '0';

	end generate;


-- ���`�W�{�I�[�o�[�T���v�����O�X�e�[�W -----

	process(clk,reset)begin
		if (reset=RESET_LEVEL) then
			pcmin_reg  <= (others=>'0');
			delta_reg  <= (others=>'0');
			osvpcm_reg <= (others=>'0');

		elsif (clk'event and clk=CLOCK_EDGE) then
			if (fs_timing='1') then
				pcmin_reg  <= pcmq_sig(pcmq_sig'left downto 1);
				delta_reg  <=(pcmq_sig(pcmq_sig'left)& pcmq_sig(pcmq_sig'left downto 1)) - (pcmin_reg(pcmin_reg'left) & pcmin_reg);
				osvpcm_reg <= pcmin_reg & "000";

			elsif (fs8_timing='1') then
				osvpcm_reg <= osvpcm_reg + (delta_reg(delta_reg'left) & delta_reg(delta_reg'left) & delta_reg);

			end if;

		end if;
	end process;


-- �����ϒ��X�e�[�W -----

	pcm_sig(pcm_sig'left) <= not osvpcm_reg(osvpcm_reg'left);
	pcm_sig(pcm_sig'left-1 downto 0) <= osvpcm_reg(osvpcm_reg'left-1 downto 3);

	add_sig <= ('0' & pcm_sig) + ('0' & dse_reg);

	process(clk,reset)begin
		if (reset=RESET_LEVEL) then
			dse_reg    <= (others=>'0');
			dacout_reg <= '0';

		elsif (clk'event and clk=CLOCK_EDGE) then
			dse_reg    <= add_sig(add_sig'left-1 downto 0);
			dacout_reg <= add_sig(add_sig'left);

		end if;
	end process;


	-- DAC�o�� 

	dac_out <= dacout_reg;


end RTL;



----------------------------------------------------------------------
--   (C)2007,2009 Copyright J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------

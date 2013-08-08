----------------------------------------------------------------------
-- TITLE : Loreley-WSG Delta-Sigma S/PDIF Transmitter module
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2005/09/26 -> 2005/09/30 (HERSTELLUNG)
--               : 2006/01/14 (FESTSTELLUNG)
--
--               : 2009/01/09 �`���l���r�b�g�C�� (NEUBEARBEITUNG)
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity wsg_spdiftx is
	generic(
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset
		CLOCK_EDGE		: std_logic := '1'	-- Rise edge drive clock
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		clk_ena		: in  std_logic := '1';	-- 128fs Pulse width 1clock time
		first_frame	: out std_logic;
		end_frame	: out std_logic;

		pcmdata_l	: in  std_logic_vector(23 downto 0);
		pcmdata_r	: in  std_logic_vector(23 downto 0);

		empha_ena	: in  std_logic := '0';
		copy_ena	: in  std_logic := '1';
		copy_gen	: in  std_logic := '0';
		freq_code	: in  std_logic_vector(1 downto 0) := "00";	-- 00:44.1kHz / 10:48kHz / 11:32kHz

		spdif_out	: out std_logic
	);
end wsg_spdiftx;

architecture RTL of wsg_spdiftx is
	constant FRAME_MAX		: integer := 192-1;
	constant SUBFRAME_MAX	: integer := 2-1;
	constant PCM_L_SUBFRAME	: integer := 0;
	constant PCM_R_SUBFRAME	: integer := 1;

	constant CATEGORY_GENERAL		: std_logic_vector(7 downto 0) := "00000000";
	constant CATEGORY_CD			: std_logic_vector(7 downto 0) := "00000001";
	constant CATEGORY_MO			: std_logic_vector(7 downto 0) := "00001001";
	constant CATEGORY_MD			: std_logic_vector(7 downto 0) := "01001001";
	constant CATEGORY_BROADCAST		: std_logic_vector(7 downto 0) := "00001110";
	constant CATEGORY_BROADCAST_JP	: std_logic_vector(7 downto 0) := "00000100";
	constant CATEGORY_BROADCAST_EU	: std_logic_vector(7 downto 0) := "00001100";
	constant CATEGORY_BROADCAST_US	: std_logic_vector(7 downto 0) := "01100100";
	constant CATEGORY_SOFTWARE		: std_logic_vector(7 downto 0) := "01000100";
	constant CATEGORY_PCM_CODEC		: std_logic_vector(7 downto 0) := "10000010";
	constant CATEGORY_MIXER			: std_logic_vector(7 downto 0) := "10010010";
	constant CATEGORY_CONVERTER		: std_logic_vector(7 downto 0) := "10011010";
	constant CATEGORY_SAMPLER		: std_logic_vector(7 downto 0) := "10100010";
	constant CATEGORY_DAT			: std_logic_vector(7 downto 0) := "10000011";
	constant CATEGORY_VTR			: std_logic_vector(7 downto 0) := "10001011";
	constant CATEGORY_DCC			: std_logic_vector(7 downto 0) := "11000011";
	constant CATEGORY_SYNTH			: std_logic_vector(7 downto 0) := "10000101";
	constant CATEGORY_MIC			: std_logic_vector(7 downto 0) := "10001101";
	constant CATEGORY_ADC			: std_logic_vector(7 downto 0) := "10010110";
	constant CATEGORY_MEMORY		: std_logic_vector(7 downto 0) := "10001000";
	constant CATEGORY_TEST			: std_logic_vector(7 downto 0) := "11000000";

	constant CHANNEL_L				: std_logic_vector(3 downto 0) := "0001";
	constant CHANNEL_R				: std_logic_vector(3 downto 0) := "0010";

	constant CLKACCURACY_LEVEL2		: std_logic_vector(1 downto 0) := "00";
	constant CLKACCURACY_LEVEL3		: std_logic_vector(1 downto 0) := "10";
	constant CLKACCURACY_LEVEL1		: std_logic_vector(1 downto 0) := "01";

	constant B_PREAMBLE		: std_logic_vector(2 downto 0) := "001";
	constant M_PREAMBLE		: std_logic_vector(2 downto 0) := "100";
	constant W_PREAMBLE		: std_logic_vector(2 downto 0) := "010";

	signal frame_num		: integer range 0 to FRAME_MAX;
	signal subframe_num		: integer range 0 to SUBFRAME_MAX;
	signal amblecode_sig	: std_logic_vector(2 downto 0);
	signal pcmdata_sig		: std_logic_vector(23 downto 0);
	signal channel_sig		: std_logic_vector(3 downto 0);
	signal statbit_sig		: std_logic_vector(FRAME_MAX downto 0);
	signal userbit_sig		: std_logic_vector(FRAME_MAX downto 0);

	component spdif_subframe_enc
	generic(
		RESET_LEVEL		: std_logic := '1';
		CLOCK_EDGE		: std_logic := '1'
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		clk_ena		: in  std_logic := '1';

		frame_end	: out std_logic;

		amble_code	: in  std_logic_vector(2 downto 0);
		aux_code	: in  std_logic_vector(3 downto 0) := "0000";
		sample_code	: in  std_logic_vector(19 downto 0);
		valid_bit	: in  std_logic := '0';
		user_bit	: in  std_logic := '0';
		status_bit	: in  std_logic;

		spdif_out	: out std_logic
	);
	end component;
	signal frame_end_sig	: std_logic;
	signal status_bit_sig	: std_logic;
	signal user_bit_sig		: std_logic;

begin

	process(clk,reset)begin
		if (reset=RESET_LEVEL) then
			frame_num <= 0;
			subframe_num <= 0;

		elsif (clk'event and clk=CLOCK_EDGE) then
			if (clk_ena='1' and frame_end_sig='1') then

				if (subframe_num /= SUBFRAME_MAX) then	-- subframe���ő傩�ǂ��� 
					subframe_num <= subframe_num + 1;
				else
					subframe_num <= 0;
					if (frame_num /= FRAME_MAX) then	-- frame�����ő傩�ǂ��� 
						frame_num <= frame_num + 1;
					else
						frame_num <= 0;
					end if;
				end if;

			end if;
		end if;
	end process;

	first_frame <= '1' when(subframe_num=0) else '0';
	end_frame   <= '1' when(subframe_num=SUBFRAME_MAX) else '0';

	amblecode_sig <= B_PREAMBLE when(frame_num=0 and subframe_num=0)else
					 M_PREAMBLE when(frame_num/=0 and subframe_num=0)else
					 W_PREAMBLE;

	pcmdata_sig <= 	pcmdata_l when subframe_num=PCM_L_SUBFRAME else
					pcmdata_r when subframe_num=PCM_R_SUBFRAME else
					(others=>'X');

--	channel_sig <=	CHANNEL_L when subframe_num=PCM_L_SUBFRAME else
--					CHANNEL_R when subframe_num=PCM_R_SUBFRAME else
--					(others=>'X');
	channel_sig <=	(others=>'0');

	statbit_sig(0) <= '0';							-- �����p�R�[�h 
	statbit_sig(1) <= '0';							-- �I�[�f�B�I�f�[�^ 
	statbit_sig(2) <= copy_ena;						-- ���쌠���ݒ� 
	statbit_sig(4 downto 3) <= '0' & empha_ena;		-- �G���t�@�V�X�ݒ� 
	statbit_sig(5) <= '0';							-- �Q�`���l���I�[�f�B�I 
	statbit_sig(7 downto 6) <= "00";				-- ���[�h�O 
	statbit_sig(15 downto 8) <= CATEGORY_GENERAL	-- �@��J�e�S���ݒ� 
						xor(copy_gen & "0000000");	-- �\�[�X����ݒ� 
	statbit_sig(19 downto 16) <= "0000";			-- �\�[�X�ԍ��O 
	statbit_sig(23 downto 20) <= channel_sig;		-- �`���l���ԍ��w�� 
	statbit_sig(27 downto 24) <= "00" & freq_code;	-- �T���v�����O���g���ݒ� 
	statbit_sig(29 downto 28) <= CLKACCURACY_LEVEL2;	-- �N���b�N���x�ݒ� 

	statbit_sig(FRAME_MAX downto 30) <= (others=>'0');	-- �\�� 

	userbit_sig <= (others=>'0');					-- ���[�U�[�r�b�g 


	status_bit_sig <= statbit_sig(frame_num);
	user_bit_sig   <= userbit_sig(frame_num);

	U : spdif_subframe_enc
		generic map(
			RESET_LEVEL	=> RESET_LEVEL,
			CLOCK_EDGE	=> CLOCK_EDGE
		)
		port map(
			reset		=> reset,
			clk			=> clk,
			clk_ena		=> clk_ena,
			frame_end	=> frame_end_sig,
			amble_code	=> amblecode_sig,
			aux_code	=> pcmdata_sig(3 downto 0),
			sample_code	=> pcmdata_sig(23 downto 4),
			valid_bit	=> '0',
			user_bit	=> user_bit_sig,
			status_bit	=> status_bit_sig,
			spdif_out	=> spdif_out
		);


end RTL;



----------------------------------------------------------------------
--  S/PDIF �T�u�t���[���G���R�[�_ 
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity spdif_subframe_enc is
	generic(
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset
		CLOCK_EDGE		: std_logic := '1'	-- Rise edge drive clock
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		clk_ena		: in  std_logic := '1';

		frame_end	: out std_logic;

		amble_code	: in  std_logic_vector(2 downto 0);
		aux_code	: in  std_logic_vector(3 downto 0) := "0000";
		sample_code	: in  std_logic_vector(19 downto 0);
		valid_bit	: in  std_logic := '0';
		user_bit	: in  std_logic := '0';
		status_bit	: in  std_logic;

		spdif_out	: out std_logic
	);
end spdif_subframe_enc;

architecture RTL of spdif_subframe_enc is
	signal slot_counter	: std_logic_vector(5 downto 0);

	signal amblebit_sig	: std_logic_vector(7 downto 0);
	signal sendbit_sig	: std_logic_vector(31 downto 0);
	signal amble_reg	: std_logic_vector(2 downto 0);
	signal auxcode_reg	: std_logic_vector(3 downto 0);
	signal sample_reg	: std_logic_vector(19 downto 0);
	signal valid_reg	: std_logic;
	signal userbit_reg	: std_logic;
	signal status_reg	: std_logic;

	signal bit_reg		: std_logic;
	signal send_symbol	: std_logic;
	signal amble_symbol	: std_logic;
	signal party_reg	: std_logic;

	signal spdifout_sig	: std_logic;
	signal spdifout_reg	: std_logic;

begin

	amblebit_sig(3 downto 0) <= "0111";
	amblebit_sig(6 downto 4) <= amble_reg;
	amblebit_sig(7) <= '0';

	sendbit_sig(3 downto 0) <= "XXXX";
	sendbit_sig(7 downto 4) <= auxcode_reg;
	sendbit_sig(27 downto 8) <= sample_reg;
	sendbit_sig(28) <= valid_reg;
	sendbit_sig(29) <= userbit_reg;
	sendbit_sig(30) <= status_reg;
	sendbit_sig(31) <= party_reg;

	frame_end <= '1' when(slot_counter="111111") else '0';

	spdifout_sig <= amble_symbol when(slot_counter(5 downto 3)="000") else send_symbol;

	process(clk,reset)begin
		if (reset=RESET_LEVEL) then
			slot_counter <= (others=>'0');
			send_symbol  <= '0';
			party_reg    <= '0';
			spdifout_reg <= '0';

		elsif (clk'event and clk=CLOCK_EDGE) then
			if (clk_ena='1') then
				slot_counter <= slot_counter + '1';

				if (slot_counter="000000") then		-- ���o�f�[�^�̃��b�` 
					amble_reg   <= amble_code;
					auxcode_reg <= aux_code;
					sample_reg  <= sample_code;
					valid_reg   <= valid_bit;
					userbit_reg <= user_bit;
					status_reg  <= status_bit;
				end if;

				if (slot_counter(5 downto 3)="000") then
					party_reg <= '0';
					if (send_symbol='0') then		-- �v���A���u���V���{�� 
						amble_symbol <= amblebit_sig(CONV_INTEGER(slot_counter(2 downto 0)));
					else
						amble_symbol <= not amblebit_sig(CONV_INTEGER(slot_counter(2 downto 0)));
					end if;
				else
					if (slot_counter(0)='0') then	-- �O���V���{�� 
						bit_reg <= sendbit_sig(CONV_INTEGER(slot_counter(5 downto 1)));
						send_symbol <= not send_symbol;
					else							-- �㔼�V���{�� 
						party_reg <= party_reg xor bit_reg;
						if (bit_reg='1') then
							send_symbol <= not send_symbol;
						end if;
					end if;
				end if;

				spdifout_reg <= spdifout_sig;

			end if;
		end if;
	end process;

	spdif_out <= spdifout_reg;


end RTL;



----------------------------------------------------------------------
-- (C)2005,2006,2009 Copyright J-7SYSTEM Works. All rights Reserved.--
----------------------------------------------------------------------

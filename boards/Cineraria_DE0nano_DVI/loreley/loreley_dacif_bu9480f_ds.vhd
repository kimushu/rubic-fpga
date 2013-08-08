----------------------------------------------------------------------
-- TITLE : Loreley DAC I/F module (Cineraria DE0 Edition)
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2008/07/01 -> 2008/07/01 (HERSTELLUNG)
--               : 2008/07/01 (FESTSTELLUNG)
--
--               : 2010/12/30 BU9480F用作成
--               : 2011/08/20 1bitΔΣDACを追加 (FESTSTELLUNG)
--               : 2011/09/16 S/PDIFのclk_ena指定漏れ修正 (FESTSTELLUNG)
----------------------------------------------------------------------

-- 16bitPCMデータと15bitボリューム値から16bitのデータを生成 
-- 右詰め、MSBファースト、LRCK:Lch='H',Rch='L'、32bitデータ長で送信 

-- ボリューム値は0x4000(16384)が最大 
-- 0x4000を越えるデータを設定した場合はPCMデータのラップアラウンドを 
-- 起こすため、ボリューム値は前段で適宜マスクすること 
-- pcmdata入力およびvolume入力はレジスタ受けではないので、前段は 
-- レジスタ出力にすること 

-- clk_enaは128fsのタイミングパルスを入力する 
-- clkに128fsのクロックを入力する場合は'1'に固定してOK 

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_arith.all;

entity loreley_dacif_bu9480f_ds is
	generic(
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset
		CLOCK_EDGE		: std_logic := '1'	-- Rise edge drive clock
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		clk_ena		: in  std_logic := '1';	-- Pulse width 1clock time (128fs)
		fs_timing	: out std_logic;

		pcmdata_l	: in  std_logic_vector(15 downto 0);	-- 符号付き 
		pcmdata_r	: in  std_logic_vector(15 downto 0);
		volume_l	: in  std_logic_vector(14 downto 0);	-- 符号なし 
		volume_r	: in  std_logic_vector(14 downto 0);

		dac_bclk	: out std_logic;
		dac_lrck	: out std_logic;
		dac_data	: out std_logic;
		aud_l		: out std_logic;
		aud_r		: out std_logic;
		spdif		: out std_logic
	);
end loreley_dacif_bu9480f_ds;

architecture RTL of loreley_dacif_bu9480f_ds is
	signal bclkcount	: std_logic_vector(6 downto 0);
	signal datshift_reg	: std_logic_vector(31 downto 0);
	signal pcmlatch_reg	: std_logic_vector(15 downto 0);

	signal mul_a_sig	: std_logic_vector(15 downto 0);
	signal mul_b_sig	: std_logic_vector(15 downto 0);
	signal mulans_sig	: std_logic_vector(31 downto 0);
	signal mulans_reg	: std_logic_vector(31 downto 0);

	component multiple_16x16
	PORT (
		dataa		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
	end component;


	signal pcmdata_l_reg	: std_logic_vector(15 downto 0);
	signal pcmdata_r_reg	: std_logic_vector(15 downto 0);
	signal fs_timing_sig	: std_logic;
	signal fs8_timing_sig	: std_logic;
	signal mute_l_sig		: std_logic;
	signal mute_r_sig		: std_logic;

	component wsg_dsdac
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset
		MUTE_LEVEL		: std_logic;
		PCMBITWIDTH		: integer;
		MLFP_STAGE		: string
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		mute_in		: in  std_logic;
		fs_timing	: in  std_logic;
		fs8_timing	: in  std_logic;
		fs128_timing: in  std_logic;

		pcmdata_in	: in  std_logic_vector(PCMBITWIDTH-1 downto 0);	-- 符号付き入力 
		dac_out		: out std_logic
	);
	end component;

	component wsg_spdiftx
	generic(
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset
		CLOCK_EDGE		: std_logic := '1'	-- Rise edge drive clock
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		clk_ena		: in  std_logic;		-- 128fs timing signal (1clk pulse width)
		first_frame	: out std_logic;
		end_frame	: out std_logic;

		pcmdata_l	: in  std_logic_vector(23 downto 0);
		pcmdata_r	: in  std_logic_vector(23 downto 0);

		empha_ena	: in  std_logic := '0';
		copy_ena	: in  std_logic := '1';
		copy_gen	: in  std_logic := '0';
		freq_code	: in  std_logic_vector(1 downto 0);		-- 00:44.1kHz / 10:48kHz / 11:32kHz

		spdif_out	: out std_logic
	);
	end component;

begin

--==== マスターボリュームとDAC出力部 ================================

	-- マスターボリューム 

	mul_a_sig <= pcmdata_l      when bclkcount(6)='0' else pcmlatch_reg;
	mul_b_sig <= '0' & volume_l when bclkcount(6)='0' else '0' & volume_r;

--	mulans_sig <= mul_a_sig * mul_b_sig;	-- s16 x s16 -> s31

	multiple_16x16_inst : multiple_16x16
	PORT MAP (
		dataa	 => mul_a_sig,
		datab	 => mul_b_sig,
		result	 => mulans_sig
	);


	-- タイミングとシリアライズ 

	fs_timing <= bclkcount(6);

	dac_bclk <= bclkcount(0);
	dac_lrck <= bclkcount(6);
	dac_data <= datshift_reg(31);

	process(clk,reset)begin
		if (reset=RESET_LEVEL) then
			bclkcount  <= (others=>'0');
			mulans_reg <= (others=>'0');

		elsif (clk'event and clk=CLOCK_EDGE) then
			mulans_reg <= mulans_sig;

			if (clk_ena = '1') then
				bclkcount <= bclkcount + '1';

				if (bclkcount(0) = '1') then
					if (bclkcount(5 downto 1) = "11111") then
						datshift_reg(31 downto 16) <= (others=>'0');
						datshift_reg(15 downto  0) <= mulans_reg(29 downto 14);
					else
						datshift_reg <= datshift_reg(30 downto 0) & '0';
					end if;

					if (bclkcount(6 downto 1) = "011111") then
						pcmlatch_reg <= pcmdata_r;
					end if;
				end if;
			end if;

		end if;
	end process;



--==== 1bitDAC出力部 ================================================

	fs_timing_sig  <= '1' when bclkcount=0 else '0';
	fs8_timing_sig <= '1' when bclkcount(3 downto 0)=0 else '0';

	mute_l_sig <= '1' when volume_l=0 else '0';
	mute_r_sig <= '1' when volume_r=0 else '0';

	process(clk,reset)begin
		if (reset=RESET_LEVEL) then
			pcmdata_l_reg <= (others=>'0');
			pcmdata_r_reg <= (others=>'0');

		elsif (clk'event and clk=CLOCK_EDGE) then
			if (bclkcount = "0111111") then
				pcmdata_l_reg <= mulans_reg(29 downto 14);
			end if;

			if (bclkcount = "1111111") then
				pcmdata_r_reg <= mulans_reg(29 downto 14);
			end if;

		end if;
	end process;


	-- 1bitDACのインスタンス 

	U_DACL : wsg_dsdac
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		MUTE_LEVEL		=> '1',
		PCMBITWIDTH		=> 16,
		MLFP_STAGE		=> "OFF"
	)
	port map (
		clk				=> clk,
		reset			=> reset,
		mute_in			=> mute_l_sig,
		fs_timing		=> fs_timing_sig,
		fs8_timing		=> fs8_timing_sig,
		fs128_timing	=> '1',

		pcmdata_in		=> pcmdata_l_reg,
		dac_out			=> aud_l
	);

	U_DACR : wsg_dsdac
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		MUTE_LEVEL		=> '1',
		PCMBITWIDTH		=> 16,
		MLFP_STAGE		=> "OFF"
	)
	port map (
		clk				=> clk,
		reset			=> reset,
		mute_in			=> mute_r_sig,
		fs_timing		=> fs_timing_sig,
		fs8_timing		=> fs8_timing_sig,
		fs128_timing	=> '1',

		pcmdata_in		=> pcmdata_r_reg,
		dac_out			=> aud_r
	);


	-- S/PDIFのインスタンス 

	U_SPDIF : wsg_spdiftx
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL
	)
	port map (
		clk				=> clk,
		reset			=> reset,
		clk_ena			=> clk_ena,
		first_frame		=> open,
		end_frame		=> open,

		pcmdata_l		=> (pcmdata_l_reg & "00000000"),
		pcmdata_r		=> (pcmdata_r_reg & "00000000"),

		empha_ena		=> '0',
		copy_ena		=> '1',
		copy_gen		=> '0',
--		freq_code		=> "10",	-- 48kHz
		freq_code		=> "00",	-- 44.1kHz
--		freq_code		=> "11",	-- 32kHz

		spdif_out		=> spdif
	);


end RTL;



----------------------------------------------------------------------
--  (C)2010-2011 Copyright  J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------

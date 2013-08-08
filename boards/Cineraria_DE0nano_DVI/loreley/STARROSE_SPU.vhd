----------------------------------------------------------------------
-- TITLE : STARROSE Sound Processing Unit (Loreley Included for Cineraria DE0)
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2006/10/13 -> 2006/12/05 (HERSTELLUNG)
--               : 2006/12/05 (FESTSTELLUNG)
--
--               : 2008/07/01 DACインスタンスを変更
--               : 2010/12/29 波形リードをAvalonMMマスタに変更
--               : 2011/08/20 1bitDAC,SPDIF出力ポートを追加 (NEUBEARBEITUNG)
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity STARROSE_SPU is
	generic(
		CLOCK_EDGE		: std_logic := '1';		-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1'		-- Positive logic reset
	);
	port(
		test_fs_sync	: in  std_logic := '0';

	--==== Register-BUS I/F signal ===================================

		S_clk			: in  std_logic;		-- Loreley clock;
		S_reset			: in  std_logic;

		S_address		: in  std_logic_vector(10 downto 2);
		S_chipselect	: in  std_logic;
		S_read			: in  std_logic;
		S_write			: in  std_logic;
		S_byteenable	: in  std_logic_vector(3 downto 0);

		S_readdata		: out std_logic_vector(31 downto 0);
		S_writedata		: in  std_logic_vector(31 downto 0);

		S_waitrequest	: out std_logic;
		S_irq			: out std_logic;

	--==== ExtWaveBuffer I/F signal(S_clk syncro) ====================

		ext_address		: out std_logic_vector(24 downto 1);
		ext_read_n		: out std_logic;
		ext_readdata	: in  std_logic_vector(15 downto 0) := (others=>'X');

	--==== WaveROM BUS I/F signal ====================================

		M_clk			: in  std_logic;		-- AvalonMM Master clock;
		M_reset			: in  std_logic;

		M_address		: out std_logic_vector(24 downto 0);	-- only 8byte alignment
		M_readreq		: out std_logic;
		M_readdata		: in  std_logic_vector(15 downto 0);
		M_datavalid		: in  std_logic;
		M_burstcount	: out std_logic_vector(2 downto 0);		-- 4 burst fixed
		M_waitrequest	: in  std_logic;

	--==== DAC output signal =========================================

		clk_128fs		: in  std_logic;
		fs_sync			: out std_logic;
		dac_mute		: out std_logic;

		dac_bclk		: out std_logic;
		dac_lrck		: out std_logic;
		dac_data		: out std_logic;
		aud_l			: out std_logic;
		aud_r			: out std_logic;
		spdif			: out std_logic
	);
end STARROSE_SPU;

architecture RTL of STARROSE_SPU is
	signal dacvol_l_reg		: std_logic_vector(14 downto 0);
	signal dacvol_r_reg		: std_logic_vector(14 downto 0);
	signal dacvolsat_sig	: std_logic_vector(14 downto 0);

	component loreley_core
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic;
		SLOTNUM_WIDTH	: integer;
		SYSTEM_ID		: integer;
		CACHELINE_WIDTH	: integer;
		USE_SLOTIRQ		: string;
		USE_ENVELOPE	: string;
		USE_DECODETABLE	: string;
		FORCE_EXTFSEDGE	: std_logic;
		FORCE_EXTWAIT	: std_logic;
		DECODE_TABLE	: string;
		DEVICE_MAKER	: string;
		PCM_FL_OUT		: string;
		PCM_FR_OUT		: string;
		PCM_RL_OUT		: string;
		PCM_RR_OUT		: string;
		PCM_AUX0_OUT	: string;
		PCM_AUX1_OUT	: string
	);
	port(
		clk				: in  std_logic;
		reset			: in  std_logic;
		ignition		: in  std_logic;
		async_fs_in		: in  std_logic;
		sync_fs_out		: out std_logic;

		address			: in  std_logic_vector(11 downto 2);
		chipselect		: in  std_logic;
		read			: in  std_logic;
		write			: in  std_logic;
		byteenable		: in  std_logic_vector(3 downto 0);
		readdata		: out std_logic_vector(31 downto 0);
		writedata		: in  std_logic_vector(31 downto 0);
		waitrequest		: out std_logic;
		irq				: out std_logic;

		rom_slotnum		: out std_logic_vector(6 downto 0);
		rom_fillreq		: out std_logic;
		rom_bank		: out std_logic_vector(1 downto 0);
		rom_address		: out std_logic_vector(29 downto 1);
		rom_read_n		: out std_logic;
		rom_readdata	: in  std_logic_vector(15 downto 0);
		rom_waitrequest	: in  std_logic;

		pcmout_fl		: out std_logic_vector(15 downto 0);
		pcmout_fr		: out std_logic_vector(15 downto 0);
		pcmout_rl		: out std_logic_vector(15 downto 0);
		pcmout_rr		: out std_logic_vector(15 downto 0);
		pcmout_aux0		: out std_logic_vector(15 downto 0);
		pcmout_aux1		: out std_logic_vector(15 downto 0);
		mute_out		: out std_logic;

		aclink_rddata	: in  std_logic_vector(31 downto 0) := (others=>'X');
		aclink_wrdata	: out std_logic_vector(31 downto 0);
		aclink_write	: out std_logic
	);
	end component;
	signal S_address_sig	: std_logic_vector(11 downto 2);
	signal rom_slotnum_sig	: std_logic_vector(6 downto 0);
	signal rom_fillreq_sig	: std_logic;
	signal rom_bank_sig		: std_logic_vector(1 downto 0);
	signal rom_address_sig	: std_logic_vector(29 downto 1);
	signal rom_read_n_sig	: std_logic;
	signal rom_readdata_sig	: std_logic_vector(15 downto 0);
	signal rom_waitreq_sig	: std_logic;
	signal pcmout_l_sig		: std_logic_vector(15 downto 0);
	signal pcmout_r_sig		: std_logic_vector(15 downto 0);
	signal mute_out_sig		: std_logic;
	signal async_fs_sig		: std_logic;
	signal dac_wrdata_sig	: std_logic_vector(31 downto 0);
	signal dac_wrena_sig	: std_logic;


	component loreley_wromcache
	generic(
		RESET_LEVEL		: std_logic;
		CLOCK_EDGE		: std_logic;
		SLOTNUM_WIDTH	: integer
	);
	port(
		reset			: in  std_logic;
		clk				: in  std_logic;
		rom_extselect	: in  std_logic;
		rom_slotnum		: in  std_logic_vector(SLOTNUM_WIDTH-1 downto 0);
		rom_fillreq		: in  std_logic;
		rom_address		: in  std_logic_vector(24 downto 1);
		rom_read_n		: in  std_logic;
		rom_readdata	: out std_logic_vector(15 downto 0);
		rom_waitrequest	: out std_logic;

		ext_address		: out std_logic_vector(24 downto 1);
		ext_read_n		: out std_logic;
		ext_readdata	: in  std_logic_vector(15 downto 0);

		M_reset			: in  std_logic;
		M_clk			: in  std_logic;
		M_address		: out std_logic_vector(24 downto 0);	-- only 8byte alignment
		M_readreq		: out std_logic;
		M_readdata		: in  std_logic_vector(15 downto 0);
		M_datavalid		: in  std_logic;
		M_burstcount	: out std_logic_vector(2 downto 0);		-- 4 burst fixed
		M_waitrequest	: in  std_logic
	);
	end component;


	component loreley_dacif_bu9480f_ds
	generic(
		RESET_LEVEL		: std_logic := '1';
		CLOCK_EDGE		: std_logic := '1'
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		clk_ena		: in  std_logic;
		fs_timing	: out std_logic;

		pcmdata_l	: in  std_logic_vector(15 downto 0);
		pcmdata_r	: in  std_logic_vector(15 downto 0);
		volume_l	: in  std_logic_vector(14 downto 0);
		volume_r	: in  std_logic_vector(14 downto 0);

		dac_bclk	: out std_logic;
		dac_lrck	: out std_logic;
		dac_data	: out std_logic;
		aud_l		: out std_logic;
		aud_r		: out std_logic;
		spdif		: out std_logic
	);
	end component;
	signal fs_sig		: std_logic;

begin

	-- Loreleyコアのインスタンス 

	async_fs_sig <= fs_sig or test_fs_sync;

	S_address_sig <= "0" & S_address;

	U_core : loreley_core
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		SLOTNUM_WIDTH	=> 6,
		SYSTEM_ID		=> 16#0765_0100#,
		CACHELINE_WIDTH	=> 3,
		USE_SLOTIRQ		=> "ON",
		USE_ENVELOPE	=> "ON",
		USE_DECODETABLE	=> "ON",
		FORCE_EXTFSEDGE	=> '0',
		FORCE_EXTWAIT	=> '1',
		DECODE_TABLE	=> "RAM",
		DEVICE_MAKER	=> "ALTERA",
		PCM_FL_OUT		=> "ON",
		PCM_FR_OUT		=> "ON",
		PCM_RL_OUT		=> "OFF",
		PCM_RR_OUT		=> "OFF",
		PCM_AUX0_OUT	=> "OFF",
		PCM_AUX1_OUT	=> "OFF"
	)
	port map (
		clk				=> S_clk,
		reset			=> S_reset,
		ignition		=> '1',
		async_fs_in		=> async_fs_sig,
		sync_fs_out		=> fs_sync,

		address			=> S_address_sig,
		chipselect		=> S_chipselect,
		read			=> S_read,
		write			=> S_write,
		byteenable		=> S_byteenable,
		readdata		=> S_readdata,
		writedata		=> S_writedata,
		waitrequest		=> S_waitrequest,
		irq				=> S_irq,

		rom_slotnum		=> rom_slotnum_sig,
		rom_fillreq		=> rom_fillreq_sig,
		rom_bank		=> rom_bank_sig,
		rom_address		=> rom_address_sig,
		rom_read_n		=> rom_read_n_sig,
		rom_readdata	=> rom_readdata_sig,
		rom_waitrequest	=> rom_waitreq_sig,

		pcmout_fl		=> pcmout_l_sig,
		pcmout_fr		=> pcmout_r_sig,
		mute_out		=> mute_out_sig,

		aclink_wrdata	=> dac_wrdata_sig,
		aclink_write	=> dac_wrena_sig
	);


	-- 波形ROMキャッシュのインスタンス 

	U_cache : loreley_wromcache
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		SLOTNUM_WIDTH	=> 6
	)
	port map (
		reset			=> S_reset,
		clk				=> S_clk,
		rom_extselect	=> rom_bank_sig(0),
		rom_slotnum		=> rom_slotnum_sig(5 downto 0),
		rom_fillreq		=> rom_fillreq_sig,
		rom_address		=> rom_address_sig(24 downto 1),
		rom_read_n		=> rom_read_n_sig,
		rom_readdata	=> rom_readdata_sig,
		rom_waitrequest	=> rom_waitreq_sig,

		ext_address		=> ext_address,
		ext_read_n		=> ext_read_n,
		ext_readdata	=> ext_readdata,

		M_reset			=> M_reset,
		M_clk			=> M_clk,
		M_address		=> M_address,
		M_readreq		=> M_readreq,
		M_readdata		=> M_readdata,
		M_datavalid		=> M_datavalid,
		M_burstcount	=> M_burstcount,
		M_waitrequest	=> M_waitrequest
	);


	-- DACのインスタンス 

	dacvolsat_sig <= dac_wrdata_sig(14 downto 0) when dac_wrdata_sig(15 downto 14)="00" else
						(14=>'1',others=>'0');			-- 設定データを飽和 

	process(S_clk,S_reset)begin							-- DAC制御レジスタ 
		if (S_reset=RESET_LEVEL) then
			dacvol_l_reg <= (14=>'1',others=>'0');
			dacvol_r_reg <= (14=>'1',others=>'0');

		elsif (S_clk'event and S_clk=CLOCK_EDGE) then
			if (dac_wrena_sig='1') then
				case dac_wrdata_sig(22 downto 16) is
				when "0000000" =>
					dacvol_l_reg <= dacvolsat_sig;

				when "0000001" =>
					dacvol_r_reg <= dacvolsat_sig;

				when others=>
				end case;
			end if;
		end if;
	end process;


	U_dac : loreley_dacif_bu9480f_ds
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL
	)
	port map (
		reset			=> S_reset,
		clk				=> clk_128fs,
		clk_ena			=> '1',
		fs_timing		=> fs_sig,

		pcmdata_l		=> pcmout_l_sig,
		pcmdata_r		=> pcmout_r_sig,
		volume_l		=> dacvol_l_reg,
		volume_r		=> dacvol_r_reg,

		dac_bclk		=> dac_bclk,
		dac_lrck		=> dac_lrck,
		dac_data		=> dac_data,
		aud_l			=> aud_l,
		aud_r			=> aud_r,
		spdif			=> spdif
	);

	dac_mute <= mute_out_sig;


end RTL;



----------------------------------------------------------------------
--   (C)2005-2011 Copyright J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------

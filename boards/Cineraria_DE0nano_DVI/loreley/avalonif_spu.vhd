----------------------------------------------------------------------
-- TITLE : STARROSE_SPU AvalonBUS Interface
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2006/12/05 -> 2007/01/11 (HERSTELLUNG)
--               : 2007/01/19 (FESTSTELLUNG)
--
--               : 2008/07/01 AMETHYST用に改版
--               : 2008/07/05 波形バッファを削除
--               : 2010/12/29 波形リードをAvalonMMマスタに変更 
--               : 2011/08/20 1bitDAC,S/PDIF出力ポートを追加 
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity avalonif_spu is
	port(
		csi_global_reset	: in  std_logic;
		csi_global_clock	: in  std_logic;

	--==== Avalonバス信号線(SPU) ======================================
		avs_s1_address		: in  std_logic_vector(10 downto 2);
		avs_s1_chipselect	: in  std_logic;
		avs_s1_read			: in  std_logic;
		avs_s1_write		: in  std_logic;
		avs_s1_byteenable	: in  std_logic_vector(3 downto 0);
		avs_s1_readdata		: out std_logic_vector(31 downto 0);
		avs_s1_writedata	: in  std_logic_vector(31 downto 0);
		avs_s1_waitrequest	: out std_logic;
		avs_s1_irq			: out std_logic;

	--==== 波形メモリリードマスタ ====================================
		csi_m1_clock		: in  std_logic;

		avm_m1_address		: out std_logic_vector(24 downto 0);	-- only 8byte alignment
		avm_m1_burstcount	: out std_logic_vector(2 downto 0);		-- only 4 burst
		avm_m1_read			: out std_logic;
		avm_m1_readdata		: in  std_logic_vector(15 downto 0);
		avm_m1_readdatavalid: in  std_logic;
		avm_m1_waitrequest	: in  std_logic;

	--==== DAC信号線 =================================================
		clk_128fs		: in  std_logic;

		DAC_BCLK		: out std_logic;
		DAC_LRCK		: out std_logic;
		DAC_DATA		: out std_logic;
		AUD_L			: out std_logic;
		AUD_R			: out std_logic;
		SPDIF			: out std_logic
	);
end avalonif_spu;

architecture RTL of avalonif_spu is

	component STARROSE_SPU
	generic(
		CLOCK_EDGE		: std_logic := '1';
		RESET_LEVEL		: std_logic := '1'
	);
	port(
		test_fs_sync	: in  std_logic := '0';

		S_clk			: in  std_logic;
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

		ext_address		: out std_logic_vector(24 downto 1);
		ext_read_n		: out std_logic;
		ext_readdata	: in  std_logic_vector(15 downto 0) := (others=>'X');

		M_clk			: in  std_logic;
		M_reset			: in  std_logic;
		M_address		: out std_logic_vector(24 downto 0);
		M_readreq		: out std_logic;
		M_readdata		: in  std_logic_vector(15 downto 0);
		M_datavalid		: in  std_logic;
		M_burstcount	: out std_logic_vector(2 downto 0);
		M_waitrequest	: in  std_logic;

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
	end component;
--	signal spu_bus_out_sig	: std_logic_vector(24 downto 0);
--	signal spu_bus_in_sig	: std_logic_vector(16 downto 0);
--	signal dac_mute_sig		: std_logic;

begin

--==== SPUインスタンス ===============================================

	U4 : STARROSE_SPU
	generic map (
		CLOCK_EDGE		=> '1',
		RESET_LEVEL		=> '1'
	)
	port map(
		test_fs_sync	=> '0',

		S_clk			=> csi_global_clock,
		S_reset			=> csi_global_reset,
		S_address		=> avs_s1_address,
		S_chipselect	=> avs_s1_chipselect,
		S_read			=> avs_s1_read,
		S_write			=> avs_s1_write,
		S_byteenable	=> avs_s1_byteenable,
		S_readdata		=> avs_s1_readdata,
		S_writedata		=> avs_s1_writedata,
		S_waitrequest	=> avs_s1_waitrequest,
		S_irq			=> avs_s1_irq,

		ext_address		=> open,
		ext_read_n		=> open,
		ext_readdata	=> (others=>'X'),

		M_clk			=> csi_m1_clock,
		M_reset			=> csi_global_reset,
		M_address		=> avm_m1_address,
		M_readreq		=> avm_m1_read,
		M_readdata		=> avm_m1_readdata,
		M_datavalid		=> avm_m1_readdatavalid,
		M_burstcount	=> avm_m1_burstcount,
		M_waitrequest	=> avm_m1_waitrequest,

		clk_128fs		=> clk_128fs,
		fs_sync			=> open,
		dac_mute		=> open,
		dac_bclk		=> DAC_BCLK,
		dac_lrck		=> DAC_LRCK,
		dac_data		=> DAC_DATA,
		aud_l			=> AUD_L,
		aud_r			=> AUD_R,
		spdif			=> SPDIF
	);


end RTL;



----------------------------------------------------------------------
--   (C)2003-2011 Copyright J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------

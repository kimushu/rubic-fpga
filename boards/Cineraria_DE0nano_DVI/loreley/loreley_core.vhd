----------------------------------------------------------------------
-- TITLE : Loreley Core module
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2005/04/13 -> 2005/04/15 (HERSTELLUNG)
--               : 2005/04/15 (FESTSTELLUNG)
--
--               : 2006/09/28 エンベロープモード追加 (1772LEs)
--               : 2006/10/12 波形キャッシュ信号追加 (NEUBEARBEITUNG) (1766LEs)
--               : 2006/12/02 波形補間モード追加 (NEUBEARBEITUNG) (1993LEs)
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity loreley_core is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset

		SLOTNUM_WIDTH	: integer := 7;
		SYSTEM_ID		: integer := 16#0765_0000#;
		CACHELINE_WIDTH	: integer := 3;		-- WROM CacheLine width(3=8byte,4=16byte,5=32byte)
		USE_SLOTIRQ		: string := "ON";
		USE_ENVELOPE	: string := "ON";
		USE_DECODETABLE	: string := "ON";
		FORCE_EXTFSEDGE	: std_logic := '0';
		FORCE_EXTWAIT	: std_logic := '0';
--		DECODE_TABLE	: string := "ROM_C352COMPRESS";
--		DECODE_TABLE	: string := "ROM_ALAWCOMPRESS";
--		DECODE_TABLE	: string := "ROM_ULAWCOMPRESS";
		DECODE_TABLE	: string := "RAM";
		DEVICE_MAKER	: string := "ALTERA";
--		DEVICE_MAKER	: string := "XILINX";
--		DEVICE_MAKER	: string := "";

		PCM_FL_OUT		: string := "ON";
		PCM_FR_OUT		: string := "ON";
		PCM_RL_OUT		: string := "ON";
		PCM_RR_OUT		: string := "ON";
		PCM_AUX0_OUT	: string := "ON";
		PCM_AUX1_OUT	: string := "ON"
	);
	port(
		clk				: in  std_logic;	-- system clock
		reset			: in  std_logic;	-- async reset
		ignition		: in  std_logic := '1';	-- engine igniter signal

	--==== Fs sync generator signal ==================================

		async_fs_in		: in  std_logic;	-- Async fs signal input
		sync_fs_out		: out std_logic;	-- Fs sync signal (1clock width)

	--==== AvalonBUS I/F signal ======================================

		address			: in  std_logic_vector(11 downto 2);
		chipselect		: in  std_logic;
		read			: in  std_logic;
		write			: in  std_logic;
		byteenable		: in  std_logic_vector(3 downto 0);

		readdata		: out std_logic_vector(31 downto 0);
		writedata		: in  std_logic_vector(31 downto 0);

		waitrequest		: out std_logic;
		irq				: out std_logic;

	--==== WaveROM BUS I/F signal ====================================

		rom_slotnum		: out std_logic_vector(6 downto 0);
		rom_fillreq		: out std_logic;

		rom_bank		: out std_logic_vector(1 downto 0);
		rom_address		: out std_logic_vector(29 downto 1);
		rom_read_n		: out std_logic;
		rom_readdata	: in  std_logic_vector(15 downto 0);

		rom_waitrequest	: in  std_logic := '0';

	--==== Ch PCM data signal out ====================================

		pcmout_fl		: out std_logic_vector(15 downto 0);
		pcmout_fr		: out std_logic_vector(15 downto 0);
		pcmout_rl		: out std_logic_vector(15 downto 0);
		pcmout_rr		: out std_logic_vector(15 downto 0);
		pcmout_aux0		: out std_logic_vector(15 downto 0);
		pcmout_aux1		: out std_logic_vector(15 downto 0);

		mute_out		: out std_logic;

	--==== AC-LINK I/F signal ========================================

		aclink_rddata	: in  std_logic_vector(31 downto 0) := (others=>'X');
		aclink_wrdata	: out std_logic_vector(31 downto 0);
		aclink_write	: out std_logic

	);
end loreley_core;

architecture RTL of loreley_core is

	component loreley_businterface
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic;

		SLOTNUM_WIDTH	: integer;
		SYSTEM_ID		: integer;
		FORCE_EXTFSEDGE	: std_logic;
		FORCE_EXTWAIT	: std_logic;
		USE_SLOTIRQ		: string;
		USE_ENVELOPE	: string
	);
	port(
		clk				: in  std_logic;
		reset			: in  std_logic;

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

		sys_sync		: out std_logic;
		sys_slotnum		: out std_logic_vector(6 downto 0);
		sys_extwait		: out std_logic;
		sys_romwait		: out std_logic_vector(6 downto 0);
		sys_drive		: in  std_logic;
		sys_overload	: in  std_logic;
		env_renew		: out std_logic;
		irqslot			: in  std_logic;
		irqslot_num		: in  std_logic_vector(6 downto 0);
		mute_out		: out std_logic;

		ext_address		: out std_logic_vector(11 downto 2);
		ext_lock		: in  std_logic;
		ext_readdata	: in  std_logic_vector(31 downto 0);
		ext_writedata	: out std_logic_vector(31 downto 0);
		ext_writeenable	: out std_logic;

		dectable_rddata	: in  std_logic_vector(31 downto 0) := (others=>'X');
		dectable_wrdata	: out std_logic_vector(31 downto 0);
		dectable_write	: out std_logic;

		aclink_rddata	: in  std_logic_vector(31 downto 0) := (others=>'X');
		aclink_wrdata	: out std_logic_vector(31 downto 0);
		aclink_write	: out std_logic
	);
	end component;
	signal fs_sync_sig		: std_logic;
	signal sys_sync_sig		: std_logic;
	signal sys_slotnum_sig	: std_logic_vector(6 downto 0);
	signal sys_extwait_sig	: std_logic;
	signal sys_romwait_sig	: std_logic_vector(6 downto 0);
	signal slot_drive_sig	: std_logic;
	signal sys_overload_sig	: std_logic;
	signal env_renew_sig	: std_logic;
	signal irqslot_sig		: std_logic;
	signal irqslot_num_sig	: std_logic_vector(6 downto 0);
	signal reg_address_sig	: std_logic_vector(11 downto 2);
	signal reg_lock_sig		: std_logic;
	signal reg_rddata_sig	: std_logic_vector(31 downto 0);
	signal reg_wrdata_sig	: std_logic_vector(31 downto 0);
	signal reg_wrena_sig	: std_logic;
	signal dec_rddata_sig	: std_logic_vector(31 downto 0);
	signal dec_wrdata_sig	: std_logic_vector(31 downto 0);
	signal dec_write_sig	: std_logic;


	component loreley_slotengine
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic;

		SLOTNUM_WIDTH	: integer;
		CACHELINE_WIDTH	: integer;
		USE_SLOTIRQ		: string;
		USE_ENVELOPE	: string;
		DEVICE_MAKER	: string
	);
	port(
		clk				: in  std_logic;
		reset			: in  std_logic;
		ignition		: in  std_logic :='1';

		fs_sync			: in  std_logic;
		state_busy		: out std_logic;
		slot_drive		: out std_logic;

		sys_sync		: in  std_logic :='0';
		sys_slotnum		: in  std_logic_vector(6 downto 0);
		sys_extwait		: in  std_logic :='0';
		sys_romwait		: in  std_logic_vector(6 downto 0);
		irqslot			: out std_logic;
		irqslot_num		: out std_logic_vector(6 downto 0);
		env_renew		: in  std_logic :='0';

		ext_address		: in  std_logic_vector(11 downto 2);
		ext_lock		: out std_logic;
		ext_readdata	: out std_logic_vector(31 downto 0);
		ext_writedata	: in  std_logic_vector(31 downto 0);
		ext_writeenable	: in  std_logic;

		rom_slotnum		: out std_logic_vector(6 downto 0);
		rom_fillreq		: out std_logic;
		rom_bank		: out std_logic_vector(1 downto 0);
		rom_address		: out std_logic_vector(29 downto 1);
		rom_read_n		: out std_logic;
		rom_readdata	: in  std_logic_vector(15 downto 0);
		rom_waitrequest	: in  std_logic :='0';

		compress_data	: out std_logic_vector(7 downto 0);
		decompress_data	: in  std_logic_vector(15 downto 0);

		adder_start		: out std_logic;
		pcmdata			: out std_logic_vector(15 downto 0);
		volume_fl		: out std_logic_vector(7 downto 0);
		volume_fr		: out std_logic_vector(7 downto 0);
		volume_rl		: out std_logic_vector(7 downto 0);
		volume_rr		: out std_logic_vector(7 downto 0);
		volume_aux0		: out std_logic_vector(7 downto 0);
		volume_aux1		: out std_logic_vector(7 downto 0)
	);
	end component;
	signal engine_busy_sig	: std_logic;
	signal comp_data_sig	: std_logic_vector(7 downto 0);
	signal decomp_data_sig	: std_logic_vector(15 downto 0);
	signal adder_start_sig	: std_logic;
	signal pcmdata_sig		: std_logic_vector(15 downto 0);
	signal volume_fl_sig	: std_logic_vector(7 downto 0);
	signal volume_fr_sig	: std_logic_vector(7 downto 0);
	signal volume_rl_sig	: std_logic_vector(7 downto 0);
	signal volume_rr_sig	: std_logic_vector(7 downto 0);
	signal volume_aux0_sig	: std_logic_vector(7 downto 0);
	signal volume_aux1_sig	: std_logic_vector(7 downto 0);


	component loreley_decoder
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic;

		USE_DECODETABLE	: string;
		DECODE_TABLE	: string;
		DEVICE_MAKER	: string
	);
	port(
		clk				: in  std_logic;
		reset			: in  std_logic;

		compress_data	: in  std_logic_vector(7 downto 0);
		decompress_data	: out std_logic_vector(15 downto 0);

		dectable_rddata	: out std_logic_vector(31 downto 0);
		dectable_wrdata	: in  std_logic_vector(31 downto 0);
		dectable_write	: in  std_logic
	);
	end component;


	component loreley_waveadder
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic;
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

		fs_sync			: in  std_logic;
		start			: in  std_logic;
		state_busy		: out std_logic;

		pcmdata			: in  std_logic_vector(15 downto 0);
		volume_fl		: in  std_logic_vector(7 downto 0);
		volume_fr		: in  std_logic_vector(7 downto 0);
		volume_rl		: in  std_logic_vector(7 downto 0);
		volume_rr		: in  std_logic_vector(7 downto 0);
		volume_aux0		: in  std_logic_vector(7 downto 0);
		volume_aux1		: in  std_logic_vector(7 downto 0);

		pcmout_fl		: out std_logic_vector(15 downto 0);
		pcmout_fr		: out std_logic_vector(15 downto 0);
		pcmout_rl		: out std_logic_vector(15 downto 0);
		pcmout_rr		: out std_logic_vector(15 downto 0);
		pcmout_aux0		: out std_logic_vector(15 downto 0);
		pcmout_aux1		: out std_logic_vector(15 downto 0)
	);
	end component;
	signal adder_busy_sig	: std_logic;


begin


	-- バスインターフェース＆システムレジスタのインスタンス 

	sys_overload_sig <= engine_busy_sig or adder_busy_sig;

	U_busif : loreley_businterface
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		SLOTNUM_WIDTH	=> SLOTNUM_WIDTH,
		SYSTEM_ID		=> SYSTEM_ID,
		FORCE_EXTFSEDGE	=> FORCE_EXTFSEDGE,
		FORCE_EXTWAIT	=> FORCE_EXTWAIT,
		USE_SLOTIRQ		=> USE_SLOTIRQ,
		USE_ENVELOPE	=> USE_ENVELOPE
	)
	port map (
		clk				=> clk,
		reset			=> reset,

		async_fs_in		=> async_fs_in,
		sync_fs_out		=> fs_sync_sig,

		address			=> address,
		chipselect		=> chipselect,
		read			=> read,
		write			=> write,
		byteenable		=> byteenable,
		readdata		=> readdata,
		writedata		=> writedata,
		waitrequest		=> waitrequest,
		irq				=> irq,

		sys_sync		=> sys_sync_sig,
		sys_slotnum		=> sys_slotnum_sig,
		sys_extwait		=> sys_extwait_sig,
		sys_romwait		=> sys_romwait_sig,
		sys_drive		=> slot_drive_sig,
		sys_overload	=> sys_overload_sig,
		env_renew		=> env_renew_sig,
		irqslot			=> irqslot_sig,
		irqslot_num		=> irqslot_num_sig,
		mute_out		=> mute_out,

		ext_address		=> reg_address_sig,
		ext_lock		=> reg_lock_sig,
		ext_readdata	=> reg_rddata_sig,
		ext_writedata	=> reg_wrdata_sig,
		ext_writeenable	=> reg_wrena_sig,

		dectable_rddata	=> dec_rddata_sig,
		dectable_wrdata	=> dec_wrdata_sig,
		dectable_write	=> dec_write_sig,

		aclink_rddata	=> aclink_rddata,
		aclink_wrdata	=> aclink_wrdata,
		aclink_write	=> aclink_write
	);


	-- スロットエンジンのインスタンス 

	U_engine : loreley_slotengine
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		SLOTNUM_WIDTH	=> SLOTNUM_WIDTH,
		CACHELINE_WIDTH	=> CACHELINE_WIDTH,
		USE_SLOTIRQ		=> USE_SLOTIRQ,
		USE_ENVELOPE	=> USE_ENVELOPE,
		DEVICE_MAKER	=> DEVICE_MAKER
	)
	port map (
		clk				=> clk,
		reset			=> reset,
		ignition		=> ignition,

		fs_sync			=> fs_sync_sig,
		state_busy		=> engine_busy_sig,
		slot_drive		=> slot_drive_sig,

		sys_sync		=> sys_sync_sig,
		sys_slotnum		=> sys_slotnum_sig,
		sys_extwait		=> sys_extwait_sig,
		sys_romwait		=> sys_romwait_sig,

		irqslot			=> irqslot_sig,
		irqslot_num		=> irqslot_num_sig,

		env_renew		=> env_renew_sig,

		ext_address		=> reg_address_sig,
		ext_lock		=> reg_lock_sig,
		ext_readdata	=> reg_rddata_sig,
		ext_writedata	=> reg_wrdata_sig,
		ext_writeenable	=> reg_wrena_sig,

		rom_slotnum		=> rom_slotnum,
		rom_fillreq		=> rom_fillreq,
		rom_bank		=> rom_bank,
		rom_address		=> rom_address,
		rom_read_n		=> rom_read_n,
		rom_readdata	=> rom_readdata,
		rom_waitrequest	=> rom_waitrequest,

		compress_data	=> comp_data_sig,
		decompress_data	=> decomp_data_sig,

		adder_start		=> adder_start_sig,
		pcmdata			=> pcmdata_sig,
		volume_fl		=> volume_fl_sig,
		volume_fr		=> volume_fr_sig,
		volume_rl		=> volume_rl_sig,
		volume_rr		=> volume_rr_sig,
		volume_aux0		=> volume_aux0_sig,
		volume_aux1		=> volume_aux1_sig
	);


	-- デコードモジュールのインスタンス 

	U_decoder : loreley_decoder
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		USE_DECODETABLE	=> USE_DECODETABLE,
		DECODE_TABLE	=> DECODE_TABLE,
		DEVICE_MAKER	=> DEVICE_MAKER
	)
	port map (
		clk				=> clk,
		reset			=> reset,

		compress_data	=> comp_data_sig,
		decompress_data	=> decomp_data_sig,

		dectable_rddata	=> dec_rddata_sig,
		dectable_wrdata	=> dec_wrdata_sig,
		dectable_write	=> dec_write_sig
	);


	-- 波形合成モジュールのインスタンス 

	U_waveaddr : loreley_waveadder
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		DEVICE_MAKER	=> DEVICE_MAKER,
		PCM_FL_OUT		=> PCM_FL_OUT,
		PCM_FR_OUT		=> PCM_FR_OUT,
		PCM_RL_OUT		=> PCM_RL_OUT,
		PCM_RR_OUT		=> PCM_RR_OUT,
		PCM_AUX0_OUT	=> PCM_AUX0_OUT,
		PCM_AUX1_OUT	=> PCM_AUX1_OUT
	)
	port map (
		clk				=> clk,
		reset			=> reset,

		fs_sync			=> fs_sync_sig,
		start			=> adder_start_sig,
		state_busy		=> adder_busy_sig,

		pcmdata			=> pcmdata_sig,
		volume_fl		=> volume_fl_sig,
		volume_fr		=> volume_fr_sig,
		volume_rl		=> volume_rl_sig,
		volume_rr		=> volume_rr_sig,
		volume_aux0		=> volume_aux0_sig,
		volume_aux1		=> volume_aux1_sig,

		pcmout_fl		=> pcmout_fl,
		pcmout_fr		=> pcmout_fr,
		pcmout_rl		=> pcmout_rl,
		pcmout_rr		=> pcmout_rr,
		pcmout_aux0		=> pcmout_aux0,
		pcmout_aux1		=> pcmout_aux1
	);

	sync_fs_out <= fs_sync_sig;


end RTL;



----------------------------------------------------------------------
--   (C)2005,2006 Copyright J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------

----------------------------------------------------------------------
-- TITLE : Loreley Slot Engine
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2005/03/30 -> 2005/04/13 (HERSTELLUNG)
--               : 2005/04/15 (FESTSTELLUNG)
--
--               : 2006/01/03 SYNCモードの仕様を変更
--               : 2006/09/22 波形補間を拡張機能扱いに変更
--               : 2006/09/22 エンベローブモードを導入
--               : 2006/10/12 キャッシュ制御信号を追加
--               : 2006/11/30 波形補間モードを追加 (NEUBEARBEITUNG)
--
--               : 2008/02/04 エンベローブレジスタを標準VHDLで記述 (NEUBEARBEITUNG)
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity loreley_slotengine is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset

		SLOTNUM_WIDTH	: integer := 6;		-- Slot Number width(5=31slot,6=63slot,7=127slot)
		CACHELINE_WIDTH	: integer := 3;		-- WROM CacheLine width(3=8byte,4=16byte,5=32byte)
		USE_SLOTIRQ		: string := "ON";
		USE_ENVELOPE	: string := "ON";
		DEVICE_MAKER	: string := "ALTERA"
	);
	port(
		clk				: in  std_logic;	-- system clock
		reset			: in  std_logic;	-- async reset
		ignition		: in  std_logic :='1';	-- engine igniter signal

		fs_sync			: in  std_logic;	-- Fs sync signal (1clock width)
		state_busy		: out std_logic;	-- State machine busy signal
		slot_drive		: out std_logic;	-- engine driving signal

	--==== System register I/F signal ================================

		sys_sync		: in  std_logic :='0';
		sys_slotnum		: in  std_logic_vector(6 downto 0);
		sys_extwait		: in  std_logic :='0';
		sys_romwait		: in  std_logic_vector(6 downto 0);

		irqslot			: out std_logic;
		irqslot_num		: out std_logic_vector(6 downto 0);

		env_renew		: in  std_logic :='0';

	--==== RegisterBUS I/F signal ====================================

		ext_address		: in  std_logic_vector(11 downto 2);
		ext_lock		: out std_logic;

		ext_readdata	: out std_logic_vector(31 downto 0);
		ext_writedata	: in  std_logic_vector(31 downto 0);
		ext_writeenable	: in  std_logic;

	--==== WaveROM BUS I/F signal ====================================

		rom_slotnum		: out std_logic_vector(6 downto 0);
		rom_fillreq		: out std_logic;

		rom_bank		: out std_logic_vector(1 downto 0);
		rom_address		: out std_logic_vector(29 downto 1);
		rom_read_n		: out std_logic;
		rom_readdata	: in  std_logic_vector(15 downto 0);

		rom_waitrequest	: in  std_logic :='0';

	--==== Decompresser I/F signal ===================================

		compress_data	: out std_logic_vector(7 downto 0);
		decompress_data	: in  std_logic_vector(15 downto 0);

	--==== Wave Adder I/F signal =====================================

		adder_start		: out std_logic;

		pcmdata			: out std_logic_vector(15 downto 0);
		volume_fl		: out std_logic_vector(7 downto 0);
		volume_fr		: out std_logic_vector(7 downto 0);
		volume_rl		: out std_logic_vector(7 downto 0);
		volume_rr		: out std_logic_vector(7 downto 0);
		volume_aux0		: out std_logic_vector(7 downto 0);
		volume_aux1		: out std_logic_vector(7 downto 0)

	);
end loreley_slotengine;

architecture RTL of loreley_slotengine is
	constant SLOTNUM_MASK	: std_logic_vector(6 downto 0) :=
								CONV_STD_LOGIC_VECTOR((2**SLOTNUM_WIDTH)-1,7);

	type SLOT_STATE is (START,ENTRY, REGREAD0,REGREAD1,REGREAD2,REGREAD3,
							CTRL,ROMREAD,REGWRITE,WAVEADD, HALT);
	signal state : SLOT_STATE;
	signal slot_valid_reg	: std_logic;
	signal slotcount_reg	: std_logic_vector(6 downto 0);
	signal waitcount_reg	: std_logic_vector(6 downto 0);
	signal statebusy_reg	: std_logic;
	signal slotdrive_reg	: std_logic;
	signal ignition_reg		: std_logic;

	signal sys_extwait_reg	: std_logic;
	signal sys_romwait_reg	: std_logic_vector(6 downto 0);
	signal sys_sync_reg		: std_logic;
	signal keyon_sig		: std_logic;
	signal keyoff_sig		: std_logic;
	signal keyonflag_reg	: std_logic;
	signal keyoffflag_reg	: std_logic;
	signal stopflag_reg		: std_logic;
	signal irqslotset_sig	: std_logic;
	signal irqslotclr_sig	: std_logic;

	signal note_reg			: std_logic;
	signal slotbusy_reg		: std_logic;
	signal keyon_reg		: std_logic;
	signal keyoff_reg		: std_logic;
	signal keyonmask_reg	: std_logic;
	signal loophist_reg		: std_logic;
	signal irqflag_reg		: std_logic;
	signal irqenable_reg	: std_logic;
	signal phaserev_reg		: std_logic;
	signal synckeyon_reg	: std_logic;
	signal synckeyoff_reg	: std_logic;
	signal envena_reg		: std_logic;
	signal datalen_reg		: std_logic;
	signal compena_reg		: std_logic;
	signal smoothena_reg	: std_logic;
	signal loopena_reg		: std_logic;
	signal noiseena_reg		: std_logic;
	signal freq_reg			: std_logic_vector(15 downto 0);
	signal vol_fl_reg		: std_logic_vector(7 downto 0);
	signal vol_fr_reg		: std_logic_vector(7 downto 0);
	signal vol_rl_reg		: std_logic_vector(7 downto 0);
	signal vol_rr_reg		: std_logic_vector(7 downto 0);
	signal vol_aux0_reg		: std_logic_vector(7 downto 0);
	signal vol_aux1_reg		: std_logic_vector(7 downto 0);

	signal reg_a_read_sig	: std_logic_vector(31 downto 0);
	signal playaddr_reg		: std_logic_vector(29 downto 0);
	signal topaddr_reg		: std_logic_vector(playaddr_reg'left downto 0);
	signal endaddr_reg		: std_logic_vector(playaddr_reg'left downto 0);
	signal loopaddr_reg		: std_logic_vector(playaddr_reg'left downto 0);
	signal nextaddr_reg		: std_logic_vector(playaddr_reg'left downto 0);
	signal cmpaddr_a_sig	: std_logic_vector((playaddr_reg'left+1)downto 0);
	signal cmpaddr_b_sig	: std_logic_vector((playaddr_reg'left+1)downto 0);
	signal cmpaddr_q_sig	: std_logic_vector((playaddr_reg'left+1)downto 0);
	signal endflag_reg		: std_logic;
	signal addrcorr_reg		: std_logic;
	signal cacheaddr_a_sig	: std_logic_vector(playaddr_reg'left downto CACHELINE_WIDTH);
	signal cacheaddr_b_sig	: std_logic_vector(playaddr_reg'left downto CACHELINE_WIDTH);
	signal cacheaddr_q_sig	: std_logic;
	signal fullcache_reg	: std_logic;
	signal cacheflag_reg	: std_logic;
	signal halfcflag_reg	: std_logic;
	signal cachefill_reg	: std_logic;
	signal cachehalf_reg	: std_logic;
	signal fullc_req_sig	: std_logic;
	signal halfc_req_sig	: std_logic;

	signal incaddr_reg		: std_logic_vector((playaddr_reg'length+15-1)downto 0);
	signal incaddr_a_sig	: std_logic_vector(incaddr_reg'left downto 0);
	signal incaddr_b_sig	: std_logic_vector(incaddr_reg'left downto 0);
	signal incaddr_q_sig	: std_logic_vector(incaddr_reg'left downto 0);
	signal addrstart_sig	: std_logic;

	type WROMREAD_STATE is (WROM_START, WROM_READ1,WROM_READ2,WROM_READ3,WROM_READ4,
									WROM_DEC1,WROM_DEC2,WROM_DEC3,WROM_DEC4, WROM_HALT);
	signal wrom_state : WROMREAD_STATE;
	signal wrom_done_reg	: std_logic;
	signal wrom_bank_reg	: std_logic_vector(1 downto 0);
	signal wrom_addr_reg	: std_logic_vector(29 downto 0);
	signal wrom_rd_reg		: std_logic;
	signal wrom_fill_reg	: std_logic;
	signal wrom_data_reg	: std_logic_vector(15 downto 0);
	signal wrom_word_sig	: std_logic_vector(15 downto 0);
	signal wrom_byte_sig	: std_logic_vector(7 downto 0);
	signal wrom_hclbit_sig	: std_logic;
	signal wrom_hclbyte_sig	: std_logic;
	signal wrom_hclword_sig	: std_logic;
	signal wdatasel_reg		: std_logic;
	signal wdatalatch_reg	: std_logic;
	signal wavedata_sig		: std_logic_vector(15 downto 0);
	signal wavedata_reg		: std_logic_vector(15 downto 0);
	signal waddr_dec_reg	: std_logic_vector(7 downto 0);
	signal wavemul_a_reg	: std_logic_vector(15 downto 0);
	signal wavemul_b_reg	: std_logic_vector(8 downto 0);
	signal wavemul_q_sig	: std_logic_vector(23 downto 0);
	signal waveacm_a_reg	: std_logic_vector(24 downto 0);
	signal waveacm_b_reg	: std_logic_vector(24 downto 0);
	signal waveacm_q_sig	: std_logic_vector(24 downto 0);
	signal decomp_data_sig	: std_logic_vector(15 downto 0);

	signal pcmneg_q_sig		: std_logic_vector(15 downto 0);
	signal pcmout_sig		: std_logic_vector(15 downto 0);

	component loreley_slotengine_multiple
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic;
		DEVICE_MAKER	: string
	);
	port(
		mul_a_in		: in  std_logic_vector(15 downto 0);
		mul_b_in		: in  std_logic_vector(8 downto 0);
		mul_q_out		: out std_logic_vector(23 downto 0)
	);
	end component;

	component loreley_lfsr
	generic(
		RESET_LEVEL		: std_logic;
		CLOCK_EDGE		: std_logic;

		LFSR1_SIZE		: integer;
		FIBREG1_NUM		: integer;
		LFSR2_SIZE		: integer;
		FIBREG2_NUM		: integer;

		OUTPUT_BITWIDTH	: integer
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;

		lfsr_out	: out std_logic_vector(OUTPUT_BITWIDTH-1 downto 0)
	);
	end component;
	signal lfsrdata_sig		: std_logic_vector(15 downto 0);


	component loreley_turedpram
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic;
		ADDRESS_WIDTH	: integer;
		DATA_WIDTH		: integer;

		DEVICE_MAKER	: string
	);
	port(
		clk				: in  std_logic;
		reset			: in  std_logic := '0';

		address_a		: in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
		readdata_a		: out std_logic_vector(DATA_WIDTH-1 downto 0);
		writedata_a		: in  std_logic_vector(DATA_WIDTH-1 downto 0);
		writeena_a		: in  std_logic := '1';

		address_b		: in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
		readdata_b		: out std_logic_vector(DATA_WIDTH-1 downto 0);
		writedata_b		: in  std_logic_vector(DATA_WIDTH-1 downto 0);
		writeena_b		: in  std_logic := '1'
	);
	end component;
	signal reg_addr_sig		: std_logic_vector(8 downto 0);
	signal reg_wrena_sig	: std_logic;
	signal reg_a_rddata_sig	: std_logic_vector(31 downto 0);
	signal reg_b_rddata_sig	: std_logic_vector(31 downto 0);
	signal playaddr_wb_sig	: std_logic_vector(31 downto 0);
	signal status_wb_sig	: std_logic_vector(31 downto 0);

	signal ext_addr_sig		: std_logic_vector(8 downto 0);
	signal ext_rddata_sig	: std_logic_vector(31 downto 0);
	signal ext_a_rddata_sig	: std_logic_vector(31 downto 0);
	signal ext_b_rddata_sig	: std_logic_vector(31 downto 0);
	signal ext_wrdata_sig	: std_logic_vector(31 downto 0);
	signal ext_a_wrena_sig	: std_logic;
	signal ext_b_wrena_sig	: std_logic;
	signal ext_lock_sig	: std_logic;

	component loreley_irqencode
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic;
		SLOTNUM_WIDTH	: integer
	);
	port(
		clk				: in  std_logic;
		reset			: in  std_logic;

		irqslot_setaddr	: in  std_logic_vector(SLOTNUM_WIDTH-1 downto 0);
		irqslot_set		: in  std_logic;
		irqslot_clraddr	: in  std_logic_vector(SLOTNUM_WIDTH-1 downto 0);
		irqslot_clr		: in  std_logic;

		irqslot_req		: out std_logic;
		irqslot_num		: out std_logic_vector(6 downto 0)
	);
	end component;


	type ENVELOPE_STATE is (ENV_START, ENV_LOAD, ENV_CALC,
								ENV_CONV0,ENV_CONV1,ENV_CONV2,ENV_CONV3, ENV_HALT);
	signal env_state : ENVELOPE_STATE;
	signal env_done_reg		: std_logic;
	signal env_renew_reg	: std_logic;
	signal env_level_reg	: std_logic_vector(7 downto 0);
	signal env_tl_reg		: std_logic_vector(7 downto 0);
	signal env_sd_reg		: std_logic_vector(3 downto 0);
	signal env_sr_reg		: std_logic_vector(5 downto 0);
	signal env_rr_reg		: std_logic_vector(5 downto 0);
	signal env_keyoff_sig	: std_logic;
	signal env_levsat_sig	: std_logic_vector(6 downto 0);
	signal env_reflev_reg	: std_logic_vector(6 downto 0);
	signal env_sub_sig		: std_logic_vector(7 downto 0);
	signal env_subans_sig	: std_logic_vector(7 downto 0);
	signal env_subsat_sig	: std_logic_vector(7 downto 0);
	signal env_volsel_sig	: std_logic_vector(7 downto 0);
	signal env_conv_sig		: std_logic_vector(9 downto 0);
	signal env_cnvsat_sig	: std_logic_vector(7 downto 0);
	signal env_vfl_reg		: std_logic_vector(7 downto 0);
	signal env_vfr_reg		: std_logic_vector(7 downto 0);
	signal env_vrl_reg		: std_logic_vector(7 downto 0);
	signal env_vrr_reg		: std_logic_vector(7 downto 0);
	signal env_ena_sig		: std_logic;

	component loreley_envram_std
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic
	);
	port(
		clk			: in  std_logic;
		reset		: in  std_logic;

		env_rdaddr	: in  std_logic_vector(8 downto 0);
		env_rddata	: out std_logic_vector(7 downto 0);
		env_wraddr	: in  std_logic_vector(8 downto 0);
		env_wrdata	: in  std_logic_vector(7 downto 0);
		env_wrena	: in  std_logic
	);
	end component;
	component loreley_envram
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdaddress	: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		wraddress	: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		wren		: IN STD_LOGIC  := '1';
		q			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
	end component;
	signal env_rdaddr_sig	: std_logic_vector(8 downto 0);
	signal env_rddata_sig	: std_logic_vector(7 downto 0);
	signal env_wraddr_sig	: std_logic_vector(8 downto 0);
	signal env_wrdata_sig	: std_logic_vector(7 downto 0);
	signal env_wrena_sig	: std_logic;


begin

--==== スロット処理ステートマシン ====================================

	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			state <= HALT;
			ignition_reg   <= '0';
			slotcount_reg  <= (others=>'0');
			sys_sync_reg   <= '0';
			slot_valid_reg <= '0';
			statebusy_reg  <= '0';
			slotdrive_reg  <= '0';
			env_renew_reg  <= '0';

		elsif(clk'event and clk=CLOCK_EDGE) then
			if (state=HALT) then
				statebusy_reg <= '0';
			else
				statebusy_reg <= '1';
			end if;


		-- fs同期信号でスロット処理ステートを起動 --------
			if (fs_sync='1') then
				state <= START;
				ignition_reg    <= ignition;
				slotcount_reg   <= sys_slotnum and SLOTNUM_MASK;
				sys_extwait_reg <= sys_extwait;
				sys_romwait_reg <= sys_romwait;
				sys_sync_reg    <= sys_sync;
				slotdrive_reg   <= '0';
				env_renew_reg   <= env_renew;

			else
				case state is
				when START =>
					if (slotcount_reg=0) then
						state <= HALT;
					else
						state <= ENTRY;
					end if;

				when ENTRY =>
					state <= REGREAD0;


		-- レジスタファイルからデータをロードする --------
				when REGREAD0 =>		-- PLAY-ADDRESS,STATUSレジスタをロード 
					state <= REGREAD1;
					note_reg <= reg_b_rddata_sig(31);
					slot_valid_reg <= reg_b_rddata_sig(15);

					slotbusy_reg  <= reg_b_rddata_sig(15);
					keyon_reg     <= reg_b_rddata_sig(14);
					keyoff_reg    <= reg_b_rddata_sig(13);
					keyonmask_reg <= reg_b_rddata_sig(12);
					loophist_reg  <= reg_b_rddata_sig(11);
					irqflag_reg   <= reg_b_rddata_sig(10);
					irqenable_reg <= reg_b_rddata_sig(9);
					phaserev_reg  <= reg_b_rddata_sig(8);
					synckeyon_reg <= reg_b_rddata_sig(7);
					synckeyoff_reg<= reg_b_rddata_sig(6);
					envena_reg    <= reg_b_rddata_sig(5);
					datalen_reg   <= reg_b_rddata_sig(4);
					compena_reg   <= reg_b_rddata_sig(3);
					smoothena_reg <= reg_b_rddata_sig(2);
					loopena_reg   <= reg_b_rddata_sig(1);
					noiseena_reg  <= reg_b_rddata_sig(0);

					cacheflag_reg <= reg_a_rddata_sig(31);				-- WaveROMキャッシュ更新フラグ
					halfcflag_reg <= reg_a_rddata_sig(30);
					playaddr_reg  <= reg_a_rddata_sig(29 downto 0);

					incaddr_reg(29+15 downto 15) <= reg_a_rddata_sig(29 downto 0);
					incaddr_reg(14 downto 0) <= reg_b_rddata_sig(30 downto 16);

					fullcache_reg <= '0';

				when REGREAD1 =>		-- START-ADDRESS,FREQ,ENVレジスタをロード 
					state <= REGREAD2;

					freq_reg   <= reg_b_rddata_sig(15 downto 0);
					env_rr_reg <= reg_b_rddata_sig(21 downto 16);
					env_sr_reg <= reg_b_rddata_sig(27 downto 22);
					env_sd_reg <= reg_b_rddata_sig(31 downto 28);

					wrom_bank_reg <= reg_a_read_sig(31 downto 30);
					if (datalen_reg='0') then
						topaddr_reg <= reg_a_read_sig(29 downto 0);
					else
						topaddr_reg <= '0' & reg_a_read_sig(29 downto 1);	-- 16bitデータ長の場合はLSB無効 
					end if;

					keyoffflag_reg <= keyoff_sig;		-- キーフラグを確定 
					keyonflag_reg  <= keyon_sig;

				when REGREAD2 =>		-- END-ADDRESS,VOL-LEFTレジスタをロード 
					state <= REGREAD3;

					vol_fl_reg  <= reg_b_rddata_sig(7 downto 0);
					vol_rl_reg  <= reg_b_rddata_sig(15 downto 8);
					vol_aux0_reg<= reg_b_rddata_sig(23 downto 16);
					env_tl_reg  <= reg_b_rddata_sig(31 downto 24);

					if (datalen_reg='0') then
						endaddr_reg <= reg_a_read_sig(29 downto 0);
					else
						endaddr_reg <= '0' & reg_a_read_sig(29 downto 1);	-- 16bitデータ長の場合はLSB無効 
					end if;

					incaddr_reg  <= incaddr_q_sig;		-- アドレスを更新 

				when REGREAD3 =>		-- LOOP-ADDRESS,VOL-RIGHTレジスタをロード 
					state <= CTRL;

					vol_fr_reg  <= reg_b_rddata_sig(7 downto 0);
					vol_rr_reg  <= reg_b_rddata_sig(15 downto 8);
					vol_aux1_reg<= reg_b_rddata_sig(23 downto 16);

					if (datalen_reg='0') then
						loopaddr_reg <= reg_a_read_sig(29 downto 0);
					else
						loopaddr_reg <= '0' & reg_a_read_sig(29 downto 1);	-- 16bitデータ長の場合はLSB無効 
					end if;

					if (env_ena_sig = '1') then			-- 発音停止フラグを確定 
						if (keyon_sig = '0') then
							stopflag_reg <= env_keyoff_sig;
						end if;
					else
						stopflag_reg <= keyoff_sig;
					end if;

					addrcorr_reg <= cmpaddr_q_sig(0);	-- エンドアドレス判定 
					endflag_reg  <= not cmpaddr_q_sig(cmpaddr_q_sig'left);


		-- スロットの動作をコントロールする --------
				when CTRL =>
					if (slotbusy_reg='1') then
						state <= ROMREAD;				-- 再生中ならROMアクセスへ 
					else
						state <= REGWRITE;				-- 停止中ならROMリードはスキップ 
					end if;

					if (stopflag_reg='1') then			-- 発音停止要求の処理（最優先） 
						slotbusy_reg <= '0';

					elsif (keyonflag_reg='1' and keyonmask_reg='0') then	-- KEYON時の処理 
						slotbusy_reg <= '1';
						loophist_reg <= '0';
						nextaddr_reg <= topaddr_reg;
						fullcache_reg<= '1';

					elsif (slotbusy_reg='1') then			-- 再生時の処理 
						if (endflag_reg='1') then
							irqflag_reg <= irqflag_reg or irqenable_reg;
							if (loopena_reg='1') then		-- ループ時の処理 
								fullcache_reg <= '1';
								loophist_reg  <= '1';
								if (addrcorr_reg='0') then
									nextaddr_reg <= loopaddr_reg;
								else
									nextaddr_reg <= loopaddr_reg + 1;
								end if;
							else
								slotbusy_reg <= '0';
							end if;
						else
							nextaddr_reg <= incaddr_reg(29+15 downto 15);
						end if;

					end if;

					cachefill_reg <= cacheaddr_q_sig;	-- キャッシュフラグ 

					if (keyoffflag_reg = '1') then		-- ノートフラグ 
						note_reg <= '0';
					elsif (keyonflag_reg = '1') then
						note_reg <= '1';
					end if;

				when ROMREAD =>		-- WaveROMリード、エンベローブエンジンの終了待ち 
					if (wrom_done_reg='1' and env_done_reg='1') then
						state <= REGWRITE;
					end if;


		-- レジスタへの書き戻しと波形合成を行う --------
				when REGWRITE =>
					state <= WAVEADD;
					slotcount_reg <= slotcount_reg - '1';
					slotdrive_reg <= slotdrive_reg or slotbusy_reg;

				when WAVEADD =>
					if (slotcount_reg=0) then
						state <= HALT;
					else
						state <= REGREAD0;
					end if;


		-- 次にfs同期信号が来るまで待機する --------
				when HALT =>
					state <= HALT;

				when others =>
					state <= HALT;
				end case;
			end if;

		end if;
	end process;


	-- スロット信号出力 
	state_busy <= statebusy_reg;
	slot_drive <= slotdrive_reg;

	-- アドレス加算器 
	incaddr_a_sig <= incaddr_reg;
	incaddr_b_sig(incaddr_b_sig'left downto 16)<= (others=>'0');
	incaddr_b_sig(15 downto 0) <= freq_reg;

	incaddr_q_sig <= incaddr_a_sig + incaddr_b_sig;

	-- 終了アドレス比較器 
	cmpaddr_a_sig <= '0' & incaddr_reg(29+15 downto 15);
	cmpaddr_b_sig <= '0' & endaddr_reg;

	cmpaddr_q_sig <= cmpaddr_a_sig - cmpaddr_b_sig - 1;

	-- キャッシュライン比較器 
	cacheaddr_a_sig <= playaddr_reg(29 downto CACHELINE_WIDTH) when datalen_reg='0' else
						playaddr_reg(28 downto CACHELINE_WIDTH-1);
	cacheaddr_b_sig <= incaddr_reg(29+15 downto CACHELINE_WIDTH+15) when datalen_reg='0' else
						incaddr_reg(28+15 downto CACHELINE_WIDTH+15-1);

	cacheaddr_q_sig <= '1' when cacheaddr_a_sig/=cacheaddr_b_sig else '0';

	fullc_req_sig <= cachefill_reg when fullcache_reg='0' else '1';
	halfc_req_sig <= cachehalf_reg when(fullcache_reg='0' and smoothena_reg='1')else '0';


--==== WaveROMリードステートマシン ===================================

	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			wrom_state <= WROM_HALT;
			wrom_done_reg <= '1';
			wrom_rd_reg   <= '0';
			wrom_fill_reg <= '0';

		elsif(clk'event and clk=CLOCK_EDGE) then

		-- スロット処理ステート開始でリードを起動 --------
			if (state = REGREAD0) then
				wrom_state <= WROM_START;

			else
				case wrom_state is
				when WROM_START =>
					if (slotbusy_reg='1') then		-- 再生アドレスからデータを読み込む 
						wrom_state <= WROM_READ1;
						wrom_done_reg <= '0';
						wrom_rd_reg   <= '1';
						wrom_addr_reg <= playaddr_reg;
						waddr_dec_reg <= incaddr_reg(14 downto 7);

						if (cacheflag_reg='1') then	-- キャッシュコントロール 
							if (halfcflag_reg='1') then		-- 既にロードしたラインはフィル無効 
								wrom_fill_reg <= '0';
							else
								wrom_fill_reg <= '1';
							end if;
							cachehalf_reg <= '0';
						else
							cachehalf_reg <= halfcflag_reg;
						end if;

					else							-- 再生していなければ停止して待機 
						wrom_state <= WROM_HALT;
						wrom_done_reg <= '1';
						wrom_rd_reg   <= '0';
						wrom_fill_reg <= '0';
						cachehalf_reg <= '0';
					end if;

					waitcount_reg <= (others=>'0');

				when WROM_READ1 =>					-- 波形アクセス 
					if ((sys_extwait_reg='1' and rom_waitrequest='0')or
						(sys_extwait_reg='0' and waitcount_reg=sys_romwait_reg)) then
						wrom_state <= WROM_READ2;

						wrom_fill_reg <= '0';
						wrom_rd_reg   <= '0';
						wrom_data_reg <= rom_readdata;	-- 波形ROMデータを取得 
						wdatasel_reg  <= wrom_addr_reg(0);
						wrom_addr_reg <= wrom_addr_reg + 1; -- 次の波形データ 
					end if;

					waitcount_reg <= waitcount_reg + 1;

				when WROM_READ2 =>					-- データラッチ 
					if (smoothena_reg='1') then
						if (datalen_reg='1' or wdatasel_reg='1') then
							wrom_state <= WROM_READ3;
							wdatalatch_reg<= '1';
							wrom_rd_reg   <= '1';

							if (wrom_hclbit_sig='1' and cachehalf_reg='0') then
								wrom_fill_reg <= '1';
								cachehalf_reg <= '1';
							end if;
						else
							wrom_state <= WROM_READ4;
							wdatalatch_reg <= '1';
						end if;
					else
						wrom_state <= WROM_DEC4;
						wrom_done_reg  <= '1';
						wdatalatch_reg <= '0';
					end if;

					waitcount_reg <= (others=>'0');

				when WROM_READ3 =>					-- 波形補間アクセス 
					if ((sys_extwait_reg='1' and rom_waitrequest='0')or
						(sys_extwait_reg='0' and waitcount_reg=sys_romwait_reg)) then
						wrom_state <= WROM_DEC1;

						wrom_fill_reg <= '0';
						wrom_rd_reg   <= '0';
						wrom_data_reg <= rom_readdata;	-- 波形ROMデータを取得 
						wdatasel_reg  <= wrom_addr_reg(0);
					end if;

					if (wdatalatch_reg='1') then
						wavemul_a_reg <= wavedata_sig;
						wavemul_b_reg <= 256 - ('0' & waddr_dec_reg);
						wdatalatch_reg<= '0';
					end if;

					waitcount_reg <= waitcount_reg + 1;

				when WROM_READ4 =>					-- 波形補間アクセススキップ
					wrom_state <= WROM_DEC1;
					wdatasel_reg <= '1';

					if (wdatalatch_reg='1') then
						wavemul_a_reg <= wavedata_sig;
						wavemul_b_reg <= 256 - ('0' & waddr_dec_reg);
						wdatalatch_reg<= '0';
					end if;


				when WROM_DEC1 =>					-- 波形補間データラッチ 
					wrom_state <= WROM_DEC2;
					waveacm_a_reg(24) <= wavemul_q_sig(23);
					waveacm_a_reg(23 downto 0) <= wavemul_q_sig;

				when WROM_DEC2 =>
					wrom_state <= WROM_DEC3;
					wavemul_a_reg <= wavedata_sig;
					wavemul_b_reg <= '0' & waddr_dec_reg;

				when WROM_DEC3 =>
					wrom_state <= WROM_DEC4;
					wrom_done_reg <= '1';
					waveacm_b_reg(24) <= wavemul_q_sig(23);
					waveacm_b_reg(23 downto 0) <= wavemul_q_sig;

				when WROM_DEC4 =>					-- 波形データ確定 
					wrom_state <= WROM_HALT;
					if (smoothena_reg='1') then
						wavedata_reg <= waveacm_q_sig(23 downto 8);
					else
						wavedata_reg <= wavedata_sig;
					end if;

				when WROM_HALT =>					-- (WAVEADD)
					wrom_state <= WROM_HALT;

				when others =>
					wrom_state <= WROM_HALT;
				end case;
			end if;
		end if;
	end process;


	-- 波形補間・積和演算器 
	U_mult : loreley_slotengine_multiple
	generic map(
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		DEVICE_MAKER	=> DEVICE_MAKER
	)
	port map(
		mul_a_in		=> wavemul_a_reg,
		mul_b_in		=> wavemul_b_reg,
		mul_q_out		=> wavemul_q_sig
	);

	waveacm_q_sig <= waveacm_a_reg + waveacm_b_reg;

	-- ハーフキャッシュライン比較 
	wrom_hclbyte_sig <= '1' when wrom_addr_reg(CACHELINE_WIDTH)/=playaddr_reg(CACHELINE_WIDTH) else '0';
	wrom_hclword_sig <= '1' when wrom_addr_reg(CACHELINE_WIDTH-1)/=playaddr_reg(CACHELINE_WIDTH-1) else '0';

	wrom_hclbit_sig  <= wrom_hclbyte_sig when datalen_reg='0' else wrom_hclword_sig;

	-- 波形キャッシュ制御信号出力 
	rom_slotnum <= slotcount_reg;
	rom_fillreq <= wrom_fill_reg;

	-- アドレス・制御信号出力 
	rom_bank    <= wrom_bank_reg;
	rom_address <= wrom_addr_reg(29 downto 1) when datalen_reg='0' else
					wrom_addr_reg(28 downto 0);
	rom_read_n  <= not wrom_rd_reg;

	-- データアライメント 
	wrom_word_sig <= wrom_data_reg;
	wrom_byte_sig <= wrom_data_reg(15 downto 8) when wdatasel_reg='1' else
						wrom_data_reg(7 downto 0);

	-- 圧縮PCMデコーダの入出力 
	compress_data  <= wrom_byte_sig;
	decomp_data_sig<= decompress_data;

	-- 波形データセレクタ 
	wavedata_sig <= lfsrdata_sig    when noiseena_reg='1' else
					wrom_word_sig   when(noiseena_reg='0' and datalen_reg='1')else
					decomp_data_sig when(noiseena_reg='0' and datalen_reg='0' and compena_reg='1')else
					wrom_byte_sig & "00000000";

	-- ランダムノイズ生成器 
	U_lfsr : loreley_lfsr
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		LFSR1_SIZE		=> 17,
		FIBREG1_NUM		=> 14,
		LFSR2_SIZE		=> 18,
		FIBREG2_NUM		=> 11,
		OUTPUT_BITWIDTH	=> 16
	)
	port map (
		clk			=> clk,
		reset		=> reset,
		lfsr_out	=> lfsrdata_sig
	);


--==== 波形データ処理 ================================================

	-- KEYON,KEYOFF重畳 
	keyoff_sig <= '0' when(sys_sync_reg='0' and synckeyoff_reg='1')else keyoff_reg;
	keyon_sig  <= '0' when(sys_sync_reg='0' and synckeyon_reg ='1')else keyon_reg;

	-- 波形データ位相反転 
	pcmneg_q_sig <= (not wavedata_reg) + '1';
	pcmout_sig   <= pcmneg_q_sig when phaserev_reg='1' else wavedata_reg;

	-- 波形合成ユニットへの出力 
	addrstart_sig <= slot_valid_reg when state=WAVEADD else '0';
	adder_start <= addrstart_sig;

	pcmdata     <= pcmout_sig;

	volume_fl   <= vol_fl_reg when env_ena_sig='0' else env_vfl_reg;
	volume_fr   <= vol_fr_reg when env_ena_sig='0' else env_vfr_reg;
	volume_rl   <= vol_rl_reg when env_ena_sig='0' else env_vrl_reg;
	volume_rr   <= vol_rr_reg when env_ena_sig='0' else env_vrr_reg;
	volume_aux0 <= vol_aux0_reg when env_ena_sig='0' else (others=>'0');
	volume_aux1 <= vol_aux1_reg when env_ena_sig='0' else (others=>'0');


--==== レジスタバス入出力 ============================================

	-- 内部レジスタアドレスに変換 
	ext_addr_sig(8 downto 2) <= ext_address(11 downto 5);
	ext_addr_sig(1 downto 0) <= ext_address(3 downto 2);

	-- レジスタロック信号の生成 
	ext_lock     <= ext_lock_sig;
	ext_lock_sig <= '1' when slotcount_reg=ext_addr_sig(8 downto 2) else '0';

	-- リードデータ出力 
	ext_readdata <= ext_rddata_sig;
	ext_rddata_sig(31 downto 0) <= ext_a_rddata_sig when ext_address(4)='1' else ext_b_rddata_sig;

	-- ライトイネーブルマスク 
	ext_wrdata_sig  <= ext_writedata;
	ext_a_wrena_sig <= ext_writeenable when(ext_address(4)='1' and ext_lock_sig='0')else '0';
	ext_b_wrena_sig <= ext_writeenable when(ext_address(4)='0' and ext_lock_sig='0')else '0';


--==== スロットレジスタ入出力 ========================================

	-- 割り込みレジスタ制御信号 
	irqslotset_sig <= irqflag_reg when reg_wrena_sig='1' else '0';
	irqslotclr_sig <= ext_b_wrena_sig when
						(ext_addr_sig(1 downto 0)="00" and ext_wrdata_sig(10)='0')else '0';

	-- Aレジスタ、Bレジスタバス I/F 
	reg_addr_sig(8 downto 2) <= slotcount_reg;
	reg_addr_sig(1 downto 0) <= "01" when state=REGREAD0 else
								"10" when state=REGREAD1 else
								"11" when state=REGREAD2 else
								"00";

	reg_a_read_sig(31 downto 1) <= reg_a_rddata_sig(31 downto 1);
	reg_a_read_sig(0) <= reg_a_rddata_sig(0) when datalen_reg='0' else '0';

	reg_wrena_sig <= '1' when state=REGWRITE else '0';

	-- PLAY-ADDRESSレジスタ書き戻し構成 
	playaddr_wb_sig(31) <= fullc_req_sig when slotbusy_reg='1' else '0';
	playaddr_wb_sig(30) <= halfc_req_sig when slotbusy_reg='1' else '0';
	playaddr_wb_sig(29 downto 0) <= nextaddr_reg;	-- 再生アドレス書き戻し 

	-- STATUSレジスタ書き戻し構成 
	status_wb_sig(31) <= note_reg when slotbusy_reg='1' else '0';
	status_wb_sig(30 downto 16) <= (others=>'0') when keyonflag_reg='1' else incaddr_reg(14 downto 0);

	status_wb_sig(15) <= slotbusy_reg when ignition_reg='1' else '0';
	status_wb_sig(14) <= '0' when keyonflag_reg='1'  else keyon_reg;
	status_wb_sig(13) <= '0' when keyoffflag_reg='1' else keyoff_reg;
	status_wb_sig(12) <= keyonmask_reg;
	status_wb_sig(11) <= loophist_reg;
	status_wb_sig(10) <= irqflag_reg;
	status_wb_sig(9)  <= irqenable_reg;
	status_wb_sig(8)  <= phaserev_reg;
	status_wb_sig(7)  <= synckeyon_reg;
	status_wb_sig(6)  <= synckeyoff_reg;
	status_wb_sig(5)  <= envena_reg;
	status_wb_sig(4)  <= datalen_reg;
	status_wb_sig(3)  <= compena_reg;
	status_wb_sig(2)  <= smoothena_reg;
	status_wb_sig(1)  <= loopena_reg;
	status_wb_sig(0)  <= noiseena_reg;


--==== レジスタインスタンス ==========================================

	-- 割り込みレジスタインスタンス 
GEN_IRQON : if (USE_SLOTIRQ = "ON") generate

	U_irq : loreley_irqencode
	generic map (
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		SLOTNUM_WIDTH	=> SLOTNUM_WIDTH
	)
	port map (
		clk				=> clk,
		reset			=> reset,

		irqslot_setaddr	=> reg_addr_sig((SLOTNUM_WIDTH+2)-1 downto 2),
		irqslot_set		=> irqslotset_sig,
		irqslot_clraddr	=> ext_addr_sig((SLOTNUM_WIDTH+2)-1 downto 2),
		irqslot_clr		=> irqslotclr_sig,
		irqslot_req		=> irqslot,
		irqslot_num		=> irqslot_num
	);

	end generate;
GEN_IRQOFF : if (USE_SLOTIRQ /= "ON") generate

	irqslot     <= '0';
	irqslot_num <= (others=>'X');

	end generate;

	-- アドレスレジスタインスタンス 
	U_areg : loreley_turedpram
	generic map(
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		ADDRESS_WIDTH	=> (SLOTNUM_WIDTH+2),
		DATA_WIDTH		=> 32,

		DEVICE_MAKER	=> DEVICE_MAKER
	)
	port map(
		clk			=> clk,
		reset		=> reset,

		address_a	=> reg_addr_sig((SLOTNUM_WIDTH+2)-1 downto 0),
		readdata_a	=> reg_a_rddata_sig,
		writedata_a	=> playaddr_wb_sig,
		writeena_a	=> reg_wrena_sig,

		address_b	=> ext_addr_sig((SLOTNUM_WIDTH+2)-1 downto 0),
		readdata_b	=> ext_a_rddata_sig,
		writedata_b	=> ext_wrdata_sig,
		writeena_b	=> ext_a_wrena_sig
	);

	-- 制御レジスタインスタンス 
	U_breg : loreley_turedpram
	generic map(
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL,
		ADDRESS_WIDTH	=> (SLOTNUM_WIDTH+2),
		DATA_WIDTH		=> 32,

		DEVICE_MAKER	=> DEVICE_MAKER
	)
	port map(
		clk			=> clk,
		reset		=> reset,

		address_a	=> reg_addr_sig((SLOTNUM_WIDTH+2)-1 downto 0),
		readdata_a	=> reg_b_rddata_sig,
		writedata_a	=> status_wb_sig,
		writeena_a	=> reg_wrena_sig,

		address_b	=> ext_addr_sig((SLOTNUM_WIDTH+2)-1 downto 0),
		readdata_b	=> ext_b_rddata_sig,
		writedata_b	=> ext_wrdata_sig,
		writeena_b	=> ext_b_wrena_sig
	);


--==== エンベロープエンジンのインスタンス ============================

GEN_ENVON : if (USE_ENVELOPE = "ON") generate

	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			env_state <= ENV_HALT;
			env_done_reg <= '1';

		elsif(clk'event and clk=CLOCK_EDGE) then

		-- スロット処理ステート開始でエンベロープエンジンを起動 --------
			if (state = REGREAD0) then
				env_state <= ENV_START;

			else
				case env_state is
				when ENV_START =>			-- エンベローブ値をロード (REGREAD1)
					if (envena_reg='1') then
						env_state <= ENV_LOAD;
						env_done_reg <= '0';
					else
						env_state <= ENV_HALT;
						env_done_reg <= '1';
					end if;

				when ENV_LOAD =>			-- エンベローブ値を更新 (REGREAD2)
					env_state <= ENV_CALC;
					env_level_reg <= env_rddata_sig;
					env_reflev_reg<= env_levsat_sig;	-- 127で飽和

				when ENV_CALC =>			-- エンベローブ値を更新 (REGREAD3)
					env_state <= ENV_CONV0;

					if (envena_reg = '1') then
						if (env_renew_reg='1') then
							if (env_level_reg(7) = '1') then	-- アタック＆ディケイ 
								env_level_reg <= env_level_reg - 1;
							else								-- サスティン＆リリース 
								env_level_reg <= env_subsat_sig;
							end if;
						end if;
					else
						env_level_reg <= (others=>'0');			-- 音声モード時は強制停止 
					end if;

				when ENV_CONV0 =>			-- エンベロープレベル→実音量へ変換 (CTRL)
					env_state <= ENV_CONV1;
					env_vfl_reg <= env_rddata_sig;

				when ENV_CONV1 =>
					env_state  <= ENV_CONV2;
					env_vrl_reg <= env_rddata_sig;

				when ENV_CONV2 =>
					env_state  <= ENV_CONV3;
					env_done_reg<= '1';
					env_vfr_reg <= env_rddata_sig;

				when ENV_CONV3 =>						-- (REGWRITE)
					env_state  <= ENV_HALT;
					env_vrr_reg <= env_rddata_sig;

				when ENV_HALT =>						-- (WAVEADD)
					env_state  <= ENV_HALT;

				when others=>
					env_state  <= ENV_HALT;
				end case;

			end if;
		end if;
	end process;

	env_ena_sig <= envena_reg;

	-- エンベロープレベル→音量値への変換 
	env_volsel_sig<= vol_rl_reg when env_state=ENV_CONV0 else
					 vol_fr_reg when env_state=ENV_CONV1 else
					 vol_rr_reg when env_state=ENV_CONV2 else
					 vol_fl_reg;
	env_conv_sig  <= ("00"&(not(env_reflev_reg & '1')))+("00"&(not env_tl_reg))+("00"&(not env_volsel_sig));
	env_cnvsat_sig<= env_conv_sig(7 downto 0) when env_conv_sig(9 downto 8)="00" else (others=>'1');

	env_rdaddr_sig<= "00" & slotcount_reg when env_state=ENV_START else
					 '1' & env_cnvsat_sig;

	env_levsat_sig<= env_rddata_sig(6 downto 0) when env_rddata_sig(7)='0' else (others=>'1');

	-- エンベロープレベルの計算 
	env_sub_sig   <= "00" & env_sr_reg when note_reg='1' else "00" & env_rr_reg;
	env_subans_sig<= env_level_reg - env_sub_sig;
	env_subsat_sig<= env_subans_sig when env_subans_sig(7)='0' else (others=>'0');

	env_keyoff_sig<= '1' when env_reflev_reg=0 else '0';	-- レベルが０になったら停止 

	-- エンベロープレベル書き戻し 
	env_wraddr_sig<= "00" & slotcount_reg;
	env_wrdata_sig<= "1000" & env_sd_reg when keyonflag_reg='1' else env_level_reg;
	env_wrena_sig <= '1' when state=REGWRITE else '0';


	GEN_USE_MF : if (DEVICE_MAKER="ALTERA") generate

		U_envreg : loreley_envram
		PORT MAP (
			clock		=> clk,
			data		=> env_wrdata_sig,
			rdaddress	=> env_rdaddr_sig,
			wraddress	=> env_wraddr_sig,
			wren		=> env_wrena_sig,
			q			=> env_rddata_sig
		);

		end generate;
	GEN_UNUSE_MF : if (DEVICE_MAKER/="ALTERA") generate

		U_envreg : loreley_envram_std
		generic map (
			CLOCK_EDGE		=> CLOCK_EDGE,
			RESET_LEVEL		=> RESET_LEVEL
		)
		port map (
			clk			=> clk,
			reset		=> reset,

			env_rdaddr	=> env_rdaddr_sig,
			env_rddata	=> env_rddata_sig,
			env_wraddr	=> env_wraddr_sig,
			env_wrdata	=> env_wrdata_sig,
			env_wrena	=> env_wrena_sig
		);

		end generate;

	end generate;
GEN_ENVOFF : if (USE_ENVELOPE /= "ON") generate

	env_done_reg<= '1';
	env_ena_sig <= '0';
	env_vfl_reg <= (others=>'0');
	env_vrl_reg <= (others=>'0');
	env_vfr_reg <= (others=>'0');
	env_vrr_reg <= (others=>'0');

	end generate;


end RTL;



----------------------------------------------------------------------
-- 符号付き16bit×符号無し9bit→符号付き24ビット乗算器
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_arith.all;

entity loreley_slotengine_multiple is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset
		DEVICE_MAKER	: string := "ALTERA"
	);
	port(
		mul_a_in		: in  std_logic_vector(15 downto 0);
		mul_b_in		: in  std_logic_vector(8 downto 0);
		mul_q_out		: out std_logic_vector(23 downto 0)
	);
end loreley_slotengine_multiple;

architecture RTL of loreley_slotengine_multiple is
	signal mul_or_sig	: std_logic_vector(23 downto 0);

	component multiple_16x9
	port(
		dataa		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (24 DOWNTO 0)
	);
	end component;
	signal mul_a_sig	: std_logic_vector(15 downto 0);
	signal mul_b_sig	: std_logic_vector(8 downto 0);
	signal mul_q_sig	: std_logic_vector(24 downto 0);

begin

	mul_a_sig  <= mul_a_in;
	mul_b_sig  <= '0' & mul_b_in(7 downto 0) when mul_b_in(8)='0' else
					(others=>'0');
	mul_or_sig <= (others=>'0') when mul_b_in(8)='0' else
					mul_a_in & "00000000";

	mul_q_out <= mul_q_sig(23 downto 0) or mul_or_sig;


GEN_USE_MF : if (DEVICE_MAKER="ALTERA") generate

	MU : multiple_16x9
	port map(
		dataa		=> mul_a_sig,
		datab		=> mul_b_sig,
		result		=> mul_q_sig
	);

	end generate;
GEN_UNUSE_MF : if (DEVICE_MAKER/="ALTERA") generate

	MU : mul_q_sig <= mul_a_sig * mul_b_sig;

	end generate;


end RTL;



----------------------------------------------------------------------
--   (C)2005,2006 Copyright J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------

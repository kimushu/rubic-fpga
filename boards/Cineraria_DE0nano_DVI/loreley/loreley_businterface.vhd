----------------------------------------------------------------------
-- TITLE : Loreley BUS Interface
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2005/04/12 -> 2005/04/13 (HERSTELLUNG)
--               : 2005/04/13 (FESTSTELLUNG)
--
--               : 2006/01/05 Loreleyモディファイ
--               : 2006/09/22 エンベロープタイマ追加 (NEUBEARBEITUNG)
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity loreley_businterface is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset

		SLOTNUM_WIDTH	: integer := 6;
		SYSTEM_ID		: integer := 16#0765_0000#;
		FORCE_EXTFSEDGE	: std_logic := '0';
		FORCE_EXTWAIT	: std_logic := '0';
		USE_SLOTIRQ		: string := "ON";
		USE_ENVELOPE	: string := "ON"
	);
	port(
		clk				: in  std_logic;	-- system clock
		reset			: in  std_logic;	-- async reset

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

	--==== Slotengine I/F signal =====================================

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

	--==== Decompresser I/F signal ===================================

		dectable_rddata	: in  std_logic_vector(31 downto 0) := (others=>'X');
		dectable_wrdata	: out std_logic_vector(31 downto 0);
		dectable_write	: out std_logic;

	--==== AC-LINK I/F signal ========================================

		aclink_rddata	: in  std_logic_vector(31 downto 0) := (others=>'X');
		aclink_wrdata	: out std_logic_vector(31 downto 0);
		aclink_write	: out std_logic

	);
end loreley_businterface;

architecture RTL of loreley_businterface is
	constant SLOTNUM_MASK	: std_logic_vector(6 downto 0) :=
								CONV_STD_LOGIC_VECTOR((2**SLOTNUM_WIDTH)-1,7);
	constant WAITCOUNT_MASK	: std_logic_vector(6 downto 0) :=
								(others=>FORCE_EXTWAIT);
	signal sys_rddata_sig	: std_logic_vector(31 downto 0);

	signal sys_status_sig	: std_logic_vector(31 downto 0);
	signal drive_reg		: std_logic;
	signal mute_reg			: std_logic;
	signal overload_reg		: std_logic;
	signal systemirq_sig	: std_logic;
	signal irqena_reg		: std_logic;
	signal irqslotnum_reg	: std_logic_vector(6 downto 0);

	signal sys_setup_sig	: std_logic_vector(31 downto 0);
	signal extwait_reg		: std_logic;
	signal waitcount_reg	: std_logic_vector(6 downto 0);
	signal extfsedge_reg	: std_logic;
	signal slotnum_reg		: std_logic_vector(6 downto 0);

	signal sys_keysync_sig	: std_logic_vector(31 downto 0);
	signal syssync_reg		: std_logic;

	signal sys_envtimer_sig	: std_logic_vector(31 downto 0);
	signal envtimer_reg		: std_logic_vector(11 downto 0);
	signal envcount_reg		: std_logic_vector(11 downto 0);
	signal envtimerena_reg	: std_logic;

	signal systemid_sig		: std_logic_vector(31 downto 0);
	signal dectabledata_sig : std_logic_vector(31 downto 0);
	signal aclinkdata_sig	: std_logic_vector(31 downto 0);

	signal extfs0_reg		: std_logic;
	signal extfs1_reg		: std_logic;
	signal extfs_in_reg		: std_logic;
	signal sync_fs_reg		: std_logic;

	component loreley_businterface_rmw
	generic(
		CLOCK_EDGE		: std_logic;
		RESET_LEVEL		: std_logic
	);
	port(
		clk				: in  std_logic;
		reset			: in  std_logic;

		address			: in  std_logic_vector(11 downto 2);
		chipselect		: in  std_logic;
		read			: in  std_logic;
		write			: in  std_logic;
		byteenable		: in  std_logic_vector(3 downto 0);
		readdata		: out std_logic_vector(31 downto 0);
		writedata		: in  std_logic_vector(31 downto 0);
		waitrequest		: out std_logic;
		irq				: out std_logic;

		reg_address		: out std_logic_vector(11 downto 2);
		reg_lock		: in  std_logic;
		reg_readdata	: in  std_logic_vector(31 downto 0);
		reg_writedata	: out std_logic_vector(31 downto 0);
		reg_writeenable	: out std_logic;
		reg_irq			: in  std_logic
	);
	end component;
	signal reg_addr_sig		: std_logic_vector(11 downto 2);
	signal reg_lock_sig		: std_logic;
	signal reg_rddata_sig	: std_logic_vector(31 downto 0);
	signal reg_wrdata_sig	: std_logic_vector(31 downto 0);
	signal reg_wrena_sig	: std_logic;
	signal reg_irq_sig		: std_logic;


begin

--==== fs同期信号生成ブロック ========================================

	-- fs同期信号を出力 
	sync_fs_out <= sync_fs_reg;

	-- 外部信号でfs同期信号を生成 
	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			extfs0_reg   <= '0';
			extfs1_reg   <= '0';
			extfs_in_reg <= '0';
			sync_fs_reg  <= '0';

		elsif(clk'event and clk=CLOCK_EDGE) then
			extfs1_reg   <= extfs0_reg;
			extfs0_reg   <= extfs_in_reg;
			extfs_in_reg <= async_fs_in;

			if (extfs1_reg/=extfs0_reg and extfs0_reg=extfsedge_reg) then
				sync_fs_reg <= '1';
			else
				sync_fs_reg <= '0';
			end if;

		end if;
	end process;


--==== エンベロープタイマブロック ====================================

GEN_ENVON : if (USE_ENVELOPE = "ON") generate

	-- エンベロープ更新信号を出力 
	env_renew <= envtimerena_reg when envcount_reg=0 else '0';

	-- エンベロープタイマカウント 
	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			envcount_reg <= (others=>'0');

		elsif(clk'event and clk=CLOCK_EDGE) then
			if (sync_fs_reg='1') then
				if (envcount_reg = 0) then
					envcount_reg <= envtimer_reg;
				else
					envcount_reg <= envcount_reg - 1;
				end if;
			end if;
		end if;
	end process;

	-- ENV-TIMERレジスタ構成 
	sys_envtimer_sig(31 downto 16) <= (others=>'0');
	sys_envtimer_sig(15) <= envtimerena_reg;
	sys_envtimer_sig(14 downto 12) <= (others=>'0');
	sys_envtimer_sig(11 downto 0) <= envtimer_reg;

	end generate;
ENG_ENVOFF : if (USE_ENVELOPE /= "ON") generate

	env_renew <= '0';
	sys_envtimer_sig <= (others=>'X');

	end generate;


--==== 割り込み処理ブロック ==========================================

GEN_IRQON : if (USE_SLOTIRQ = "ON") generate

	-- 割り込みリクエスト 
	reg_irq_sig <= irqslot and irqena_reg;

	-- スロット番号ラッチ 
	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			irqslotnum_reg <= (others=>'0');

		elsif(clk'event and clk=CLOCK_EDGE) then
			if (irqena_reg='1') then
				irqslotnum_reg <= irqslot_num;
			end if;

		end if;
	end process;

	end generate;
GEN_IRQOFF : if (USE_SLOTIRQ /= "ON") generate

	reg_irq_sig    <= '0';
	irqslotnum_reg <= (others=>'X');

	end generate;


--==== レジスタ入出力 ================================================

	-- システムレジスタ出力 
	mute_out    <= mute_reg;
	sys_sync    <= syssync_reg;
	sys_slotnum <= slotnum_reg;
	sys_extwait <= extwait_reg;
	sys_romwait <= waitcount_reg;

	-- デコードテーブルへ書き戻し 
	dectable_wrdata <= reg_wrdata_sig;
	dectable_write  <= reg_wrena_sig when reg_addr_sig(11 downto 2)="0000000101" else
						'0';

	-- AC-LINKレジスタへ書き戻し 
	aclink_wrdata   <= reg_wrdata_sig;
	aclink_write    <= reg_wrena_sig when reg_addr_sig(11 downto 2)="0000000110" else
						'0';

	-- スロットレジスタへ書き戻し 
	ext_address     <= reg_addr_sig;
	ext_writedata   <= reg_wrdata_sig;
	ext_writeenable <= reg_wrena_sig;


	-- システムレジスタ書き込み 
	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			drive_reg      <= '0';
			syssync_reg    <= '0';
			mute_reg       <= '1';
			overload_reg   <= '0';
			irqena_reg     <= '0';
			slotnum_reg    <= (others=>'0');
			extfsedge_reg  <= FORCE_EXTFSEDGE;
			extwait_reg    <= FORCE_EXTWAIT;
			waitcount_reg  <= (others=>'0');
			envtimerena_reg<= '0';
			envtimer_reg   <= (others=>'0');

		elsif(clk'event and clk=CLOCK_EDGE) then
			if (sync_fs_reg='1') then
				drive_reg    <= sys_drive;
				syssync_reg  <= '0';
				overload_reg <= overload_reg or sys_overload;

			else
				if (reg_wrena_sig='1' and reg_addr_sig(11 downto 5)=0) then
					case reg_addr_sig(4 downto 2) is
					when "000" =>
						mute_reg      <= reg_wrdata_sig(12);
						overload_reg  <= reg_wrdata_sig(11);
						irqena_reg    <= reg_wrdata_sig(9);

					when "001" =>
						extwait_reg   <= reg_wrdata_sig(15) or FORCE_EXTWAIT;
						waitcount_reg <= reg_wrdata_sig(14 downto 8) and(not WAITCOUNT_MASK);
						extfsedge_reg <= reg_wrdata_sig(7) or FORCE_EXTFSEDGE;
						slotnum_reg   <= reg_wrdata_sig(6 downto 0) and SLOTNUM_MASK;

					when "010" =>
						syssync_reg   <= '1';

					when "011" =>
						envtimerena_reg<= reg_wrdata_sig(15);
						envtimer_reg  <= reg_wrdata_sig(11 downto 0);

					when others =>
					end case;

				end if;
			end if;

		end if;
	end process;


	-- SYSTEM-STATUSレジスタ構成 
	sys_status_sig(31 downto 16) <= (others=>'0');
	sys_status_sig(15) <= drive_reg;
	sys_status_sig(14) <= '0';
	sys_status_sig(13) <= '0';
	sys_status_sig(12) <= mute_reg;
	sys_status_sig(11) <= overload_reg;
	sys_status_sig(10) <= irqslot;
	sys_status_sig(9)  <= irqena_reg;
	sys_status_sig(7)  <= '0';
	sys_status_sig(8)  <= '0';
	sys_status_sig(6 downto 0) <= irqslotnum_reg;

	-- SYSTEM-SETUPレジスタ構成 
	sys_setup_sig(31 downto 16) <= (others=>'0');
	sys_setup_sig(15) <= extwait_reg;
	sys_setup_sig(14 downto 8) <= waitcount_reg;
	sys_setup_sig(7)  <= extfsedge_reg;
	sys_setup_sig(6 downto 0)  <= slotnum_reg;

	-- SYSTEM-SYNCレジスタ構成 
	sys_keysync_sig(31 downto 1) <= (others=>'0');
	sys_keysync_sig(0) <= syssync_reg;

	-- SYSTEM-IDレジスタ構成 
	systemid_sig <= CONV_std_logic_vector(SYSTEM_ID,32);

	-- DEC-TABLEレジスタ構成 
	dectabledata_sig <= dectable_rddata;

	-- AC-LINKレジスタ構成 
	aclinkdata_sig <= aclink_rddata;


--==== AvalonBUS 入出力 ==============================================

	-- システムレジスタ読み出し選択 
	with reg_addr_sig(4 downto 2) select sys_rddata_sig <=
		sys_status_sig		when "000",
		sys_setup_sig		when "001",
		sys_keysync_sig		when "010",
		sys_envtimer_sig	when "011",
		systemid_sig		when "100",
		dectabledata_sig	when "101",
		aclinkdata_sig		when "110",
		(others=>'X')		when others;

	-- システム／スロットレジスタ入力選択 
	reg_rddata_sig <= sys_rddata_sig when reg_addr_sig(11 downto 5)=0 else
						ext_readdata;
	reg_lock_sig   <= sync_fs_reg when reg_addr_sig(11 downto 5)=0 else
						ext_lock;

	-- リードモディファイライト処理ブロックのインスタンス 
	U_bus : loreley_businterface_rmw
	generic map(
		CLOCK_EDGE		=> CLOCK_EDGE,
		RESET_LEVEL		=> RESET_LEVEL
	)
	port map (
		clk				=> clk,
		reset			=> reset,

		address			=> address,
		chipselect		=> chipselect,
		read			=> read,
		write			=> write,
		byteenable		=> byteenable,
		readdata		=> readdata,
		writedata		=> writedata,
		waitrequest		=> waitrequest,
		irq				=> irq,

		reg_address		=> reg_addr_sig,
		reg_lock		=> reg_lock_sig,
		reg_readdata	=> reg_rddata_sig,
		reg_writedata	=> reg_wrdata_sig,
		reg_writeenable	=> reg_wrena_sig,
		reg_irq			=> reg_irq_sig
	);


end RTL;



----------------------------------------------------------------------
-- Read modified Write control
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity loreley_businterface_rmw is
	generic(
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock
		RESET_LEVEL		: std_logic := '1'	-- Positive logic reset
	);
	port(
		clk				: in  std_logic;	-- system clock
		reset			: in  std_logic;	-- async reset

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

	--==== RegisterBUS I/F signal ====================================

		reg_address		: out std_logic_vector(11 downto 2);
		reg_lock		: in  std_logic;

		reg_readdata	: in  std_logic_vector(31 downto 0);
		reg_writedata	: out std_logic_vector(31 downto 0);
		reg_writeenable	: out std_logic;

		reg_irq			: in  std_logic
	);
end loreley_businterface_rmw;

architecture RTL of loreley_businterface_rmw is
	type BUS_STATE is (IDLE, START,REGREAD,REGRMD,REGWRITE,DONE, RETRY);
	signal state : BUS_STATE;

	signal addr_reg			: std_logic_vector(11 downto 2);
	signal data_reg			: std_logic_vector(31 downto 0);
	signal wnr_reg			: std_logic;
	signal wrena_reg		: std_logic_vector(3 downto 0);
	signal rmdwork_reg		: std_logic_vector(31 downto 0);
	signal regwrite_reg		: std_logic;
	signal waitreq_sig		: std_logic;

begin

	readdata    <= rmdwork_reg;
	irq         <= reg_irq;
	waitrequest <= waitreq_sig and chipselect;
	waitreq_sig <= '0' when state=DONE else '1';

	reg_address    <= addr_reg;
	reg_writedata  <= rmdwork_reg;
	reg_writeenable<= regwrite_reg when reg_lock='0' else '0';

	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			state <= IDLE;
			regwrite_reg <= '0';

		elsif(clk'event and clk=CLOCK_EDGE) then

			case state is
			when IDLE =>
				if (chipselect='1') then
					state <= START;
					addr_reg    <= address;
					data_reg    <= writedata;
					wnr_reg     <= write;
					wrena_reg   <= byteenable;
				end if;


			when START =>					-- レジスタリード待ち 
				if (reg_lock='1') then
					state <= RETRY;
				else
					state <= REGREAD;
				end if;

			when REGREAD =>
				if (reg_lock='1') then
					state <= RETRY;
				else
					if (wnr_reg='1') then
						state <= REGRMD;
					else
						state <= DONE;
					end if;
				end if;

				rmdwork_reg <= reg_readdata;


			when REGRMD =>					-- レジスタのリードモディファイライト 
				if (reg_lock='1') then
					state <= RETRY;
				else
					state <= REGWRITE;
				end if;

				case addr_reg(4 downto 2) is
				when "000" =>				-- +00h : STATUSレジスタのビット操作(bit31～15は書き込み禁止) 
					regwrite_reg <= '1';
					if (wrena_reg(1)='1') then
						rmdwork_reg(14) <= rmdwork_reg(14) or data_reg(14);
						rmdwork_reg(13) <= rmdwork_reg(13) or data_reg(13);
						rmdwork_reg(12) <= data_reg(12);
						rmdwork_reg(11) <= rmdwork_reg(11) and data_reg(11);
						rmdwork_reg(10) <= rmdwork_reg(10) and data_reg(10);
						rmdwork_reg(9)  <= data_reg(9);
						rmdwork_reg(8)  <= data_reg(8);
					end if;
					if (wrena_reg(0)='1') then
						rmdwork_reg(7 downto 0) <= data_reg(7 downto 0);
					end if;

				when "100" =>				-- +10h : 書き込み禁止(SYSTEM_ID,PLAY_ADDRESS)
					regwrite_reg <= '0';

				when others =>				-- それ以外はバスデータで上書き 
					regwrite_reg <= '1';
					if (wrena_reg(3)='1') then
						rmdwork_reg(31 downto 24) <= data_reg(31 downto 24);
					end if;
					if (wrena_reg(2)='1') then
						rmdwork_reg(23 downto 16) <= data_reg(23 downto 16);
					end if;
					if (wrena_reg(1)='1') then
						rmdwork_reg(15 downto 8)  <= data_reg(15 downto 8);
					end if;
					if (wrena_reg(0)='1') then
						rmdwork_reg(7 downto 0)   <= data_reg(7 downto 0);
					end if;

				end case;


			when REGWRITE =>				-- レジスタへ書き戻し 
				if (reg_lock='1') then
					state <= RETRY;
				else
					state <= DONE;
				end if;

				regwrite_reg <= '0';


			when DONE =>
				state <= IDLE;

			when RETRY =>
				if (reg_lock='0') then
					state <= START;
				else
					state <= RETRY;
				end if;


			when others=>
				state <= IDLE;
			end case;

		end if;
	end process;


end RTL;



----------------------------------------------------------------------
--   (C)2005,2006 Copyright J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------

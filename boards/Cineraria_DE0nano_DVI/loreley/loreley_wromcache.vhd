----------------------------------------------------------------------
-- TITLE : Loreley WaveROM cache (8byte Line / 16bit BUS)
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2006/10/13 -> 2006/10/15 (HERSTELLUNG)
--               : 2006/10/15 (FESTSTELLUNG)
--
--               : 2006/11/28 ハーフラインキャッシュ対応
--               : 2006/12/04 外部バッファバイパスを追加
--               : 2007/02/21 メモリをMegaFunctionに変更
--               : 2010/12/29 リードをAvalonMMマスタに変更 (NEUBEARBEITUNG)
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity loreley_wromcache is
	generic(
		RESET_LEVEL		: std_logic := '1';	-- Positive logic reset
		CLOCK_EDGE		: std_logic := '1';	-- Rise edge drive clock

		SLOTNUM_WIDTH	: integer := 6			-- 63slot
	);
	port(
		reset			: in  std_logic;
		clk				: in  std_logic;		-- Lorely drive clock
		rom_extselect	: in  std_logic;
		rom_slotnum		: in  std_logic_vector(SLOTNUM_WIDTH-1 downto 0);
		rom_fillreq		: in  std_logic;
		rom_address		: in  std_logic_vector(24 downto 1);	-- 32Mbyte area
		rom_read_n		: in  std_logic;
		rom_readdata	: out std_logic_vector(15 downto 0);
		rom_waitrequest	: out std_logic;

		ext_address		: out std_logic_vector(24 downto 1);
		ext_read_n		: out std_logic;
		ext_readdata	: in  std_logic_vector(15 downto 0);

		M_reset			: in  std_logic;
		M_clk			: in  std_logic;		-- AvalonMM Master drive clock;
		M_address		: out std_logic_vector(24 downto 0);	-- only 8byte alignment
		M_readreq		: out std_logic;
		M_readdata		: in  std_logic_vector(15 downto 0);
		M_datavalid		: in  std_logic;
		M_burstcount	: out std_logic_vector(2 downto 0);		-- 4 burst fixed
		M_waitrequest	: in  std_logic
	);
end loreley_wromcache;

architecture RTL of loreley_wromcache is
	type PCMBUS_STATE is (IDLE,READWAIT,BURSTREAD,DONE);
	signal readstate : PCMBUS_STATE;
	signal romread_n_0		: std_logic;
	signal romread_n_reg	: std_logic;
	signal fillreq_0		: std_logic;
	signal fillreq_reg		: std_logic;
	signal pcmaddr_reg		: std_logic_vector(24 downto 3);
	signal pcmreq_reg		: std_logic;
	signal cacheaddr_reg	: std_logic_vector((SLOTNUM_WIDTH-1)+3 downto 2);
	signal burstaddr_reg	: std_logic_vector(1 downto 0);
	signal statebusy_reg	: std_logic;

	type WROMBUS_STATE is (IDLE,HOLD,DONE);
	signal wromstate : WROMBUS_STATE;
	signal waitreq_reg_0	: std_logic;
	signal waitreq_reg		: std_logic;
	signal waithold_reg		: std_logic;


	component loreley_cacheram
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdaddress	: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		wraddress	: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		wrclock		: IN STD_LOGIC ;
		wren		: IN STD_LOGIC  := '1';
		q			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
	end component;
	signal rdaddr_sig	: std_logic_vector(8 downto 0);
	signal wraddr_sig	: std_logic_vector(8 downto 0);
	signal rddata_sig	: std_logic_vector(15 downto 0);


begin

	-- Loreleyインターフェース(WaveROMリード)

	rom_readdata    <= rddata_sig when rom_extselect='0' else ext_readdata;
	rom_waitrequest <= waitreq_reg or waithold_reg;

	ext_read_n  <= rom_read_n when rom_extselect='1' else '1';
	ext_address <= rom_address;

	process (clk,reset) begin
		if (reset=RESET_LEVEL) then
			wromstate <= IDLE;
			waitreq_reg_0 <= '0';
			waitreq_reg   <= '0';
			waithold_reg  <= '1';

		elsif (clk'event and clk=CLOCK_EDGE) then
			waitreq_reg_0 <= statebusy_reg;
			waitreq_reg   <= waitreq_reg_0;

			case wromstate is
			when IDLE =>
				if (rom_read_n = '0') then
					if (rom_extselect = '0' and rom_fillreq = '1') then
						wromstate <= HOLD;
					else
						wromstate <= DONE;
						waithold_reg <= '0';
					end if;
				end if;
			when HOLD =>
				if (waitreq_reg='1') then
					wromstate <= DONE;
					waithold_reg <= '0';
				end if;
			when DONE =>
				if (rom_read_n='1') then
					wromstate <= IDLE;
					waithold_reg <= '1';
				end if;
			end case;

		end if;
	end process;


	-- AvalonMMマスタインターフェース(バーストリード要求)

	M_address    <= pcmaddr_reg & "000";	-- 開始アドレスは8バイト境界 
	M_burstcount <= CONV_STD_LOGIC_VECTOR(4, M_burstcount'length);	-- ４サイクル固定 
	M_readreq    <= pcmreq_reg;

	process (M_clk,M_reset) begin
		if (M_reset=RESET_LEVEL) then
			readstate <= IDLE;
			romread_n_0   <= '0';
			romread_n_reg <= '0';
			fillreq_0     <= '0';
			fillreq_reg   <= '0';
			pcmreq_reg    <= '0';
			statebusy_reg <= '0';

		elsif (M_clk'event and M_clk=CLOCK_EDGE) then
			romread_n_0   <= rom_read_n;
			romread_n_reg <= romread_n_0;
			fillreq_0     <= rom_fillreq;
			fillreq_reg   <= fillreq_0;

			case readstate is
			when IDLE =>
				if (romread_n_reg='0') then
					if (fillreq_reg = '1') then
						readstate <= READWAIT;
						pcmaddr_reg   <= rom_address(24 downto 3);
						pcmreq_reg    <= '1';
						cacheaddr_reg <= rom_slotnum & rom_address(3);
						statebusy_reg <= '1';
					else
						readstate <= DONE;
					end if;
				end if;

			when READWAIT =>					-- バーストリードトランザクション発行 
				if (M_waitrequest = '0') then
					readstate <= BURSTREAD;
					pcmreq_reg <= '0';
					burstaddr_reg <= "00";
				end if;

			when BURSTREAD =>					-- バーストデータ到着待ち 
				if (M_datavalid = '1') then
					if (burstaddr_reg = "11") then
						readstate <= DONE;
						statebusy_reg <= '0';
					else
						burstaddr_reg <= burstaddr_reg + '1';
					end if;
				end if;

			when DONE =>
				if (romread_n_reg = '1') then
					readstate <= IDLE;
				end if;

			end case;

		end if;
	end process;


	-- キャッシュRAM (Simple Dualport RAM)

	rdaddr_sig <= rom_slotnum & rom_address(3 downto 1);
	wraddr_sig <= cacheaddr_reg & burstaddr_reg;

	U_mem : loreley_cacheram
	port map (
		rdclock		=> clk,
		rdaddress	=> rdaddr_sig,
		q			=> rddata_sig,

		wrclock		=> M_clk,
		wraddress	=> wraddr_sig,
		data		=> M_readdata,
		wren		=> M_datavalid
	);


end RTL;



----------------------------------------------------------------------
--   (C)2005-2008 Copyright J-7SYSTEM Works.  All rights Reserved.  --
----------------------------------------------------------------------

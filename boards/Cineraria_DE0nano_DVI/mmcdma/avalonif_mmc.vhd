----------------------------------------------------------------------
-- TITLE : MMC/SD SPI I/F for Avalon Slave
--
--     VERFASSER : S.OSAFUNE (J-7SYSTEM Works)
--     DATUM     : 2007/01/19 -> 2007/01/31 (HERSTELLUNG)
--               : 2007/01/31 (FESTSTELLUNG)
--
--               : 2008/07/17 FRCゼロフラグを追加 (NEUBEARBEITUNG)
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity avalonif_mmc is
	port(
		----- Avalonバス信号 -----------
		clk			: in  std_logic;
		reset		: in  std_logic;
		chipselect	: in  std_logic;
		address		: in  std_logic_vector(3 downto 2);
		read		: in  std_logic;
		readdata	: out std_logic_vector(31 downto 0);
		write		: in  std_logic;
		writedata	: in  std_logic_vector(31 downto 0);
		irq			: out std_logic;

		----- MMC SPI信号 -----------
			-- 各ピンの信号レベルはLVCMOSに設定すること
		MMC_nCS		: out std_logic;
		MMC_SCK		: out std_logic;
		MMC_SDO		: out std_logic;
		MMC_SDI		: in  std_logic := '1';
		MMC_CD		: in  std_logic := '1';	-- カード挿入検出 
		MMC_WP		: in  std_logic := '1'	-- ライトプロテクト検出 
	);
end avalonif_mmc;

architecture RTL of avalonif_mmc is
	type SPI_STATE is (IDLE,SDO,SDI,DONE);
	signal state : SPI_STATE;
	signal bitcount		: integer range 0 to 7;

	signal read_0_sig	: std_logic_vector(31 downto 0);
	signal read_1_sig	: std_logic_vector(31 downto 0);
	signal read_2_sig	: std_logic_vector(31 downto 0);

	signal divref_reg	: std_logic_vector(7 downto 0);
	signal divcount		: std_logic_vector(7 downto 0);
	signal rxddata		: std_logic_vector(7 downto 0);
	signal txddata		: std_logic_vector(7 downto 0);
	signal irqena_reg	: std_logic;
	signal exit_reg		: std_logic;
	signal mmc_wp_reg	: std_logic;
	signal mmc_cd_reg	: std_logic;
	signal ncs_reg		: std_logic;
	signal sck_reg		: std_logic;
	signal sdo_reg		: std_logic;
	signal frc_reg		: std_logic_vector(31 downto 0);
	signal frczero_reg	: std_logic;

begin

	irq <= exit_reg when irqena_reg='1' else '0';

	readdata <= read_2_sig when address="10" else
				read_1_sig when address="01" else
				read_0_sig;

	read_0_sig(31 downto 16) <= (others=>'0');
	read_0_sig(15) <= irqena_reg;
	read_0_sig(14) <= '0';
	read_0_sig(13) <= '0';
	read_0_sig(12) <= frczero_reg;
	read_0_sig(11) <= mmc_wp_reg;
	read_0_sig(10) <= mmc_cd_reg;
	read_0_sig(9)  <= exit_reg;
	read_0_sig(8)  <= ncs_reg;
	read_0_sig(7 downto 0) <= rxddata;

	read_1_sig(31 downto 8) <= (others=>'0');
	read_1_sig(7 downto 0) <= divref_reg;

	read_2_sig <= frc_reg;

	MMC_nCS <= ncs_reg;
	MMC_SCK <= sck_reg;
	MMC_SDO <= sdo_reg;

	process (clk,reset) begin
		if (reset='1') then
			state      <= IDLE;
			divref_reg <= (others=>'1');
			irqena_reg <= '0';
			ncs_reg    <= '1';
			sck_reg    <= '1';
			sdo_reg    <= '1';
			exit_reg   <= '1';
			frc_reg    <= (others=>'0');
			frczero_reg<= '1';

		elsif(clk'event and clk='1') then
			mmc_cd_reg <= MMC_CD;
			mmc_wp_reg <= MMC_WP;

			case state is
			when IDLE =>
				if (chipselect='1' and write='1' and address(3)='0') then
					case address(2) is
					when '0' =>
						if (writedata(9)='0') then
							state    <= SDO;
							bitcount <= 0;
							divcount <= divref_reg;
							exit_reg <= '0';
						end if;
						irqena_reg <= writedata(15);
						ncs_reg    <= writedata(8);
						txddata    <= writedata(7 downto 0);
					when '1' =>
						divref_reg <= writedata(7 downto 0);
					end case;
				end if;

			when SDO =>
				if (divcount=0) then
					state    <= SDI;
					divcount <= divref_reg;
					sck_reg  <= not sck_reg;
					sdo_reg  <= txddata(7);
					txddata  <= txddata(6 downto 0) & '0';
				else
					divcount <= divcount - '1';
				end if;

			when SDI =>
				if (divcount=0) then
					if (bitcount=7) then
						state <= DONE;
					else
						state <= SDO;
					end if;
					bitcount <= bitcount + 1;
					divcount <= divref_reg;
					sck_reg  <= not sck_reg;
					rxddata  <= rxddata(6 downto 0) & MMC_SDI;
				else
					divcount <= divcount - '1';
				end if;

			when DONE =>
				if (divcount=0) then
					state    <= IDLE;
					sck_reg  <= '1';
					sdo_reg  <= '1';
					exit_reg <= '1';
				else
					divcount <= divcount - '1';
				end if;

			end case;


			if (chipselect='1' and write='1' and address="10") then
				frc_reg <= writedata;
			elsif (frc_reg /= 0) then
				frc_reg <= frc_reg - '1';
			end if;

			if (frc_reg = 0) then
				frczero_reg <= '1';
			else
				frczero_reg <= '0';
			end if;

		end if;
	end process;


end RTL;



----------------------------------------------------------------------
--   (C)2003-2007 Copyright J-7SYSTEM Works. All rights Reserved.   --
----------------------------------------------------------------------
